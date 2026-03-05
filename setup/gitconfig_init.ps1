Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info  { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Green }
function Write-Warn  { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git is not installed. Please install Git to proceed."
    exit 1
}

$gitconfig = Join-Path $HOME ".gitconfig"
$gitconfigLocal = Join-Path $HOME ".gitconfig.local"

if (-not (Test-Path $gitconfig)) {
    Write-Error ".gitconfig file not found in home directory. Exiting."
    exit 1
}

if (-not (Select-String -Path $gitconfig -Pattern "~/.gitconfig.local" -Quiet)) {
    Write-Warn 'Appropriate include line not found in .gitconfig. ".gitconfig.local" will not be included.'
}

if (Test-Path $gitconfigLocal) {
    Write-Warn ".gitconfig.local already exists in home directory."
} else {
    @"
[credential "https://github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential
[credential "https://gist.github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential
[user]
    name = <YOUR_NAME>
    email = <YOUR_EMAIL>
    signingKey = <YOUR_PATH_TO_GPG_KEY>
"@ | Set-Content -Path $gitconfigLocal -Encoding UTF8

    Write-Info ".gitconfig.local has been created in your home directory."
}
