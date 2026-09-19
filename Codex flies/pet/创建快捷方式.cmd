@echo off
setlocal
cd /d "%~dp0"
pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install-shortcuts.ps1"
if errorlevel 1 (
    echo.
    echo Failed to create the shortcuts.
    pause
)
