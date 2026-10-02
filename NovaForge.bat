@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\NovaForge.ps1"
if errorlevel 1 (
    echo.
    echo Nova Forge exited with an error. See above.
    pause
)
