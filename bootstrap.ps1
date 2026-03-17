Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] This script must be run as Administrator (required for symlink creation)." -ForegroundColor Red
    exit 1
}

$DotfilesDir = $PSScriptRoot
$CreateSymlink = Join-Path $DotfilesDir "windows\scripts\Create-Symlink.ps1"

function Write-Info  { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Green }
function Write-Warn  { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Step  { param([string]$Message) Write-Host "[STEP] $Message" -ForegroundColor Blue }

$script:HasGum = $false

# ── Prompts (gum with Read-Host fallback) ─────────────────────

function Invoke-Confirm {
    param([string]$Prompt)
    if ($script:HasGum) {
        gum confirm $Prompt
        return $LASTEXITCODE -eq 0
    } else {
        $choice = Read-Host "$Prompt [Y/n]"
        return (-not $choice -or $choice -match '^[Yy]')
    }
}

function Invoke-ChooseMany {
    param(
        [string]$Header,
        [string[]]$Items,
        [string[]]$Selected = @()
    )

    if ($script:HasGum) {
        $args_ = @("--no-limit", "--header", $Header)
        if ($Selected.Count -gt 0) {
            $args_ += @("--selected", ($Selected -join ","))
        }
        $result = $Items | gum choose @args_
        if ($LASTEXITCODE -ne 0) { return @() }
        return @($result)
    } else {
        Write-Host $Header
        Write-Host "(space-separated, or 'all' for everything)"
        foreach ($item in $Items) {
            $marker = if ($Selected -contains $item) { "*" } else { " " }
            Write-Host "  [$marker] $item"
        }
        $input = Read-Host ">"
        if ($input -eq "all") { return $Items }
        if (-not $input) { return @() }
        return @($input -split '\s+')
    }
}

# ── Gum bootstrap ────────────────────────────────────────────

function Install-Gum {
    if (Get-Command gum -ErrorAction SilentlyContinue) {
        $script:HasGum = $true
        return
    }

    Write-Step "gum not found - installing for interactive prompts..."

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id charmbracelet.gum --accept-source-agreements --accept-package-agreements 2>$null
        # Refresh PATH
        $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
    }

    if (Get-Command gum -ErrorAction SilentlyContinue) {
        $script:HasGum = $true
        Write-Info "gum installed"
    } else {
        Write-Warn "Could not install gum, falling back to basic prompts"
    }
}

# ── Tool installation ─────────────────────────────────────────

function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$Name
    )

    $installed = winget list --id $PackageId 2>$null | Select-String $PackageId
    if ($installed) {
        Write-Info "$Name is already installed"
        return
    }

    Write-Info "Installing $Name..."
    winget install --id $PackageId --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Failed to install $Name, skipping"
    }
}

function Install-Tools {
    Write-Step "Checking tools..."

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warn "winget not found. Install 'App Installer' from the Microsoft Store and re-run this script."
        Write-Warn "https://aka.ms/getwinget"
        return
    }

    $packages = @(
        @{ Id = "Git.Git";              Name = "Git" },
        @{ Id = "Neovim.Neovim";        Name = "Neovim" },
        @{ Id = "AutoHotkey.AutoHotkey"; Name = "AutoHotkey" },
        @{ Id = "glzr-io.glazewm";      Name = "GlazeWM" },
        @{ Id = "glzr-io.zebar";        Name = "Zebar" },
        @{ Id = "Schniz.fnm";           Name = "fnm" },
        @{ Id = "junegunn.fzf";         Name = "fzf" },
        @{ Id = "Starship.Starship";    Name = "Starship" },
        @{ Id = "eza-community.eza";    Name = "eza" },
        @{ Id = "ajeetdsouza.zoxide";   Name = "zoxide" }
    )

    # Find missing tools
    $missing = @()
    foreach ($pkg in $packages) {
        $installed = winget list --id $pkg.Id 2>$null | Select-String $pkg.Id
        if (-not $installed) {
            $missing += $pkg
        }
    }

    if ($missing.Count -eq 0) {
        Write-Info "All tools already installed"
        return
    }

    $missingNames = $missing | ForEach-Object { $_.Name }
    $selected = Invoke-ChooseMany -Header "Select tools to install:" -Items $missingNames -Selected $missingNames

    foreach ($name in $selected) {
        $pkg = $missing | Where-Object { $_.Name -eq $name }
        if ($pkg) {
            Install-WingetPackage -PackageId $pkg.Id -Name $pkg.Name
        }
    }

    # Refresh PATH so newly installed tools are available in this session
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
    Write-Info "Refreshed PATH"
}

# ── Submodules ────────────────────────────────────────────────

function Initialize-Submodules {
    Write-Step "Initializing git submodules..."
    Push-Location $DotfilesDir
    git submodule update --init --recursive
    Pop-Location
    Write-Info "Submodules initialized"
}

# ── Node.js ───────────────────────────────────────────────────

function Install-NodeLTS {
    if (-not (Get-Command fnm -ErrorAction SilentlyContinue)) {
        Write-Warn "fnm not found, skipping Node.js install"
        return
    }

    Write-Step "Installing Node.js LTS via fnm..."
    try {
        fnm install --lts
        fnm use lts-latest
        fnm env --use-on-cd | Out-String | Invoke-Expression
        Write-Info "Node.js LTS installed via fnm"
    } catch {
        Write-Warn "Failed to install Node.js via fnm: $_"
    }
}

# ── Zebar ─────────────────────────────────────────────────────

function Build-ZebarWidget {
    $zebarDir = Join-Path $DotfilesDir "glzr\.glzr\zebar\starter"

    if (-not (Test-Path $zebarDir)) {
        Write-Warn "Zebar starter directory not found at $zebarDir, skipping build"
        return
    }

    Write-Step "Building Zebar widget..."
    Push-Location $zebarDir
    try {
        npm install
        npm run build
        Write-Info "Zebar widget built"
    } catch {
        Write-Warn "Failed to build Zebar widget: $_"
    } finally {
        Pop-Location
    }
}

# ── Symlinks ──────────────────────────────────────────────────

function New-Symlinks {
    Write-Step "Creating symlinks..."

    $symlinks = @(
        @{ Name = "GlazeWM + Zebar"; Target = "glzr\.glzr";                                              Path = (Join-Path $HOME ".glzr") },
        @{ Name = "AutoHotkey";      Target = "autohotkey\hotkey.ahk";                                    Path = (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup\hotkey.ahk") },
        @{ Name = "Neovim";          Target = "nvim\.config\nvim";                                        Path = (Join-Path $env:LOCALAPPDATA "nvim") },
        @{ Name = "Git config";      Target = "git\.gitconfig";                                           Path = (Join-Path $HOME ".gitconfig") },
        @{ Name = "Git ignore";      Target = "git\.gitignore";                                           Path = (Join-Path $HOME ".gitignore") },
        @{ Name = "Windows Terminal"; Target = "wt\settings.json";                                        Path = (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json") },
        @{ Name = "Scripts";         Target = "windows\scripts";                                          Path = (Join-Path $HOME "Documents\scripts") },
        @{ Name = "PowerShell";      Target = "windows\profile\Microsoft.PowerShell_profile.ps1";         Path = (Join-Path $HOME "Documents\PowerShell\Microsoft.PowerShell_profile.ps1") }
    )

    $names = $symlinks | ForEach-Object { $_.Name }
    $selected = Invoke-ChooseMany -Header "Select symlinks to create:" -Items $names -Selected $names

    foreach ($name in $selected) {
        $link = $symlinks | Where-Object { $_.Name -eq $name }
        if ($link) {
            $target = Join-Path $DotfilesDir $link.Target
            & $CreateSymlink $target $link.Path
        }
    }
}

# ── Git config ────────────────────────────────────────────────

function Set-GitLocalConfig {
    $gitconfigLocal = Join-Path $HOME ".gitconfig.local"
    if ((Test-Path (Join-Path $HOME ".gitconfig")) -and (-not (Test-Path $gitconfigLocal))) {
        Write-Warn "~/.gitconfig.local not found"
        Write-Info "Copy the example and fill in your details:"
        Write-Info "  cp $DotfilesDir\git\.gitconfig.local.example ~\.gitconfig.local"
    }
}

# ── Main ──────────────────────────────────────────────────────

function Main {
    Write-Host ""
    Write-Host ([char]0x2554 + ([string][char]0x2550) * 39 + [char]0x2557)
    Write-Host ([char]0x2551 + "     Dotfiles Bootstrap (Windows)      " + [char]0x2551)
    Write-Host ([char]0x255A + ([string][char]0x2550) * 39 + [char]0x255D)
    Write-Host ""

    Install-Gum
    Install-Tools
    Install-NodeLTS
    Initialize-Submodules
    Build-ZebarWidget
    New-Symlinks
    Set-GitLocalConfig

    Write-Host ""
    Write-Info "Bootstrap complete!"
}

Main
