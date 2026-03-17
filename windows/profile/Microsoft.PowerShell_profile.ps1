# Optimized PowerShell Profile

# Fast module loading with lazy initialization
if (-not $Global:PSReadLineLoaded) {
    Import-Module PSReadLine -Force:$false
    Set-PSReadLineOption -EditMode Emacs
    $Global:PSReadLineLoaded = $true
}

# Cache external tool initializations
if (-not $Global:ExternalToolsInitialized) {
    # Fnm - Only if fnm is available
    if (Get-Command fnm -ErrorAction SilentlyContinue) {
        fnm env --use-on-cd | Out-String | Invoke-Expression
    }

    # Zoxide - Only if zoxide is available
    if (Get-Command zoxide -ErrorAction SilentlyContinue) {
        Invoke-Expression (& { (zoxide init powershell | Out-String) })
    }

    # Starship - Only if starship is available
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        Invoke-Expression (&starship init powershell)
    }

    $Global:ExternalToolsInitialized = $true
}

# Fast alias setup
if (-not $Global:AliasesSet) {
    # Remove existing ls alias if it exists
    if (Get-Alias ls -ErrorAction SilentlyContinue) {
        Remove-Item alias:ls -Force
    }

    # Only create eza functions if eza is available
    if (Get-Command eza -ErrorAction SilentlyContinue) {
        function global:ls { eza --icons --git @args }
        function global:l { eza --icons --git -lah @args }
        function global:ll { eza --icons --git -lh @args }
    } else {
        # Fallback to regular ls with some formatting
        function global:ls { Get-ChildItem @args }
        function global:l { Get-ChildItem -Force @args }
        function global:ll { Get-ChildItem @args | Format-Table -AutoSize }
    }

    # Set vim alias if nvim exists
    if (Get-Command nvim -ErrorAction SilentlyContinue) {
        Set-Alias -Name vim -Value nvim -Scope Global
    }

    $Global:AliasesSet = $true
}

$env:PATH += ";$env:LOCALAPPDATA\Microsoft\WindowsApps"
