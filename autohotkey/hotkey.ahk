#Requires AutoHotkey v2.0.2
#SingleInstance Force
SetWorkingDir A_ScriptDir

; Ctrl+Space to toggle between English and Korean
^Space::
{
    Send("{vk15sc1F2}")
}

; Alt+Shift+Enter to run Terminal Emulator
!+Enter::
{
    Run "C:\Program Files\Alacritty\alacritty.exe"
}
