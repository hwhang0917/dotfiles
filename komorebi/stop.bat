@echo off
REM Batch script to stop komorebi and AutoHotkey
REM This will gracefully shut down all komorebi services and AutoHotkey scripts

echo =============================================================================
echo Stopping Komorebi and AutoHotkey services...
echo =============================================================================
echo.

REM Stop komorebi (this will also stop the bar if running)
echo Stopping komorebi window manager...
komorebic stop >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✓ Komorebi stopped successfully
) else (
    echo   ! Komorebi may not have been running or failed to stop
)

REM Wait a moment for komorebi to fully shut down
timeout /t 2 /nobreak >nul

REM Kill any remaining komorebi processes
echo Cleaning up komorebi processes...
taskkill /f /im "komorebi.exe" >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✓ Killed remaining komorebi.exe processes
)

taskkill /f /im "komorebic.exe" >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✓ Killed remaining komorebic.exe processes
)

REM Stop AutoHotkey scripts
echo Stopping AutoHotkey scripts...
taskkill /f /im "AutoHotkey.exe" >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✓ Stopped AutoHotkey v1 scripts
)

taskkill /f /im "AutoHotkey32.exe" >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✓ Stopped AutoHotkey v1 (32-bit) scripts
)

taskkill /f /im "AutoHotkey64.exe" >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✓ Stopped AutoHotkey v1 (64-bit) scripts
)

REM AutoHotkey v2 has different executable names
for %%i in ("AutoHotkeyU32.exe" "AutoHotkeyU64.exe" "AutoHotkeyA32.exe") do (
    taskkill /f /im %%i >nul 2>&1
    if !errorlevel! equ 0 (
        echo   ✓ Stopped %%i
    )
)

REM Check for any remaining processes
echo.
echo Checking for remaining processes...

REM Check for komorebi
tasklist /fi "imagename eq komorebi.exe" 2>nul | find /i "komorebi.exe" >nul
if %errorlevel% equ 0 (
    echo   ! Warning: komorebi.exe is still running
) else (
    echo   ✓ No komorebi processes found
)

REM Check for AutoHotkey
set "ahk_found=false"
for %%i in ("AutoHotkey.exe" "AutoHotkey32.exe" "AutoHotkey64.exe" "AutoHotkeyU32.exe" "AutoHotkeyU64.exe" "AutoHotkeyA32.exe") do (
    tasklist /fi "imagename eq %%i" 2>nul | find /i %%i >nul
    if !errorlevel! equ 0 (
        echo   ! Warning: %%i is still running
        set "ahk_found=true"
    )
)

if "%ahk_found%"=="false" (
    echo   ✓ No AutoHotkey processes found
)

echo.
echo =============================================================================
echo Shutdown complete!
echo.
echo If you want to restart everything, run the startup script again.
echo =============================================================================
echo.
echo Press any key to exit...
pause >nul
