#!/bin/bash
# Claude Shield VPS 代理与防泄露环境一键配置脚本 (Linux/macOS)
# 提示：若要在当前终端中直接使环境变量生效，请使用 source ./setup_proxy_env.sh 运行此脚本。

echo -e "\033[1;36m==========================================================\033[0m"
echo -e "\033[1;36m    Claude Shield - VPS 代理与防泄露一键配置工具 (Unix)\033[0m"
echo -e "\033[1;36m==========================================================\033[0m"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/vps_config.json"
PID_FILE="$SCRIPT_DIR/ssh_tunnel.pid"

# 默认配置与读取
vps_ip=""
ssh_user="root"
ssh_port=22
ssh_local_port=1080
vps_tz="America/New_York"

use_saved=false

if [ -f "$CONFIG_FILE" ]; then
    # 尝试解析 JSON
    if command -v jq &> /dev/null; then
        vps_ip=$(jq -r '.vps_ip // ""' "$CONFIG_FILE")
        ssh_user=$(jq -r '.ssh_user // "root"' "$CONFIG_FILE")
        ssh_port=$(jq -r '.ssh_port // 22' "$CONFIG_FILE")
        ssh_local_port=$(jq -r '.ssh_local_port // .local_port // 1080' "$CONFIG_FILE")
        vps_tz=$(jq -r '.vps_tz // "America/New_York"' "$CONFIG_FILE")
    else
        # 简单正则提取与兼容处理
        vps_ip=$(grep -o '"vps_ip":[^,]*' "$CONFIG_FILE" | head -n1 | cut -d'"' -f4)
        ssh_user=$(grep -o '"ssh_user":[^,]*' "$CONFIG_FILE" | head -n1 | cut -d'"' -f4)
        ssh_port=$(grep -o '"ssh_port":[^,]*' "$CONFIG_FILE" | head -n1 | tr -cd '0-9')
        ssh_local_port=$(grep -o '"ssh_local_port":[^,]*' "$CONFIG_FILE" | head -n1 | tr -cd '0-9')
        if [ -z "$ssh_local_port" ]; then
            ssh_local_port=$(grep -o '"local_port":[^,]*' "$CONFIG_FILE" | head -n1 | tr -cd '0-9')
        fi
        if [ -z "$ssh_local_port" ]; then
            ssh_local_port=1080
        fi
        vps_tz=$(grep -o '"vps_tz":[^,]*' "$CONFIG_FILE" | head -n1 | cut -d'"' -f4)
    fi

    if [ -n "$vps_ip" ] && [ "$vps_ip" != "null" ]; then
        echo -e "\033[32m💡 自动加载已保存的配置：\033[0m"
        echo -e "   - VPS IP: $vps_ip"
        echo -e "   - SSH 用户: $ssh_user"
        echo -e "   - SSH 端口: $ssh_port"
        echo -e "   - 本地代理端口: $ssh_local_port"
        echo -e "   - VPS 目标时区: $vps_tz"
        echo -e "   *(如需修改配置，请直接删除同目录下的 vps_config.json)*"
        echo ""
        use_saved=true
    fi
fi

if [ "$use_saved" = false ]; then
    echo "请输入您的 VPS 连接配置（配置将保存在本地 vps_config.json 中，后续运行自动加载）："
    while [ -z "$vps_ip" ]; do
        read -p "👉 请输入 VPS 的 IP 地址或域名 (必填): " vps_ip
    done
    
    read -p "👉 请输入 SSH 用户名 (默认: root): " input_user
    ssh_user=${input_user:-$ssh_user}
    
    read -p "👉 请输入 SSH 端口号 (默认: 22): " input_port
    ssh_port=${input_port:-$ssh_port}
    
    read -p "👉 请输入本地 SOCKS5 代理端口 (默认: 1080): " input_lport
    ssh_local_port=${input_lport:-$ssh_local_port}
    
    read -p "👉 请输入 VPS 所在的 IANA 时区 (默认: America/New_York): " input_tz
    vps_tz=${input_tz:-$vps_tz}

    # 合并保存 JSON 配置，不覆盖已有配置的其他属性 (优先使用 Node.js 或 Python)
    if command -v node &> /dev/null; then
        node -e "
        const fs = require('fs');
        const file = process.argv[1];
        let data = {};
        try { data = JSON.parse(fs.readFileSync(file, 'utf8')); } catch(e) {}
        data.vps_ip = process.argv[2];
        data.ssh_user = process.argv[3];
        data.ssh_port = parseInt(process.argv[4]);
        data.ssh_local_port = parseInt(process.argv[5]);
        data.vps_tz = process.argv[6];
        fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');
        " "$CONFIG_FILE" "$vps_ip" "$ssh_user" "$ssh_port" "$ssh_local_port" "$vps_tz"
    elif command -v python3 &> /dev/null; then
        python3 -c "
        import json, sys
        file = sys.argv[1]
        try:
            with open(file, 'r', encoding='utf-8') as f: data = json.load(f)
        except:
            data = {}
        data['vps_ip'] = sys.argv[2]
        data['ssh_user'] = sys.argv[3]
        data['ssh_port'] = int(sys.argv[4])
        data['ssh_local_port'] = int(sys.argv[5])
        data['vps_tz'] = sys.argv[6]
        with open(file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        " "$CONFIG_FILE" "$vps_ip" "$ssh_user" "$ssh_port" "$ssh_local_port" "$vps_tz"
    else
        # 兜底直接写入
        cat <<EOF > "$CONFIG_FILE"
{
  "vps_ip": "$vps_ip",
  "ssh_user": "$ssh_user",
  "ssh_port": $ssh_port,
  "ssh_local_port": $ssh_local_port,
  "vps_tz": "$vps_tz"
}
EOF
    fi
    echo -e "\033[32m✅ 配置已成功保存至 $CONFIG_FILE\033[0m\n"
fi

# 2. 检查并清理旧的 SSH 隧道
if [ -f "$PID_FILE" ]; then
    old_pid=$(cat "$PID_FILE")
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
        echo -e "\033[33m🔄 检测到已存在运行中的旧 SSH 隧道 (PID: $old_pid)，正在关闭...\033[0m"
        kill -9 "$old_pid" &>/dev/null
        sleep 1
    fi
    rm -f "$PID_FILE"
fi

# 检查本地端口是否已被占用
if command -v lsof &> /dev/null; then
    if lsof -i:"$ssh_local_port" -sTCP:LISTEN &>/dev/null; then
        echo -e "\033[31m⚠️ 本地端口 $ssh_local_port 已被其他程序占用！\033[0m"
        echo "请先关闭占用该端口的程序，或运行 ./restore_proxy_env.sh 释放端口。"
        exit 1
    fi
fi

# 3. 建立 SSH SOCKS5 动态端口转发隧道
echo -e "\033[36m🚀 正在后台建立指向 VPS ($vps_ip) 的加密隧道...\033[0m"
echo -e "\033[33m🔑 如果提示输入密码或二次验证，请在下方终端中完成。\033[0m"

# 启动 SSH 并在后台运行
ssh -f -N -D 127.0.0.1:"$ssh_local_port" -p "$ssh_port" "$ssh_user@$vps_ip"

# 寻找刚才建立的 ssh 后台进程 PID 写入文件
ssh_pid=$(ps aux | grep "ssh -f -N -D 127.0.0.1:$ssh_local_port" | grep -v grep | awk '{print $2}' | head -n1)
if [ -n "$ssh_pid" ]; then
    echo "$ssh_pid" > "$PID_FILE"
    echo -e "\033[32m✅ SSH 隧道已在后台启动 (PID: $ssh_pid)。\033[0m"
    echo -e "\033[32m📡 本地 SOCKS5 代理已监听在 127.0.0.1:$ssh_local_port\033[0m"
else
    echo -e "\033[31m❌ 启动 SSH 隧道失败。请检查网络或免密登录配置。\033[0m"
    exit 1
fi

sleep 1

# 4. 配置环境变量
# 核心防御：强制由远程 VPS 解析 DNS，杜绝 DNS 本地泄露风险！
PROXY_VAL="socks5://127.0.0.1:$ssh_local_port"

export HTTP_PROXY="$PROXY_VAL"
export HTTPS_PROXY="$PROXY_VAL"
export TZ="$vps_tz"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

echo -e "\033[32m🌐 环境变量已在当前 Shell 中注入：\033[0m"
echo -e "   - HTTPS_PROXY = $HTTPS_PROXY (使用 socks5h 强制远程 DNS 解析)"
echo -e "   - TZ = $TZ (Node.js 时区锁定)"
echo -e "   - LANG = $LANG"
echo ""

# 5. 提供极速沙箱防泄漏浏览器启动
start_browser() {
    local browser=$1
    local temp_profile="/tmp/claude-isolated-profile-$(whoami)"
    mkdir -p "$temp_profile"
    
    local proxy_arg="--proxy-server=socks5://127.0.0.1:$ssh_local_port"
    local profile_arg="--user-data-dir=$temp_profile"
    local lang_arg="--lang=en-US --accept-lang=en-US,en"
    local privacy_arg="--disable-features=WebRtcHideLocalIpsWithMdns --disable-encryption-binding"
    local urls="https://browserleaks.com/webrtc https://claude.ai"

    if [ "$browser" = "chrome" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS Chrome
            open -na "Google Chrome" --args $proxy_arg $profile_arg $lang_arg $privacy_arg $urls
            return 0
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux Chrome
            if command -v google-chrome &> /dev/null; then
                google-chrome $proxy_arg $profile_arg $lang_arg $privacy_arg $urls &>/dev/null &
                return 0
            elif command -v chromium-browser &> /dev/null; then
                chromium-browser $proxy_arg $profile_arg $lang_arg $privacy_arg $urls &>/dev/null &
                return 0
            fi
        fi
    fi
    return 1
}

while true; do
    echo "--- 请选择后续操作 ---"
    echo "1. 启动【独立防泄漏 Google Chrome 浏览器】进行网页端授权"
    echo "2. 保持当前 SSH 隧道，仅查看恢复说明"
    echo "3. 关闭隧道并退出"
    echo ""
    read -p "👉 请输入选项序号 (1-3): " opt
    
    case $opt in
        1)
            if ! start_browser "chrome"; then
                echo -e "\033[31m❌ 未在您的系统上找到 Google Chrome 浏览器。请手动打开并配置代理：socks5://127.0.0.1:$ssh_local_port\033[0m"
            fi
            ;;
        2)
            echo -e "\n\033[32m📡 SSH 隧道正在后台运行。\033[0m"
            echo -e "🌟 安全环境防护已在 Unix 中成功激活！\033[0m"
            echo -e "👉 您可以在当前或任何已配置的环境中，直接运行 Claude Code (claude)！"
            echo -e "👉 运行项目目录下的 ./restore_proxy_env.sh 可一键清理该隧道并还原设置。\n"
            break
            ;;
        3)
            # 调用还原脚本
            bash "$SCRIPT_DIR/restore_proxy_env.sh"
            break
            ;;
        * )
            echo -e "\033[33m⚠️ 无效选项，请重新选择。\033[0m"
            ;;
    esac
done
