# Claude Shield VPS 代理与防泄露环境一键配置脚本 (Windows PowerShell)
# 编码格式: UTF-8 with BOM

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "    Claude Shield - VPS 代理与防泄露一键配置工具" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$configFile = Join-Path $PSScriptRoot "vps_config.json"
$pidFile = Join-Path $PSScriptRoot "ssh_tunnel.pid"

# 默认配置
$vpsConfig = @{
    vps_ip = ""
    ssh_user = "root"
    ssh_port = 22
    ssh_local_port = 1080
    vps_tz = "America/New_York"
}

$useSaved = $false

# 1. 尝试无感加载已有配置
if (Test-Path $configFile) {
    try {
        $loadedConfig = Get-Content $configFile -Raw | ConvertFrom-Json
        if ($loadedConfig -and ![string]::IsNullOrWhiteSpace($loadedConfig.vps_ip)) {
            $vpsConfig.vps_ip = $loadedConfig.vps_ip
            $vpsConfig.ssh_user = $loadedConfig.ssh_user
            $vpsConfig.ssh_port = $loadedConfig.ssh_port
            
            # 兼容性处理：优先读取 ssh_local_port，其次 local_port，最后 1080 默认值
            if ($loadedConfig.ssh_local_port) {
                $vpsConfig.ssh_local_port = $loadedConfig.ssh_local_port
            } elseif ($loadedConfig.local_port) {
                $vpsConfig.ssh_local_port = $loadedConfig.local_port
            } else {
                $vpsConfig.ssh_local_port = 1080
            }
            
            $vpsConfig.vps_tz = $loadedConfig.vps_tz
            
            Write-Host "💡 自动加载已保存的配置：" -ForegroundColor Green
            Write-Host "   - VPS IP: $($vpsConfig.vps_ip)"
            Write-Host "   - SSH 用户: $($vpsConfig.ssh_user)"
            Write-Host "   - SSH 端口: $($vpsConfig.ssh_port)"
            Write-Host "   - 本地代理端口: $($vpsConfig.ssh_local_port)"
            Write-Host "   - VPS 目标时区: $($vpsConfig.vps_tz)"
            Write-Host "   *(如需修改配置，请直接删除同目录下的 vps_config.json)*`n" -ForegroundColor Gray
            $useSaved = $true
        }
    } catch {
        Write-Host "⚠️ 读取配置文件失败，将重新配置。" -ForegroundColor Yellow
    }
}

# 2. 第一次使用，引导交互输入
if (-not $useSaved) {
    Write-Host "请输入您的 VPS 连接配置（配置将保存在本地 vps_config.json 中，后续运行将自动加载无需再次输入）："
    
    $ip = ""
    while ([string]::IsNullOrWhiteSpace($ip)) {
        $ip = Read-Host "👉 请输入 VPS 的 IP 地址或域名 (必填)"
    }
    $vpsConfig.vps_ip = $ip.Trim()

    $user = Read-Host "👉 请输入 SSH 用户名 (默认: root)"
    if (-not [string]::IsNullOrWhiteSpace($user)) { $vpsConfig.ssh_user = $user.Trim() }

    $portStr = Read-Host "👉 请输入 SSH 端口号 (默认: 22)"
    if (-not [string]::IsNullOrWhiteSpace($portStr)) {
        if ([int]::TryParse($portStr, [ref]$portObj)) {
            $vpsConfig.ssh_port = $portObj
        }
    }

    $localPortStr = Read-Host "👉 请输入本地 SOCKS5 代理端口 (默认: 1080)"
    if (-not [string]::IsNullOrWhiteSpace($localPortStr)) {
        if ([int]::TryParse($localPortStr, [ref]$localPortObj)) {
            $vpsConfig.ssh_local_port = $localPortObj
        }
    }

    $tz = Read-Host "👉 请输入 VPS 所在的 IANA 时区 (默认: America/New_York)"
    if (-not [string]::IsNullOrWhiteSpace($tz)) { $vpsConfig.vps_tz = $tz.Trim() }

    # 合并保存配置，不覆盖已有的 v2ray 配置
    $existing = @{}
    if (Test-Path $configFile) {
        try {
            $existing = Get-Content $configFile -Raw | ConvertFrom-Json -AsHashtable
        } catch {}
    }
    $existing["vps_ip"] = $vpsConfig.vps_ip
    $existing["ssh_user"] = $vpsConfig.ssh_user
    $existing["ssh_port"] = $vpsConfig.ssh_port
    $existing["ssh_local_port"] = $vpsConfig.ssh_local_port
    $existing["vps_tz"] = $vpsConfig.vps_tz

    $existing | ConvertTo-Json | Out-File $configFile -Encoding utf8
    Write-Host "✅ 配置已成功保存至 $configFile`n" -ForegroundColor Green
}

# 3. 检查并清理旧的 SSH 隧道
if (Test-Path $pidFile) {
    $oldPid = Get-Content $pidFile -Raw
    if (![string]::IsNullOrWhiteSpace($oldPid)) {
        $oldPid = $oldPid.Trim()
        $proc = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "🔄 检测到已存在运行中的旧 SSH 隧道 (PID: $oldPid)，正在关闭..." -ForegroundColor Yellow
            Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        }
    }
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}

# 检查本地代理端口是否已被占用
$portOccupied = Get-NetTCPConnection -LocalPort $vpsConfig.ssh_local_port -ErrorAction SilentlyContinue | Where-Object { $_.State -eq "Listen" }
if ($portOccupied) {
    Write-Host "⚠️ 本地端口 $($vpsConfig.ssh_local_port) 已被其他程序占用！" -ForegroundColor Red
    Write-Host "请先关闭占用该端口的程序，或者运行 restore_proxy_env.ps1，或在配置中修改本地代理端口。" -ForegroundColor Red
    Read-Host "按回车键退出..."
    exit
}

# 4. 建立 SSH SOCKS5 动态端口转发隧道
Write-Host "🚀 正在建立指向 VPS ($($vpsConfig.vps_ip)) 的加密隧道..." -ForegroundColor Cyan
Write-Host "🔑 如果提示输入密码或指纹确认，请在新弹出的窗口中完成授权。" -ForegroundColor Yellow

$sshArgs = "-N -D 127.0.0.1:$($vpsConfig.ssh_local_port) -p $($vpsConfig.ssh_port) $($vpsConfig.ssh_user)@$($vpsConfig.vps_ip)"

# 新开窗口运行 SSH 隧道，以便用户交互（输入密码/指纹）
$sshProcess = Start-Process cmd -ArgumentList "/c title Claude SSH Tunnel & ssh $sshArgs" -PassThru -WindowStyle Minimized

if ($sshProcess) {
    $sshProcess.Id | Out-File $pidFile -Encoding ascii
    Write-Host "✅ SSH 隧道后台窗口已成功开启 (PID: $($sshProcess.Id))。" -ForegroundColor Green
    Write-Host "📡 本地 SOCKS5 代理已监听在 127.0.0.1:$($vpsConfig.ssh_local_port)" -ForegroundColor Green
} else {
    Write-Host "❌ 启动 SSH 进程失败，请确认系统是否已安装 OpenSSH 客户端（Windows 10/11 默认已自带，可在 cmd 中运行 ssh 测试）。" -ForegroundColor Red
    Read-Host "按回车键退出..."
    exit
}

# 延迟等待隧道可能需要的密码输入或连接建立
Write-Host "⏳ 等待 3 秒以确保隧道初始化完成..."
Start-Sleep -Seconds 3

# 5. 配置防泄露环境变量
# 核心防御：强制由远程 VPS 解析 DNS，杜绝 DNS 本地泄露风险！
$proxyVal = "socks5://127.0.0.1:$($vpsConfig.ssh_local_port)"
$tzVal = $vpsConfig.vps_tz

# 同时注入当前会话（立立即生效）
$env:HTTP_PROXY = $proxyVal
$env:HTTPS_PROXY = $proxyVal
$env:TZ = $tzVal
$env:LANG = "en_US.UTF-8"
$env:LC_ALL = "en_US.UTF-8"

Write-Host "🌐 正在将防泄露配置写入 Windows 用户级环境变量中..." -ForegroundColor Cyan

try {
    [Environment]::SetEnvironmentVariable("HTTP_PROXY", $proxyVal, "User")
    [Environment]::SetEnvironmentVariable("HTTPS_PROXY", $proxyVal, "User")
    [Environment]::SetEnvironmentVariable("TZ", $tzVal, "User")
    [Environment]::SetEnvironmentVariable("LANG", "en_US.UTF-8", "User")
    [Environment]::SetEnvironmentVariable("LC_ALL", "en_US.UTF-8", "User")
    
    Write-Host "✅ 全局用户环境变量已成功注入！" -ForegroundColor Green
    Write-Host "   - HTTP(S)_PROXY = $proxyVal"
    Write-Host "   - TZ = $tzVal"
    Write-Host "   - LANG = en_US.UTF-8"
    Write-Host ""
    Write-Host "📢 重要提示：新开的任何窗口（例如新建 VS Code 终端、新的 CMD 或 PowerShell）将【自动激活】安全防护！" -ForegroundColor Yellow
    Write-Host "   您无需在其他窗口中配置或运行任何命令，直接输入 claude 即可畅玩。" -ForegroundColor Green
    Write-Host "   *(注意：已经打开的旧窗口需要关闭并重新打开才会生效)*" -ForegroundColor Yellow
    Write-Host "   ⚠️ 退出时请务必运行 restore_proxy_env.bat 清理全局环境变量，否则可能影响日常未代理工具的联网。" -ForegroundColor DarkYellow
} catch {
    Write-Host "⚠️ 写入 Windows 全局环境变量失败（可能权限不足）。环境变量已降级为仅在当前窗口生效。" -ForegroundColor Yellow
}
Write-Host ""

# 6. 提供极速沙箱防泄漏浏览器启动
function Start-IsolatedBrowser {
    param(
        [string]$BrowserType
    )
    
    $tempProfile = Join-Path $env:TEMP "claude-isolated-profile"
    $proxyArg = "--proxy-server=socks5://127.0.0.1:$($vpsConfig.ssh_local_port)"
    $profileArg = "--user-data-dir=$tempProfile"
    $langArg = "--lang=en-US --accept-lang=en-US,en"
    $privacyArg = "--disable-features=WebRtcHideLocalIpsWithMdns --disable-encryption-binding"
    $targetUrls = "https://browserleaks.com/webrtc https://claude.ai"

    if ($BrowserType -eq "chrome") {
        $chromePaths = @(
            "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
            "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
            "${env:LocalAppData}\Google\Chrome\Application\chrome.exe"
        )
        $chromePath = $chromePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
        
        if ($chromePath) {
            Write-Host "🚀 正在启动隔离的 Google Chrome 浏览器窗口..." -ForegroundColor Cyan
            Start-Process $chromePath -ArgumentList "$proxyArg $profileArg $langArg $privacyArg $targetUrls"
            return $true
        }
    } else {
        $edgePaths = @(
            "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe",
            "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
            "${env:LocalAppData}\Microsoft\Edge\Application\msedge.exe"
        )
        $edgePath = $edgePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
        
        if ($edgePath) {
            Write-Host "🚀 正在启动隔离的 Microsoft Edge 浏览器窗口..." -ForegroundColor Cyan
            Start-Process $edgePath -ArgumentList "$proxyArg $profileArg $langArg $privacyArg $targetUrls"
            return $true
        }
    }
    return $false
}

# 交互选择后续操作
while ($true) {
    Write-Host "--- 后续操作选择 ---"
    Write-Host "1. 启动【独立防泄漏 Google Chrome 浏览器】进行网页端授权"
    Write-Host "2. 启动【独立防泄漏 Microsoft Edge 浏览器】进行网页端授权"
    Write-Host "3. 保持后台 SSH 隧道与全局环境变量，并退出本窗口"
    Write-Host "4. 关闭 SSH 隧道、清除全局环境变量并安全退出"
    Write-Host ""
    $opt = Read-Host "👉 请输入选项序号 (1-4)"
    
    switch ($opt) {
        "1" {
            if (-not (Start-IsolatedBrowser -BrowserType "chrome")) {
                Write-Host "❌ 未在您的电脑上找到 Google Chrome 浏览器，正在尝试启动 Edge..." -ForegroundColor Yellow
                if (-not (Start-IsolatedBrowser -BrowserType "edge")) {
                    Write-Host "❌ 自动启动浏览器失败，请手动打开您的浏览器，并配置代理 socks5://127.0.0.1:$($vpsConfig.ssh_local_port)" -ForegroundColor Red
                }
            }
        }
        "2" {
            if (-not (Start-IsolatedBrowser -BrowserType "edge")) {
                Write-Host "❌ 未在您的电脑上找到 Microsoft Edge 浏览器..." -ForegroundColor Red
            }
        }
        "3" {
            Write-Host "`n📡 SSH 隧道已成功运行在后台，全局防泄露变量已写入注册表。" -ForegroundColor Green
            Write-Host "🌟 安全防护已在 Windows 全局激活！新开的任何终端窗口、VS Code 终端或 CMD 都会自动进入代理保护中。"
            Write-Host "👉 您可以在任何新终端中直接运行 Claude Code (claude)、启动 Antigravity，或者运行 Codex！" -ForegroundColor Cyan
            Write-Host "👉 运行项目目录下的 restore_proxy_env.ps1 可一键关闭隧道并清空全局环境变量。`n"
            break
        }
        "4" {
            & (Join-Path $PSScriptRoot "restore_proxy_env.ps1")
            break
        }
        default {
            Write-Host "⚠️ 无效选项，请重新输入。" -ForegroundColor Yellow
        }
    }
}
