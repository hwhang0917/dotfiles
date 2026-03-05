Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] This script must be run as Administrator (required for symlink creation)." -ForegroundColor Red
    exit 1
}

$DotfilesDir = $PSScriptRoot

function Write-Info  { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Green }
function Write-Warn  { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Step  { param([string]$Message) Write-Host "[STEP] $Message" -ForegroundColor Blue }

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

function New-SymlinkSafe {
    param(
        [string]$Path,
        [string]$Target,
        [switch]$Directory
    )

    if (Test-Path $Path) {
        $item = Get-Item $Path -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            $existing = $item.Target
            if ($existing -eq $Target) {
                Write-Info "Symlink already correct: $Path"
                return
            }
            Write-Warn "Symlink exists but points to '$existing', removing and re-linking: $Path"
            $item.Delete()
        } else {
            Write-Warn "Path already exists and is not a symlink, skipping: $Path"
            return
        }
    }

    $parentDir = Split-Path -Parent $Path
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    if ($Directory) {
        New-Item -ItemType SymbolicLink -Path $Path -Target $Target | Out-Null
    } else {
        New-Item -ItemType SymbolicLink -Path $Path -Target $Target | Out-Null
    }
    Write-Info "Created symlink: $Path -> $Target"
}

function Install-Tools {
    Write-Step "Installing essential tools via winget..."

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
        @{ Id = "Schniz.fnm";            Name = "fnm" },
        @{ Id = "junegunn.fzf";         Name = "fzf" },
        @{ Id = "Starship.Starship";    Name = "Starship" },
        @{ Id = "eza-community.eza";    Name = "eza" },
        @{ Id = "ajeetdsouza.zoxide";   Name = "zoxide" }
    )

    foreach ($pkg in $packages) {
        Install-WingetPackage -PackageId $pkg.Id -Name $pkg.Name
    }

    # Refresh PATH so newly installed tools are available in this session
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
    Write-Info "Refreshed PATH"
}

function Initialize-Submodules {
    Write-Step "Initializing git submodules..."
    Push-Location $DotfilesDir
    git submodule update --init --recursive
    Pop-Location
    Write-Info "Submodules initialized"
}

function Install-NodeLTS {
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

function Build-ZebarWidget {
    Write-Step "Building Zebar widget..."
    $zebarDir = Join-Path $DotfilesDir "glzr\.glzr\zebar\starter"

    if (-not (Test-Path $zebarDir)) {
        Write-Warn "Zebar starter directory not found at $zebarDir, skipping build"
        return
    }

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

function New-Symlinks {
    Write-Step "Creating symlinks..."

    # GlazeWM + Zebar
    New-SymlinkSafe `
        -Path (Join-Path $HOME ".glzr") `
        -Target (Join-Path $DotfilesDir "glzr\.glzr") `
        -Directory

    # AutoHotkey -> Startup folder
    New-SymlinkSafe `
        -Path (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup\hotkey.ahk") `
        -Target (Join-Path $DotfilesDir "autohotkey\hotkey.ahk")

    # Neovim
    New-SymlinkSafe `
        -Path (Join-Path $env:LOCALAPPDATA "nvim") `
        -Target (Join-Path $DotfilesDir "nvim\.config\nvim") `
        -Directory

    # Git
    New-SymlinkSafe `
        -Path (Join-Path $HOME ".gitconfig") `
        -Target (Join-Path $DotfilesDir "git\.gitconfig")

    New-SymlinkSafe `
        -Path (Join-Path $HOME ".gitignore") `
        -Target (Join-Path $DotfilesDir "git\.gitignore")

    # Windows Terminal
    New-SymlinkSafe `
        -Path (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json") `
        -Target (Join-Path $DotfilesDir "wt\settings.json")

    # Scripts
    New-SymlinkSafe `
        -Path (Join-Path $HOME "Documents\scripts") `
        -Target (Join-Path $DotfilesDir "windows\scripts") `
        -Directory

    # PowerShell profile
    New-SymlinkSafe `
        -Path (Join-Path $HOME "Documents\PowerShell\Microsoft.PowerShell_profile.ps1") `
        -Target (Join-Path $DotfilesDir "windows\profile\Microsoft.PowerShell_profile.ps1")
}

function Set-GitLocalConfig {
    $gitconfigLocal = Join-Path $HOME ".gitconfig.local"
    if (Test-Path (Join-Path $HOME ".gitconfig")) {
        if (-not (Test-Path $gitconfigLocal)) {
            Write-Step "Setting up git local config..."
            $initScript = Join-Path $DotfilesDir "setup\gitconfig_init.ps1"
            & $initScript
        }
    }
}

function Main {
    Write-Host ""
    Write-Host ([char]0x2554 + ([string][char]0x2550) * 39 + [char]0x2557)
    Write-Host ([char]0x2551 + "     Dotfiles Bootstrap (Windows)      " + [char]0x2551)
    Write-Host ([char]0x255A + ([string][char]0x2550) * 39 + [char]0x255D)
    Write-Host ""

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
