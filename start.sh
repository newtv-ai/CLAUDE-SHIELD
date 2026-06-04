#!/bin/bash

# ==========================================================
# 配置项：是否在当前终端前台运行并显示日志？
# 可直接用编辑器修改此行：
#   SHOW_WINDOW="true"   ->  (默认) 前台启动并打印日志 (Ctrl+C 关闭)
#   SHOW_WINDOW="false"  ->  后台隐藏运行 (再次运行本脚本即可关闭)
# ==========================================================
SHOW_WINDOW="true"

echo -e "\033[1;36m==========================================================\033[0m"
echo -e "\033[1;36m    Claude 账户封号风险评估系统一键启动器 (Unix)\033[0m"
echo -e "\033[1;36m==========================================================\033[0m"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/server.pid"
NODE_MODULES_DIR="$SCRIPT_DIR/node_modules"

# 1. 自动检测并安装依赖
if [ ! -d "$NODE_MODULES_DIR" ]; then
    echo -e "\033[33m⚠️ 检测到尚未安装前端依赖包，正在为您执行 'npm install'，请稍候...\033[0m"
    if ! command -v npm &> /dev/null; then
        echo -e "\033[31m❌ 启动失败：系统上未找到 Node.js (未检测到 npm 命令行)。\033[0m"
        echo "请先安装 Node.js 后再次启动本程序。"
        read -p "按回车键退出..."
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
    npm install
    if [ $? -ne 0 ]; then
        echo -e "\033[31m❌ 依赖安装失败，请手动在项目根目录下运行 'npm install' 进行排查。\033[0m"
        read -p "按回车键退出..."
        exit 1
    fi
    echo -e "\033[32m✅ 依赖组件库安装完成！\033[0m\n"
fi

# 2. Detect and close previous instances of this specific project
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if [ ! -z "$OLD_PID" ]; then
        echo -e "\033[33m正在检测上一次运行的旧进程 (PID: $OLD_PID)...\033[0m"
        if ps -p $OLD_PID > /dev/null 2>&1; then
            echo "发现旧进程正在运行，正在强制关闭其进程树..."
            pkill -P $OLD_PID >/dev/null 2>&1
            kill -9 $OLD_PID >/dev/null 2>&1
            echo -e "\033[32m✅ 旧进程已成功终止。\033[0m"
        else
            echo -e "\033[32m✅ 旧进程已不在运行状态。\033[0m"
        fi
    fi
    rm -f "$PID_FILE"
else
    echo -e "\033[32m✅ 未发现记录的旧进程 PID 文件。\033[0m"
fi
echo ""

# 3. Start the server according to configuration
if [ "$SHOW_WINDOW" = "true" ]; then
    echo -e "\033[36m🚀 正在前台启动开发服务器...\033[0m"
    echo -e "\033[90m--------------------------------------------------------\033[0m"
    echo -e "启动成功后，请在浏览器中打开: \033[32mhttp://localhost:5173/\033[0m (或 127.0.0.1:5173)"
    echo -e "如需停止服务，请直接按 Ctrl+C 关闭。"
    echo -e "\033[90m--------------------------------------------------------\033[0m"
    echo ""
    cd "$SCRIPT_DIR"
    npm run dev
else
    echo -e "\033[36m🚀 正在后台隐藏启动开发服务器...\033[0m"
    
    # Run in background via nohup and write the background task PID
    cd "$SCRIPT_DIR"
    nohup npm run dev > /dev/null 2>&1 &
    echo $! > "$PID_FILE"
    
    echo -e "\033[32m✅ 服务已成功在后台隐藏启动！\033[0m"
    echo -e "\033[90m--------------------------------------------------------\033[0m"
    echo -e "请在浏览器中打开此链接访问项目:"
    echo -e "👉 \033[32mhttp://localhost:5173/\033[0m (或 127.0.0.1:5173)"
    echo -e "\033[90m--------------------------------------------------------\033[0m"
    echo ""
    echo "[提示] 若后续要关闭此后台隐藏服务，只需再次运行此脚本即可。"
    echo "本启动窗口将在 3 秒后自动关闭..."
    sleep 3
fi
