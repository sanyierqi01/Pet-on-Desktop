@echo off
setlocal
cd /d "%~dp0"
pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0desktop-pet.ps1" -ExportPreview
if errorlevel 1 pause
