# Claude Shield VPS 代理与防泄露环境一键清理脚本 (Windows PowerShell)
# 编码格式: UTF-8 with BOM

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "    Claude Shield - VPS 代理与防泄露环境一键清理还原工具" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$pidFile = Join-Path $PSScriptRoot "ssh_tunnel.pid"

# 1. 关停后台运行的 SSH 代理进程
if (Test-Path $pidFile) {
    $oldPid = Get-Content $pidFile -Raw
    if (![string]::IsNullOrWhiteSpace($oldPid)) {
        $oldPid = $oldPid.Trim()
        Write-Host "🔄 正在检测 SSH 隧道进程 (PID: $oldPid)..."
        
        $proc = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "🔄 正在终止 SSH 隧道后台窗口及相关进程..." -ForegroundColor Yellow
            # 杀掉进程树以彻底清理 CMD 和 SSH
            taskkill /F /T /PID $oldPid >$null 2>&1
            Write-Host "✅ SSH 隧道已成功关闭。" -ForegroundColor Green
        } else {
            Write-Host "✅ SSH 隧道进程未处于运行状态。" -ForegroundColor Green
        }
    }
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "ℹ️ 未找到 active 的 SSH 隧道运行记录。" -ForegroundColor Gray
}

# 2. 清除当前会话与 Windows 用户级环境变量
$env:HTTP_PROXY = $null
$env:HTTPS_PROXY = $null
$env:TZ = $null
$env:LANG = $null
$env:LC_ALL = $null

try {
    [Environment]::SetEnvironmentVariable("HTTP_PROXY", $null, "User")
    [Environment]::SetEnvironmentVariable("HTTPS_PROXY", $null, "User")
    [Environment]::SetEnvironmentVariable("TZ", $null, "User")
    [Environment]::SetEnvironmentVariable("LANG", $null, "User")
    [Environment]::SetEnvironmentVariable("LC_ALL", $null, "User")
    
    Write-Host "🧹 全局用户环境变量已成功还原清除！" -ForegroundColor Green
    Write-Host "📢 提示：新开的命令行或 VS Code 终端将不再包含任何代理设置，网络已恢复直连状态。" -ForegroundColor Green
    Write-Host "   *(注意：已经打开的终端需要新建或重启才能恢复正常网络)*" -ForegroundColor Yellow
} catch {
    Write-Host "⚠️ 清除 Windows 全局环境变量失败（可能权限不足）。" -ForegroundColor Yellow
}
Write-Host ""

# 3. 清理沙箱浏览器的临时 Profile
$tempProfile = Join-Path $env:TEMP "claude-isolated-profile"
if (Test-Path $tempProfile) {
    Write-Host "🧹 检测到隔离浏览器的临时沙盒目录..." -ForegroundColor Gray
    
    $confirm = Read-Host "是否彻底删除防泄漏浏览器的临时缓存与登录 Cookie？(Y/N，选择 Y 确保下次使用绝对纯净，默认为 N)"
    if ($confirm -and $confirm.Trim().ToUpper() -eq "Y") {
        Write-Host "正在删除 $tempProfile..." -ForegroundColor Yellow
        # 强制递归删除
        Remove-Item $tempProfile -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ 隔离浏览器数据已彻底销毁，无任何残留。" -ForegroundColor Green
    } else {
        Write-Host "保留隔离浏览器数据（下次启动可保持已登录状态）。" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "🎉 还原工作已全部完成！您的网络和环境变量已恢复到初始状态。" -ForegroundColor Green
Write-Host "一键清理窗口将在 3 秒后关闭..."
Start-Sleep -Seconds 3
