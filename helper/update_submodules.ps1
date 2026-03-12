$ErrorActionPreference = "Stop"

$DotfilesDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Set-Location $DotfilesDir

git submodule update --remote

$ChangedModules = git diff --name-only
if (-not $ChangedModules) {
    Write-Host "All submodules are already up to date."
    exit 0
}

Write-Host "Updated submodules:"
Write-Host $ChangedModules

git add -A
git commit -m "chore: update submodules"
