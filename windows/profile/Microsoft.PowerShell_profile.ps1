Import-Module PSReadLine -Force:$false
Set-PSReadLineOption -EditMode Emacs

if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd | Out-String | Invoke-Expression
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

if (Get-Alias ls -ErrorAction SilentlyContinue) {
    Remove-Item alias:ls -Force
}

if (Get-Command eza -ErrorAction SilentlyContinue) {
    function global:ls { eza --icons --git @args }
    function global:l { eza --icons --git -lah @args }
    function global:ll { eza --icons --git -lh @args }
} else {
    function global:ls { Get-ChildItem @args }
    function global:l { Get-ChildItem -Force @args }
    function global:ll { Get-ChildItem @args | Format-Table -AutoSize }
}

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias -Name vim -Value nvim -Scope Global
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    Set-Alias -Name cat -Value bat -Scope Global
}

$env:PATH += ";$env:LOCALAPPDATA\Microsoft\WindowsApps"
