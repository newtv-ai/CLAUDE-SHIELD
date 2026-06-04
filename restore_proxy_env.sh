#!/bin/bash
# Claude Shield VPS 代理与防泄露环境一键清理脚本 (Linux/macOS)

echo -e "\033[1;36m==========================================================\033[0m"
echo -e "\033[1;36m    Claude Shield - VPS 代理与防泄露一键清理工具 (Unix)\033[0m"
echo -e "\033[1;36m==========================================================\033[0m"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/ssh_tunnel.pid"

# 1. 关停后台运行的 SSH 代理进程
if [ -f "$PID_FILE" ]; then
    old_pid=$(cat "$PID_FILE")
    if [ -n "$old_pid" ]; then
        echo -e "🔄 正在检测 SSH 隧道进程 (PID: $old_pid)..."
        if kill -0 "$old_pid" 2>/dev/null; then
            echo -e "\033[33m🔄 正在终止 SSH 隧道后台进程...\033[0m"
            kill -9 "$old_pid" &>/dev/null
            echo -e "\033[32m✅ SSH 隧道已成功关闭。\033[0m"
        else
            echo -e "\033[32m✅ SSH 隧道已不处于运行状态。\033[0m"
        fi
    fi
    rm -f "$PID_FILE"
else
    echo -e "\033[90mℹ️ 未找到 active 的 SSH 隧道运行记录。\033[0m"
fi

# 2. 清除当前 Shell 会话的环境变量
unset HTTP_PROXY
unset HTTPS_PROXY
unset TZ
unset LANG
unset LC_ALL

echo -e "\033[32m🧹 当前 Shell 会话中的代理、时区与语言环境变量已清除。\033[0m"
echo -e "   - HTTP_PROXY = $HTTP_PROXY"
echo -e "   - HTTPS_PROXY = $HTTPS_PROXY"
echo -e "   - TZ = $TZ"
echo ""

# 3. 清理沙箱浏览器的临时 Profile
temp_profile="/tmp/claude-isolated-profile-$(whoami)"
if [ -d "$temp_profile" ]; then
    echo -e "\033[90m🧹 检测到隔离浏览器的临时沙盒目录...\033[0m"
    read -p "是否彻底删除防泄漏浏览器的临时缓存与登录 Cookie？(Y/N，默认为 N): " confirm
    confirm=${confirm:-N}
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\033[33m正在删除 $temp_profile...\033[0m"
        rm -rf "$temp_profile"
        echo -e "\033[32m✅ 隔离浏览器数据已彻底销毁，无任何残留。\033[0m"
    else
        echo -e "\033[90m保留隔离浏览器数据（下次启动可保持已登录状态）。\033[0m"
    fi
fi

echo ""
echo -e "\033[32m🎉 还原清理工作已全部完成！您的网络和环境变量已恢复到初始状态。\033[0m"
echo "3秒后窗口自动关闭..."
sleep 3
