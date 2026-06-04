#!/bin/bash

# ==========================================================
# 配置项：是否在当前终端前台运行并显示日志？
# 可直接用编辑器修改此行：
#   SHOW_WINDOW="true"   ->  (默认) 前台启动并打印日志 (Ctrl+C 关闭)
#   SHOW_WINDOW="false"  ->  后台隐藏运行 (再次运行本脚本即可关闭)
# ==========================================================
SHOW_WINDOW="true"

echo "=========================================================="
echo "    Claude 账户封号风险评估系统一键启动器 (Linux)"
echo "=========================================================="
echo ""

PID_FILE="server.pid"

# 1. Detect and close previous instances of this specific project
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if [ ! -z "$OLD_PID" ]; then
        echo "正在检测上一次运行的旧进程 (PID: $OLD_PID)..."
        if ps -p $OLD_PID > /dev/null 2>&1; then
            echo "发现旧进程正在运行，正在强制关闭其进程树..."
            pkill -P $OLD_PID >/dev/null 2>&1
            kill -9 $OLD_PID >/dev/null 2>&1
            echo "✅ 旧进程已成功终止。"
        else
            echo "✅ 旧进程已不在运行状态。"
        fi
    fi
    rm -f "$PID_FILE"
else
    echo "✅ 未发现记录的旧进程 PID 文件。"
fi
echo ""

# 2. Start the server according to configuration
if [ "$SHOW_WINDOW" = "true" ]; then
    echo "🚀 正在前台启动开发服务器..."
    echo "--------------------------------------------------------"
    echo "启动成功后，请在浏览器中打开: http://localhost:5173/ (or 127.0.0.1:5173)"
    echo "如需停止服务，请直接按 Ctrl+C 关闭。"
    echo "--------------------------------------------------------"
    echo ""
    npm run dev
else
    echo "🚀 正在后台隐藏启动开发服务器..."
    
    # Run in background via nohup and write the background task PID
    nohup npm run dev > /dev/null 2>&1 &
    echo $! > "$PID_FILE"
    
    echo "✅ 服务已成功在后台隐藏启动！"
    echo "--------------------------------------------------------"
    echo "请在浏览器中打开此链接访问项目:"
    echo "👉 http://localhost:5173/ (or 127.0.0.1:5173)"
    echo "--------------------------------------------------------"
    echo ""
    echo "[提示] 若后续要关闭此后台隐藏服务，只需再次运行此脚本即可。"
    echo "本启动窗口将在 3 秒后自动关闭..."
    sleep 3
fi
