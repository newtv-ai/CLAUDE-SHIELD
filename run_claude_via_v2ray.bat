@echo off
:: UTF-8 编码支持
chcp 65001 >nul
title Claude Shield - 快捷启动 (V2ray 全局桥接防封模式)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_claude_via_v2ray.ps1"
