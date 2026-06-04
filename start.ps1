param (
    [string]$ShowWindow = "true"
)

# Set Output Encoding to UTF-8 to prevent garbled Chinese text in CMD
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=========================================================="
Write-Host "    Claude Shield Launcher (Windows)"
Write-Host "=========================================================="
Write-Host ""

$pidFile = "server.pid"

# 1. Detect and close previous instances of this specific project
if (Test-Path $pidFile) {
    $oldPid = Get-Content $pidFile -Raw
    if (![string]::IsNullOrWhiteSpace($oldPid)) {
        $oldPid = $oldPid.Trim()
        Write-Host "Checking for previous running server (PID: $oldPid)..."
        
        $proc = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "Old process detected. Stopping server process tree..."
            taskkill /F /T /PID $oldPid >$null 2>&1
            Write-Host "✅ Old server stopped successfully."
        } else {
            Write-Host "✅ Old server is not running."
        }
    }
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "✅ No active server records found."
}
Write-Host ""

# 2. Start the server according to configuration argument (Bypass read-host prompt)
if ($ShowWindow.ToLower() -eq "true") {
    Write-Host "🚀 Launching development server..."
    Write-Host "--------------------------------------------------------"
    Write-Host "Once ready, open: http://localhost:5173/ (or http://127.0.0.1:5173/)"
    Write-Host "(Port will automatically switch to 5174+ if occupied)"
    Write-Host "Close the popped-up window anytime to stop the server."
    Write-Host "--------------------------------------------------------"
    Write-Host ""
    
    # Launch in a new CMD window and save the window PID
    $p = Start-Process cmd -ArgumentList "/c title Claude Shield Server & npm run dev" -PassThru
    $p.Id | Out-File $pidFile -Encoding ascii
    
    Start-Sleep -Seconds 1
} else {
    Write-Host "🚀 Launching development server in background..."
    
    # Launch Vite in hidden background mode and log the PID
    $p = Start-Process cmd -ArgumentList "/c npm run dev" -WindowStyle Hidden -PassThru
    $p.Id | Out-File $pidFile -Encoding ascii
    
    Write-Host "✅ Server launched in the background successfully!"
    Write-Host "--------------------------------------------------------"
    Write-Host "Open this URL in your web browser:"
    Write-Host "👉 http://localhost:5173/ (or http://127.0.0.1:5173/)"
    Write-Host "--------------------------------------------------------"
    Write-Host ""
    Write-Host "[Info] To stop this background server, simply run this launcher script again."
    Write-Host ""
    Write-Host "This launcher window will auto-close in 3 seconds..."
    Start-Sleep -Seconds 3
}
