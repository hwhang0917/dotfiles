@echo off
REM Batch script to start komorebi with config and then AutoHotkey
REM Modify the paths below to match your setup

REM =============================================================================
REM CONFIGURATION - UPDATE THESE PATHS
REM =============================================================================

REM Path to your komorebi config file
set "KOMOREBI_CONFIG=C:\Users\%USERNAME%\dotfiles\komorebi\komorebi.json"

REM Path to your AutoHotkey script
set "AHK_SCRIPT=C:\Users\%USERNAME%\dotfiles\komorebi\komorebi.ahk"

REM Path to AutoHotkey executable (adjust version as needed)
set "AHK_EXE=C:\%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey64.exe"

REM Optional: Path to komorebi bar config (if using)
set "BAR_CONFIG=C:\Users\%USERNAME%\dotfiles\komorebi\komorebi.bar.json"

REM =============================================================================
REM SCRIPT EXECUTION
REM =============================================================================

echo Starting Komorebi window manager...

REM Check if komorebi config exists
if not exist "%KOMOREBI_CONFIG%" (
    echo ERROR: Komorebi config file not found at: %KOMOREBI_CONFIG%
    echo Please update the KOMOREBI_CONFIG path in this script
    pause
    exit /b 1
)

REM Start komorebi with config
echo Loading komorebi with config: %KOMOREBI_CONFIG%
start /b komorebic start --config "%KOMOREBI_CONFIG%"

REM Wait a moment for komorebi to initialize
timeout /t 3 /nobreak >nul

REM Optional: Start komorebi bar if config exists
if exist "%BAR_CONFIG%" (
    echo Starting komorebi bar with config: %BAR_CONFIG%
    start /b komorebic bar --config "%BAR_CONFIG%"
    timeout /t 2 /nobreak >nul
) else (
    echo Bar config not found, skipping bar startup
)

REM Check if AutoHotkey script exists
if not exist "%AHK_SCRIPT%" (
    echo ERROR: AutoHotkey script not found at: %AHK_SCRIPT%
    echo Please update the AHK_SCRIPT path in this script
    pause
    exit /b 1
)

REM Check if AutoHotkey executable exists
if not exist "%AHK_EXE%" (
    echo ERROR: AutoHotkey executable not found at: %AHK_EXE%
    echo Please update the AHK_EXE path in this script
    echo Common locations:
    echo   - C:\Program Files\AutoHotkey\v2\AutoHotkey.exe
    echo   - C:\Program Files\AutoHotkey\AutoHotkey.exe
    pause
    exit /b 1
)

REM Start AutoHotkey script
echo Starting AutoHotkey script: %AHK_SCRIPT%
start "" "%AHK_EXE%" "%AHK_SCRIPT%"

echo.
echo =============================================================================
echo Startup complete!
echo - Komorebi is running with config: %KOMOREBI_CONFIG%
if exist "%BAR_CONFIG%" echo - Komorebi bar is running with config: %BAR_CONFIG%
echo - AutoHotkey script is running: %AHK_SCRIPT%
echo =============================================================================
echo.
echo Press any key to exit this window (services will continue running)
pause >nul
