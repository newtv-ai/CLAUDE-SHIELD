#!/bin/bash
# Claude Shield - 快捷启动脚本 (Linux/macOS 配合 V2ray/Clash 代理)
# 提示：若要在当前终端中直接使环境变量生效，请使用 source ./run_claude_via_v2ray.sh 运行此脚本。

echo -e "\033[1;36m==========================================================\033[0m"
echo -e "\033[1;36m    Claude Shield - 快捷启动工具 (Unix 桥接全局模式)\033[0m"
echo -e "\033[1;36m==========================================================\033[0m"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/vps_config.json"

local_port=10808
vps_tz="America/New_York"
has_config=false

if [ -f "$CONFIG_FILE" ]; then
    if command -v jq &> /dev/null; then
        local_port=$(jq -r '.v2ray_local_port // .local_port // 10808' "$CONFIG_FILE")
        vps_tz=$(jq -r '.vps_tz // "America/New_York"' "$CONFIG_FILE")
        has_config=true
    elif command -v node &> /dev/null; then
        local_port=$(node -e "try { const d = JSON.parse(require('fs').readFileSync('$CONFIG_FILE','utf8')); console.log(d.v2ray_local_port || d.local_port || 10808); } catch(e) { console.log(10808); }")
        vps_tz=$(node -e "try { const d = JSON.parse(require('fs').readFileSync('$CONFIG_FILE','utf8')); console.log(d.vps_tz || 'America/New_York'); } catch(e) { console.log('America/New_York'); }")
        has_config=true
    else
        # 简单正则提取兼容处理
        local_port=$(grep -o '"v2ray_local_port":[^,]*' "$CONFIG_FILE" | head -n1 | tr -cd '0-9')
        if [ -z "$local_port" ]; then
            local_port=$(grep -o '"local_port":[^,]*' "$CONFIG_FILE" | head -n1 | tr -cd '0-9')
        fi
        vps_tz=$(grep -o '"vps_tz":[^,]*' "$CONFIG_FILE" | head -n1 | cut -d'"' -f4)
        if [ -n "$local_port" ] && [ "$local_port" != "null" ]; then
            has_config=true
        fi
    fi
fi

if [ "$has_config" = false ] || [ "$local_port" = "null" ] || [ -z "$local_port" ]; then
    # 强制重设默认值，防止空值
    local_port=10808
    vps_tz="America/New_York"
    
    echo "[配置] 检测到是首次运行，请配置您的本地代理参数（配置将被保存无需下次重复输入）："
    echo -e "\033[33m💡 提示：新版 v2rayN (Mixed) 默认是 10808，Clash 默认是 7890；如果您是老版本 v2rayN 分立端口，HTTP 端口通常为 10809。\033[0m"
    read -p "👉 请输入本地 HTTP 代理端口 (默认 10808, 直接回车使用默认): " input_port
    local_port=${input_port:-$local_port}
    
    read -p "👉 请输入节点目标时区 (默认 America/New_York, 直接回车使用默认): " input_tz
    vps_tz=${input_tz:-$vps_tz}

    # 合并保存配置，不覆盖已有的 VPS IP 等其他属性 (优先使用 Node.js 或 Python)
    if command -v node &> /dev/null; then
        node -e "
        const fs = require('fs');
        const file = process.argv[1];
        let data = {};
        try { data = JSON.parse(fs.readFileSync(file, 'utf8')); } catch(e) {}
        data.v2ray_local_port = parseInt(process.argv[2]);
        data.vps_tz = process.argv[3];
        fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');
        " "$CONFIG_FILE" "$local_port" "$vps_tz"
    elif command -v python3 &> /dev/null; then
        python3 -c "
        import json, sys
        file = sys.argv[1]
        try:
            with open(file, 'r', encoding='utf-8') as f: data = json.load(f)
        except:
            data = {}
        data['v2ray_local_port'] = int(sys.argv[2])
        data['vps_tz'] = sys.argv[3]
        with open(file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        " "$CONFIG_FILE" "$local_port" "$vps_tz"
    else
        # 兜底直接覆盖写入
        cat <<EOF > "$CONFIG_FILE"
{
  "v2ray_local_port": $local_port,
  "vps_tz": "$vps_tz"
}
EOF
    fi
    echo -e "\033[32m✅ 配置已成功保存至 $CONFIG_FILE\033[0m\n"
else
    echo -e "💡 \033[32m自动加载已保存的本地配置：\033[0m"
    echo -e "   - 本地 HTTP 端口: $local_port (注：新版 v2rayN 混合/Clash 推荐 10808/7890，老版 v2rayN 推荐 10809)"
    echo -e "   - 锁定目标时区: $vps_tz"
    echo -e "   *(如需修改配置，请直接删除同目录下的 vps_config.json)*"
    echo ""
fi

PROXY_VAL="http://127.0.0.1:$local_port"

# 识别 Shell 配置文件
SHELL_RC=""
if [[ "$SHELL" == */zsh ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == */bash ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

# 写入全局环境变量
if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
    echo -e "\n# --- CLAUDE SHIELD START ---" >> "$SHELL_RC"
    echo "export HTTP_PROXY='$PROXY_VAL'" >> "$SHELL_RC"
    echo "export HTTPS_PROXY='$PROXY_VAL'" >> "$SHELL_RC"
    echo "export TZ='$vps_tz'" >> "$SHELL_RC"
    echo "export LANG='en_US.UTF-8'" >> "$SHELL_RC"
    echo "export LC_ALL='en_US.UTF-8'" >> "$SHELL_RC"
    echo "# --- CLAUDE SHIELD END ---" >> "$SHELL_RC"
    echo -e "🌐 已自动将环境变量写入您的 $SHELL_RC 配置文件中。"
fi

# 当前 Shell 会话也注入
export HTTP_PROXY="$PROXY_VAL"
export HTTPS_PROXY="$PROXY_VAL"
export TZ="$vps_tz"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

echo ""
echo -e "\033[32m==========================================================\033[0m"
echo -e "\033[32m ✅ 全局安全环境防护已成功激活！\033[0m"
echo -e " - 代理中继: $PROXY_VAL"
echo -e " - 锁定时区: $vps_tz"
echo ""
echo -e " 🌟 您新开的任何终端、Shell 窗口都会自动继承此代理防护。"
echo -e " 👉 请直接在任意新终端里运行您的工具："
echo -e "   - 启动 Claude Code: 直接输入 claude"
echo -e "   - 启动 Antigravity / Codex: 直接输入您的 Agent 启动命令"
echo -e "\033[32m==========================================================\033[0m"
echo ""
echo -e "\033[33m⚠️ [重要] 请保持本窗口挂在后台运行。\033[0m"
echo -e "\033[33m⚠️ 结束工作后，请在【下方窗口内按 Enter 键】，脚本会自动还原清理系统配置文件。\033[0m"
echo -e "----------------------------------------------------------"
echo ""

read -p "按下 [Enter] 键还原清理配置并退出..."

# 还原清理配置文件
if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/# --- CLAUDE SHIELD START ---/,/# --- CLAUDE SHIELD END ---/d' "$SHELL_RC"
    else
        sed -i '/# --- CLAUDE SHIELD START ---/,/# --- CLAUDE SHIELD END ---/d' "$SHELL_RC"
    fi
    echo -e "\033[32m🧹 已清理并还原您的 $SHELL_RC 配置文件。\033[0m"
fi

echo -e "\033[32m✅ 全局环境变量已成功还原，网络恢复直连。\033[0m"
sleep 2
