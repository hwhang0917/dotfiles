# Set-Routes.ps1 - Dual WiFi routing setup (internal + public)
#
# Connects two WiFi adapters to separate networks and configures
# routing so internal subnets go through the internal gateway
# while everything else routes through the public gateway.
#
# Config: Copy Set-Routes.config.example.json to Set-Routes.config.json
#         in the same directory as this script and edit the values:
#
#   InternalAdapter / PublicAdapter  - adapter description patterns (Get-NetAdapter)
#   InternalInterface / PublicInterface - adapter names (Get-NetAdapter "Name" column)
#   InternalSSID / PublicSSID        - WiFi network names to connect to
#   InternalGateway / PublicGateway  - gateway IPs for each network
#   InternalSubnets                  - array of {"Prefix": "x.x.x.x/x"} routed internally
#   PublicMetric / InternalMetric    - interface metrics (lower = preferred default route)
#   SubnetRouteMetric                - route metric for internal subnet entries
#   DisconnectWait / ConnectWait     - seconds to wait during WiFi reconnection
#
# ============================================================
# Check for admin privileges
# ============================================================
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator." -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then try again."
    exit 1
}

# ============================================================
# Load config from external JSON file
# ============================================================
$configPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "Set-Routes.config.json"
if (-not (Test-Path $configPath)) {
    Write-Host "ERROR: Config file not found at: $configPath" -ForegroundColor Red
    Write-Host "Copy Set-Routes.config.example.json to Set-Routes.config.json and edit it for your environment."
    exit 1
}
$config = Get-Content -Raw $configPath | ConvertFrom-Json
# ============================================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFile = Join-Path $scriptDir "set-route.log"

function Log {
    param([string]$msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $msg"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

Log "========== Starting route setup =========="

# Force WiFi associations
Log "Disconnecting all WiFi interfaces..."
netsh wlan disconnect interface="$($config.InternalInterface)" | Out-Null
netsh wlan disconnect interface="$($config.PublicInterface)" | Out-Null
Start-Sleep -Seconds $config.DisconnectWait

Log "Connecting $($config.InternalInterface) -> $($config.InternalSSID)"
netsh wlan connect name="$($config.InternalSSID)" interface="$($config.InternalInterface)"
Log "Connecting $($config.PublicInterface) -> $($config.PublicSSID)"
netsh wlan connect name="$($config.PublicSSID)" interface="$($config.PublicInterface)"

Log "Waiting for connections to establish..."
Start-Sleep -Seconds $config.ConnectWait

# Look up current interface indexes
$intel = (Get-NetAdapter | Where-Object InterfaceDescription -like $config.InternalAdapter).ifIndex
$realtek = (Get-NetAdapter | Where-Object InterfaceDescription -like $config.PublicAdapter).ifIndex

if (-not $intel) { Log "ERROR: Internal adapter ($($config.InternalAdapter)) not found"; exit 1 }
if (-not $realtek) { Log "ERROR: Public adapter ($($config.PublicAdapter)) not found"; exit 1 }

Log "Detected Internal (IF $intel), Public (IF $realtek)"

# Remove DHCP-assigned default route on internal adapter
Remove-NetRoute -InterfaceIndex $intel -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
Log "Removed default route from internal adapter"

# Set interface metrics
Set-NetIPInterface -InterfaceIndex $realtek -InterfaceMetric $config.PublicMetric
Set-NetIPInterface -InterfaceIndex $intel -InterfaceMetric $config.InternalMetric
Log "Set metrics: Public=$($config.PublicMetric), Internal=$($config.InternalMetric)"

# Default route through public adapter
New-NetRoute -DestinationPrefix "0.0.0.0/0" -NextHop $config.PublicGateway -InterfaceIndex $realtek -RouteMetric 1 -ErrorAction SilentlyContinue
Log "Added default route -> $($config.PublicGateway) via Public (IF $realtek)"

# Internal subnets
foreach ($subnet in $config.InternalSubnets) {
    New-NetRoute -DestinationPrefix $subnet.Prefix -NextHop $config.InternalGateway -InterfaceIndex $intel -RouteMetric $config.SubnetRouteMetric -ErrorAction SilentlyContinue
    Log "Added $($subnet.Prefix) -> $($config.InternalGateway) via Internal (IF $intel)"
}

Log "========== Route setup complete =========="

