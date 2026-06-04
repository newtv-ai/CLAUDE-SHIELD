@echo off
:: UTF-8 编码支持
chcp 65001 >nul
title Claude Shield - 一键还原环境
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore_proxy_env.ps1"
