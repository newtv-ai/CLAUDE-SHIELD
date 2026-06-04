@echo off
chcp 65001 > nul
cd /d "%~dp0"
set SHOW_WINDOW=true
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start.ps1" -ShowWindow "%SHOW_WINDOW%"
