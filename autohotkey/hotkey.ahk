#Requires AutoHotkey v2.0

; Switch input language to English
^Space::
{
    Send "{vk15sc1F1}"
}

; Switch input to English and send Escape (for exiting Vim insert mode in Korean)
^[::
{
    Send "{vk15sc1F1}"
    Sleep 50
    Send "{Esc}"
}

; CapsLock::Ctrl

; Remap Pause to CapsLock
Pause::CapsLock

; Cycle between windows of the same application (macOS-style Alt+Tab)
#`::
{
    ActiveClass := WinGetClass("A")
    WinClassCount := WinGetCount("ahk_class " . ActiveClass)
    If (WinClassCount = 1)
        Return
    Else
    {
        WinMoveBottom("A")
        WinActivate("ahk_class " . ActiveClass)
    }
}

; Disable Win+M (minimize all)
#m::return

