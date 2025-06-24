#Requires AutoHotkey v2.0.2
#SingleInstance Force

Komorebic(cmd) {
    RunWait(format("komorebic.exe {}", cmd), , "Hide")
}

!q::Komorebic("close")
!m::Komorebic("minimize")

; Focus windows
!h::Komorebic("focus left")
!j::Komorebic("focus down")
!k::Komorebic("focus up")
!l::Komorebic("focus right")

!+[::Komorebic("cycle-focus previous")
!+]::Komorebic("cycle-focus next")

; Move windows
!+h::Komorebic("move left")
!+j::Komorebic("move down")
!+k::Komorebic("move up")
!+l::Komorebic("move right")

; Stack windows
; !Left::Komorebic("stack left")
; !Down::Komorebic("stack down")
; !Up::Komorebic("stack up")
; !Right::Komorebic("stack right")
; !;::Komorebic("unstack")
; ![::Komorebic("cycle-stack previous")
; !]::Komorebic("cycle-stack next")

; Resize
!=::Komorebic("resize-axis horizontal increase")
!-::Komorebic("resize-axis horizontal decrease")
!+=::Komorebic("resize-axis vertical increase")
!+_::Komorebic("resize-axis vertical decrease")

; Manipulate windows
!t::Komorebic("toggle-float")
!f::Komorebic("toggle-monocle")

; Window manager options
!+r::Komorebic("retile")
!+p::Komorebic("toggle-pause")

; Layouts
!x::Komorebic("flip-layout horizontal")
!y::Komorebic("flip-layout vertical")

; Workspaces
!1::Komorebic("focus-workspace 0")
!2::Komorebic("focus-workspace 1")
!3::Komorebic("focus-workspace 2")
!4::Komorebic("focus-workspace 3")
!5::Komorebic("focus-workspace 4")
!6::Komorebic("focus-workspace 5")
!7::Komorebic("focus-workspace 6")
!8::Komorebic("focus-workspace 7")
!9::Komorebic("focus-workspace 8")

; Move windows across workspaces
!+1::Komorebic("move-to-workspace 0")
!+2::Komorebic("move-to-workspace 1")
!+3::Komorebic("move-to-workspace 2")
!+4::Komorebic("move-to-workspace 3")
!+5::Komorebic("move-to-workspace 4")
!+6::Komorebic("move-to-workspace 5")
!+7::Komorebic("move-to-workspace 6")
!+8::Komorebic("move-to-workspace 7")
!+9::Komorebic("move-to-workspace 8")

; Workspace switchting
; AutoHotkey v2.0 script for toggling between two most recent workspaces in komorebi
; Prevents command prompt flickering by running komorebi commands hidden

; Global variables to track workspace history
currentWorkspace := 0
previousWorkspace := 0

; Function to get current workspace without showing command prompt
GetCurrentWorkspace() {
    ; Run komorebi query and capture output without showing window
    result := ""
    try {
        ; Use RunWait with hidden window to prevent flickering
        RunWait('komorebic.exe query focused-workspace-index', , "Hide", &pid)

        ; Create temporary file to capture output
        tempFile := A_Temp . "\komorebi_workspace.tmp"
        RunWait('komorebic.exe query focused-workspace-index > "' . tempFile . '"', , "Hide")

        ; Read the result from temp file
        if FileExist(tempFile) {
            result := FileRead(tempFile)
            FileDelete(tempFile)
            ; Clean up the result (remove newlines/spaces)
            result := Trim(result)
        }
    } catch {
        ; Fallback - assume workspace 0 if query fails
        result := "0"
    }

    return Integer(result)
}

; Function to switch to a specific workspace without showing command prompt
SwitchToWorkspace(workspaceIndex) {
    try {
        ; Run komorebi switch command hidden
        Run('komorebic.exe focus-workspace ' . workspaceIndex, , "Hide")
    } catch {
        ; Silently fail if command doesn't work
    }
}

; Function to update workspace history
UpdateWorkspaceHistory() {
    newWorkspace := GetCurrentWorkspace()

    ; Only update if workspace actually changed
    if (newWorkspace != currentWorkspace) {
        previousWorkspace := currentWorkspace
        currentWorkspace := newWorkspace
    }
}

; Initialize current workspace on script start
currentWorkspace := GetCurrentWorkspace()

; Hotkey: Alt+Tab to toggle between current and previous workspace
!Tab:: {
    ; Get current workspace to make sure we're up to date
    currentWs := GetCurrentWorkspace()

    ; If this is the first time or we only have one workspace in history
    if (previousWorkspace == 0 && currentWs == 0) {
        ; Try to switch to workspace 1 if we're on 0
        SwitchToWorkspace(1)
        previousWorkspace := 0
        currentWorkspace := 1
    } else if (previousWorkspace == currentWorkspace) {
        ; If somehow previous equals current, try to find another workspace
        targetWorkspace := (currentWs == 0) ? 1 : 0
        SwitchToWorkspace(targetWorkspace)
        previousWorkspace := currentWorkspace
        currentWorkspace := targetWorkspace
    } else {
        ; Normal toggle between current and previous
        SwitchToWorkspace(previousWorkspace)

        ; Swap the workspaces
        temp := currentWorkspace
        currentWorkspace := previousWorkspace
        previousWorkspace := temp
    }
}

; Optional: Track workspace changes from other sources (like komorebi hotkeys)
; This timer periodically checks if workspace changed externally
SetTimer(UpdateWorkspaceHistory, 1000)

; Optional: Additional hotkeys for manual workspace switching that update history
; Uncomment and modify these if you want to track other workspace switches

/*
; Win+1 through Win+9 for direct workspace switching
Loop 9 {
    Hotkey("Win" . A_Index, (*) => {
        workspaceNum := SubStr(A_ThisHotkey, 4) - 1  ; Convert to 0-based index
        SwitchToWorkspace(workspaceNum)
        previousWorkspace := currentWorkspace
        currentWorkspace := workspaceNum
    })
}
*/
