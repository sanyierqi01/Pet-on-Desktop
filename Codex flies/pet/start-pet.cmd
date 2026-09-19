@echo off
setlocal
cd /d "%~dp0"
pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0desktop-pet.ps1"
if errorlevel 1 (
    echo.
    echo The desktop pet exited with an error.
    pause
)
