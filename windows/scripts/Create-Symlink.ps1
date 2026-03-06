param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Target,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Symlink
)

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {
    Write-Error "This script requires administrator privileges. Run as admin and try again."
    exit 1
}

$Target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Target)
$Symlink = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Symlink)

if (-not (Test-Path $Target)) {
    Write-Error "Target does not exist: $Target"
    exit 1
}

if ((Test-Path $Symlink) -and (Get-Item $Symlink -Force).PSIsContainer) {
    $Symlink = Join-Path $Symlink (Split-Path $Target -Leaf)
}

if (Test-Path $Symlink) {
    $existing = Get-Item $Symlink -Force
    if ($existing.LinkType -eq "SymbolicLink" -and $existing.Target -eq $Target) {
        Write-Host "Symlink already exists: $Symlink -> $Target"
        exit 0
    } elseif ($existing.LinkType -eq "SymbolicLink") {
        $response = Read-Host "Symlink already exists: $Symlink -> $($existing.Target). Replace? [Y/n]"
        if ($response -and $response -notin @('y', 'Y')) {
            Write-Host "Skipped."
            exit 0
        }
        Remove-Item $Symlink -Force
    } else {
        Write-Error "Path already exists and is not a symlink: $Symlink"
        exit 1
    }
}

$parentDir = Split-Path $Symlink -Parent
if (-not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}

$isDirectory = (Get-Item $Target).PSIsContainer
New-Item -ItemType SymbolicLink -Path $Symlink -Target $Target | Out-Null

$linkType = if ($isDirectory) { "directory" } else { "file" }
Write-Host "Created $linkType symlink: $Symlink -> $Target"
