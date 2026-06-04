@echo off
chcp 65001 > nul
cd /d "%~dp0"

:: ==========================================================
:: 配置项：是否在启动时显示 Vite 运行日志的命令行黑窗口？
:: 可直接用“记事本”编辑此行：
::   set SHOW_WINDOW=true   ->  (默认) 启动并显示黑窗口日志
::   set SHOW_WINDOW=false  ->  后台隐藏运行，桌面无黑窗口
:: ==========================================================
set SHOW_WINDOW=true

:: Bypasses execution policy and forwards configuration argument to PowerShell core
powershell -NoProfile -ExecutionPolicy Bypass -File "start.ps1" -ShowWindow "%SHOW_WINDOW%"
