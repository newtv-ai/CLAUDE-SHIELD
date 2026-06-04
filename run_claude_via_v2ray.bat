@echo off
:: UTF-8 编码支持
chcp 65001 >nul
title Claude Shield - 快捷启动 (V2ray 全局桥接防封模式)

echo ==========================================================
echo    Claude Shield - 快捷启动工具 (配合 V2rayN / Clash)
echo ==========================================================
echo.
echo [提示] 启动前请确保您的 v2rayN 或 Clash 软件已开启且代理工作正常。
echo.

set CONFIG_FILE=vps_config.json

:: 默认初始参数
set LOCAL_PORT=10808
set TARGET_TZ=America/New_York
set HAS_CONFIG=0

:: 1. 尝试从 vps_config.json 读取配置
if exist %CONFIG_FILE% (
    for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "$json = Get-Content '%CONFIG_FILE%' -Raw | ConvertFrom-Json; if ($json.v2ray_local_port) { $json.v2ray_local_port } else { $json.local_port }"`) do set LOCAL_PORT=%%i
    for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "$json = Get-Content '%CONFIG_FILE%' -Raw | ConvertFrom-Json; $json.vps_tz"`) do set TARGET_TZ=%%i
    
    if not "%LOCAL_PORT%"=="" if not "%LOCAL_PORT%"=="null" (
        set HAS_CONFIG=1
    )
)

:: 移除多余空格和双引号
if not "%LOCAL_PORT%"=="" set LOCAL_PORT=%LOCAL_PORT: =%
if not "%TARGET_TZ%"=="" set TARGET_TZ=%TARGET_TZ: =%
if not "%TARGET_TZ%"=="" set TARGET_TZ=%TARGET_TZ:"=%

:: 2. 如果无配置文件（首次启动），引导交互输入并保存
if "%HAS_CONFIG%"=="0" (
    echo [配置] 检测到是首次运行，请配置您的本地代理参数（配置将被保存无需下次重复输入）：
    
    set /p USER_PORT="👉 请输入本地 SOCKS5 代理端口 (默认 10808, 直接回车使用默认): "
    if not "%USER_PORT%"=="" set LOCAL_PORT=%USER_PORT%
    
    set /p USER_TZ="👉 请输入节点目标时区 (默认 America/New_York, 直接回车使用默认): "
    if not "%USER_TZ%"=="" set TARGET_TZ=%USER_TZ%
    
    :: 合并写入配置，保留原有配置的其他字段
    powershell -NoProfile -Command "$json = if (Test-Path '%CONFIG_FILE%') { Get-Content '%CONFIG_FILE%' -Raw | ConvertFrom-Json } else { [PSCustomObject]@{} }; $json | Add-Member -NotePropertyName 'v2ray_local_port' -NotePropertyValue %LOCAL_PORT% -Force; $json | Add-Member -NotePropertyName 'vps_tz' -NotePropertyValue '%TARGET_TZ%' -Force; $json | ConvertTo-Json | Out-File '%CONFIG_FILE%' -Encoding utf8"
    
    echo ✅ 配置已成功保存至 %CONFIG_FILE%！
    echo.
) else (
    echo 💡 自动加载已保存的本地配置：
    echo    - 本地 SOCKS5 端口: %LOCAL_PORT%
    echo    - 锁定目标时区: %TARGET_TZ%
    echo    *(如需修改配置，请直接删除同目录下的 vps_config.json)*
    echo.
)

echo 📡 正在注入 Windows 用户级全局环境变量...

:: 注入环境变量（必须使用 socks5h 强制由 VPS 远程解析 DNS，避免本地 DNS 泄露）
set PROXY_VAL=socks5h://127.0.0.1:%LOCAL_PORT%
powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('HTTP_PROXY', '%PROXY_VAL%', 'User')"
powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('HTTPS_PROXY', '%PROXY_VAL%', 'User')"
powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('TZ', '%TARGET_TZ%', 'User')"
powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('LANG', 'en_US.UTF-8', 'User')"
powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('LC_ALL', 'en_US.UTF-8', 'User')"

:: 当前会话也注入，立即可用
set HTTPS_PROXY=%PROXY_VAL%
set HTTP_PROXY=%PROXY_VAL%
set TZ=%TARGET_TZ%
set LANG=en_US.UTF-8
set LC_ALL=en_US.UTF-8

echo.
echo ==========================================================
echo  ✅ 全局安全环境防护已成功激活！
echo  - 代理中继: %PROXY_VAL%
echo  - 锁定时区: %TZ%
echo.
echo  🌟 无需 VS Code 配置！您新开的任何终端、PowerShell 窗口都会自动受保护。
echo  👉 请直接在任意新终端里运行您的工具：
echo    - 启动 Claude Code: 直接输入 claude
echo    - 启动 Antigravity / Codex: 直接输入您的 Agent 启动命令
echo ==========================================================
echo.
echo ⚠️ [重要] 请保持本窗口挂在后台运行。
echo ⚠️ 结束工作后，请在【下方窗口内按任意键】，脚本会自动为您还原系统环境变量。
echo ----------------------------------------------------------
echo.

pause

echo.
echo 🧹 正在清理还原 Windows 全局环境变量...
powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('HTTP_PROXY', $null, 'User')"
powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('HTTPS_PROXY', $null, 'User')"
powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('TZ', $null, 'User')"
powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('LANG', $null, 'User')"
powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('LC_ALL', $null, 'User')"

echo ✅ 全局环境变量已成功还原清除，网络已恢复干净直连状态。
echo 本清理窗口将在 3 秒后关闭...
timeout /t 3 >nul
