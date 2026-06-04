@echo off
:: UTF-8 编码支持
chcp 65001 >nul
title Claude Shield - 一键配置环境
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_proxy_env.ps1"
pause
