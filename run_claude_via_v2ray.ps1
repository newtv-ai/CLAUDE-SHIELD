# Claude Shield - 快捷启动 (V2ray 全局桥接防封模式) (Windows PowerShell)
# 编码格式: UTF-8 with BOM

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "    Claude Shield - 快捷启动工具 (配合 V2rayN / Clash)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[提示] 启动前请确保您的 v2rayN 或 Clash 软件已开启且代理工作正常。" -ForegroundColor Yellow
Write-Host ""

$configFile = Join-Path $PSScriptRoot "vps_config.json"

# 默认初始参数
$localPort = 10808
$targetTz = "America/New_York"
$useSaved = $false

# 1. 尝试从 vps_config.json 读取配置
if (Test-Path $configFile) {
    try {
        $loadedConfig = Get-Content $configFile -Raw | ConvertFrom-Json
        if ($loadedConfig) {
            # 兼容性处理：优先读取 v2ray_local_port，其次 local_port，最后 10808 默认值
            if ($loadedConfig.v2ray_local_port) {
                $localPort = $loadedConfig.v2ray_local_port
                $useSaved = $true
            } elseif ($loadedConfig.local_port) {
                $localPort = $loadedConfig.local_port
                $useSaved = $true
            }
            
            if ($loadedConfig.vps_tz) {
                $targetTz = $loadedConfig.vps_tz
            }
        }
    } catch {
        Write-Host "⚠️ 读取配置文件失败，将重新配置。" -ForegroundColor Yellow
    }
}

# 2. 如果无配置文件（首次启动），引导交互输入并保存
if (-not $useSaved) {
    Write-Host "请输入您的本地代理参数（配置将被保存，后续运行将自动加载无需再次输入）：" -ForegroundColor Cyan
    
    Write-Host "💡 提示：新版 v2rayN (Mixed) 默认是 10808，Clash 默认是 7890；如果您是老版本 v2rayN 分立端口，HTTP 端口通常为 10809。" -ForegroundColor Yellow
    $portStr = Read-Host "👉 请输入本地 HTTP 代理端口 (默认 10808, 直接回车使用默认)"
    if (-not [string]::IsNullOrWhiteSpace($portStr)) {
        if ([int]::TryParse($portStr, [ref]$portObj)) {
            $localPort = $portObj
        }
    }
    
    $tzStr = Read-Host "👉 请输入节点目标时区 (默认 America/New_York, 直接回车使用默认)"
    if (-not [string]::IsNullOrWhiteSpace($tzStr)) {
        $targetTz = $tzStr.Trim()
    }
    
    # 合并保存配置，不覆盖已有的 VPS 配置
    $existing = @{}
    if (Test-Path $configFile) {
        try {
            $existing = Get-Content $configFile -Raw | ConvertFrom-Json -AsHashtable
        } catch {}
    }
    $existing["v2ray_local_port"] = $localPort
    $existing["vps_tz"] = $targetTz

    $existing | ConvertTo-Json | Out-File $configFile -Encoding utf8
    Write-Host "✅ 配置已成功保存至 $configFile`n" -ForegroundColor Green
} else {
    Write-Host "💡 自动加载已保存的本地配置：" -ForegroundColor Green
    Write-Host "   - 本地 HTTP 端口: $localPort (注：新版 v2rayN 混合/Clash 推荐 10808/7890，老版 v2rayN 推荐 10809)"
    Write-Host "   - 锁定目标时区: $targetTz"
    Write-Host "   *(如需修改配置，请直接删除同目录下的 vps_config.json)*`n" -ForegroundColor Gray
}

Write-Host "📡 正在注入 Windows 用户级全局环境变量..." -ForegroundColor Cyan

# 注入环境变量（使用兼容性最佳的 http 协议，避免 Node.js 报 UnsupportedProxyProtocol 错误）
$proxyVal = "http://127.0.0.1:$localPort"

try {
    [Environment]::SetEnvironmentVariable("HTTP_PROXY", $proxyVal, "User")
    [Environment]::SetEnvironmentVariable("HTTPS_PROXY", $proxyVal, "User")
    [Environment]::SetEnvironmentVariable("TZ", $targetTz, "User")
    [Environment]::SetEnvironmentVariable("LANG", "en_US.UTF-8", "User")
    [Environment]::SetEnvironmentVariable("LC_ALL", "en_US.UTF-8", "User")
    
    # 当前会话也注入，立即可用
    $env:HTTP_PROXY = $proxyVal
    $env:HTTPS_PROXY = $proxyVal
    $env:TZ = $targetTz
    $env:LANG = "en_US.UTF-8"
    $env:LC_ALL = "en_US.UTF-8"
    
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host " ✅ 全局安全环境防护已成功激活！" -ForegroundColor Green
    Write-Host " - 代理中继: $proxyVal" -ForegroundColor Green
    Write-Host " - 锁定时区: $targetTz" -ForegroundColor Green
    Write-Host ""
    Write-Host " 🌟 无需任何编辑器配置！您新开的任何终端、PowerShell 窗口都会自动受保护。" -ForegroundColor Green
    Write-Host " 👉 请直接在任意新终端里运行您的工具：" -ForegroundColor Cyan
    Write-Host "   - 启动 Claude Code: 直接输入 claude" -ForegroundColor Cyan
    Write-Host "   - 启动 Antigravity / Codex: 直接输入您的 Agent 启动命令" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "⚠️ 写入 Windows 全局环境变量失败（可能权限不足）。环境变量已降级为仅在当前窗口生效。" -ForegroundColor Yellow
}

Write-Host "⚠️ [重要] 请保持本窗口挂在后台运行。" -ForegroundColor Yellow
Write-Host "⚠️ 结束工作后，请在下方窗口内按回车键，脚本会自动为您还原系统环境变量。" -ForegroundColor DarkYellow
Write-Host "----------------------------------------------------------"
Write-Host ""

Read-Host "按下 [Enter] 键还原清理配置并退出"

Write-Host ""
Write-Host "🧹 正在清理还原 Windows 全局环境变量..." -ForegroundColor Cyan
try {
    [Environment]::SetEnvironmentVariable("HTTP_PROXY", $null, "User")
    [Environment]::SetEnvironmentVariable("HTTPS_PROXY", $null, "User")
    [Environment]::SetEnvironmentVariable("TZ", $null, "User")
    [Environment]::SetEnvironmentVariable("LANG", $null, "User")
    [Environment]::SetEnvironmentVariable("LC_ALL", $null, "User")
    Write-Host "✅ 全局环境变量已成功还原清除，网络已恢复干净直连状态。" -ForegroundColor Green
} catch {
    Write-Host "⚠️ 清理全局环境变量失败。" -ForegroundColor Red
}

Write-Host "本清理窗口将在 3 秒后关闭..."
Start-Sleep -Seconds 3
