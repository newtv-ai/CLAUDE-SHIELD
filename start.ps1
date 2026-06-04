param (
    [string]$ShowWindow = "true"
)

# Set Output Encoding to UTF-8 to prevent garbled Chinese text in CMD
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "    Claude Shield Launcher (Windows)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$pidFile = Join-Path $PSScriptRoot "server.pid"
$nodeModulesPath = Join-Path $PSScriptRoot "node_modules"

# 1. 自动检测并安装依赖
if (!(Test-Path $nodeModulesPath)) {
    Write-Host "⚠️ 检测到尚未安装前端依赖包，正在自动为您执行 'npm install' 安装依赖..." -ForegroundColor Yellow
    $npmCheck = Get-Command npm -ErrorAction SilentlyContinue
    if (!$npmCheck) {
        Write-Host "❌ 启动失败：在您的系统上未找到 Node.js (未检测到 npm 命令行)。" -ForegroundColor Red
        Write-Host "请先前往 https://nodejs.org/ 下载并安装 Node.js，随后重新启动本程序。" -ForegroundColor Red
        Read-Host "按回车键退出..."
        exit
    }
    
    # 运行 npm install 并等待结束
    $installProc = Start-Process cmd -ArgumentList "/c cd /d `"$PSScriptRoot`" && npm install" -PassThru
    $installProc.WaitForExit()
    
    if ($installProc.ExitCode -ne 0) {
        Write-Host "❌ 依赖安装失败，请手动在此目录下运行 'npm install' 排查错误。" -ForegroundColor Red
        Read-Host "按回车键退出..."
        exit
    }
    Write-Host "✅ 依赖组件库安装完成！`n" -ForegroundColor Green
}

# 2. Detect and close previous instances of this specific project
if (Test-Path $pidFile) {
    $oldPid = Get-Content $pidFile -Raw
    if (![string]::IsNullOrWhiteSpace($oldPid)) {
        $oldPid = $oldPid.Trim()
        Write-Host "正在检测是否有运行中的旧诊断服务器 (PID: $oldPid)..." -ForegroundColor Yellow
        
        $proc = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "检测到已存在的旧服务进程。正在终止其进程树..." -ForegroundColor Yellow
            taskkill /F /T /PID $oldPid >$null 2>&1
            Write-Host "✅ 旧诊断服务器已成功关闭。" -ForegroundColor Green
        } else {
            Write-Host "✅ 无需关闭：旧服务器未处于运行状态。" -ForegroundColor Green
        }
    }
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "✅ 未检测到正在运行的活动诊断服务。" -ForegroundColor Green
}
Write-Host ""

# 3. Start the server according to configuration argument
if ($ShowWindow.ToLower() -eq "true") {
    Write-Host "🚀 正在启动本地开发服务器..." -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------" -ForegroundColor Gray
    Write-Host "服务启动就绪后，请在浏览器中打开网址：" -ForegroundColor Gray
    Write-Host "👉 http://localhost:5173/ (或 http://127.0.0.1:5173/)" -ForegroundColor Green
    Write-Host "(如果 5173 端口被占用，服务会自动顺延到 5174+ 端口)" -ForegroundColor Gray
    Write-Host "随时关闭弹出的黑窗口，即可停止诊断服务运行。" -ForegroundColor Gray
    Write-Host "--------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""
    
    # Launch in a new CMD window and save the window PID
    $p = Start-Process cmd -ArgumentList "/c cd /d `"$PSScriptRoot`" && title Claude Shield Server && npm run dev" -PassThru
    $p.Id | Out-File $pidFile -Encoding ascii
    
    Start-Sleep -Seconds 1
} else {
    Write-Host "🚀 正在后台隐藏启动本地开发服务器..." -ForegroundColor Cyan
    
    # Launch Vite in hidden background mode and log the PID
    $p = Start-Process cmd -ArgumentList "/c cd /d `"$PSScriptRoot`" && npm run dev" -WindowStyle Hidden -PassThru
    $p.Id | Out-File $pidFile -Encoding ascii
    
    Write-Host "✅ 诊断服务器已成功在后台静默运行！" -ForegroundColor Green
    Write-Host "--------------------------------------------------------" -ForegroundColor Gray
    Write-Host "请在您的浏览器中访问此地址进行网络指纹排查：" -ForegroundColor Gray
    Write-Host "👉 http://localhost:5173/ (或 http://127.0.0.1:5173/)" -ForegroundColor Green
    Write-Host "--------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[提示] 若要停止此后台服务器，只需再次双击运行本启动脚本即可。" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "本窗口将在 3 秒后自动关闭..." -ForegroundColor Gray
    Start-Sleep -Seconds 3
}
