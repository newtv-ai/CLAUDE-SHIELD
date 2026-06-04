# 🛡️ Claude Shield - Account Risk Assessment & Leak Detection System

<p align="center">
  <img src="static/favicon.png" alt="Claude Shield Logo" width="100" height="100" style="border-radius: 20px; box-shadow: 0 10px 20px rgba(0, 243, 255, 0.2);"/>
</p>

<p align="center">
  <strong>A lightweight, zero-dependency, pure client-side environment safety & proxy leak assessment tool for Claude accounts.</strong>
</p>

---

## 🌟 Recommended Open-Source Project

If you find **Claude Shield** helpful, please check out another beautiful open-source tool crafted by our team:
👉 **[Switchboard](https://github.com/newtv-ai/switchboard)** — A modern, high-performance intelligent relay and network gateway controller. Give it a Star if you like it!

---

## 📖 Introduction

In 2026, Anthropic's anti-fraud system drastically tightened restrictions. Not only does it verify the reputation of your egress proxy IP, but it also audits WebRTC leaks, DNS resolution paths, timezones, locale settings, and client TLS/JA4 signatures.

**Claude Shield** is a pure client-side environment audit tool designed to evaluate your system settings before logging into Claude or launching Claude Code (CLI). It helps identify critical proxy configurations that might leak your true location, lowering the chance of getting your Claude account suspended.

### 🔎 Core Audit Indicators

1. **IP Geolocation & Reputation**: Inspects proxy IP fraud scores, ISP attributes, and check whether your node is flagged as a datacenter/proxy hosting service.
2. **DNS Leak Testing**: Resolves a unique client-side testing subdomain to detect whether local DNS servers (e.g., from domestic ISPs) are intercepting queries, revealing your physical geolocation.
3. **WebRTC Egress Audit**: Scans browser ICE candidates to ensure the browser does not bypass the proxy, exposing your physical network adapters.
4. **Timezone & Locale Alignment**: Compares your OS system timezone and browser language with your proxy egress IP location (e.g., warns if you use a US IP but keep Asia/Shanghai timezone).
5. **TLS Fingerprint & JA4 Assessment**: Captures and validates client JA4 signatures, identifying spoofing patterns or header inconsistencies.

---

## 🚀 Two Options for Anti-Ban Proxy Setup

This project provides two environment configuration methods designed to **protect Claude Code** in a safe and fast manner:

> [!IMPORTANT]
> **📢 Prerequisite for Using the Scripts**
> All anti-ban scripts and configuration settings provided in this project can only helper you if: **Your VPS IP / proxy node itself is clean and has NOT been flagged or blacklisted by Anthropic.**
> If your node has a healthy IP reputation, but your account faces risks due to your local computer's "Asia/Shanghai timezone", "Chinese language environment" or "WebRTC IP leaks", these scripts will perfectly align your environment settings and minimize the ban risk. If the node IP itself is already blacklisted, local client-side configurations will not help.

---

### 🔑 Option A: SSH Secure Tunneling Mode (One-Click Setup)
**Best for**: Developers who do not wish to run third-party GUI proxy clients during development, or prefer a lightweight, native SSH proxy connection using VPS IP.

#### 💻 VPS Server Requirements (Virtually Zero)
* **No Proxy Server Installation Required**: You do **NOT** need to install any proxy servers (like Clash, v2ray, or Shadowsocks) on your VPS. The script leverages SSH's native dynamic port forwarding. As long as your VPS is reachable via ordinary SSH, it works out of the box.
* **Rare Troubleshooting**: If SSH connects successfully but the SOCKS5 proxy tunnel fails to bind, check the SSH configuration file `/etc/ssh/sshd_config` on your VPS and ensure that `AllowTcpForwarding` is set to `yes` (which is the system default):
  ```text
  AllowTcpForwarding yes
  ```
  If modified, restart the SSH service (e.g., `systemctl restart sshd`).

#### 📋 Instructions (Windows Environment)
1. Double-click to launch **`setup_proxy_env.bat`**. Enter your VPS credentials on the first run.
2. The script runs a minimized SSH SOCKS5 tunnel in the background and writes env variables into user registries.
3. **Global Automatic Activation**: Once configured, any **new** terminal window, CMD, or VS Code terminal will automatically inherit the safe environment. You do not need to make any menu choices; directly run `claude` (Claude Code) in these terminals.
4. Double-click **`restore_proxy_env.bat`** after work to close the SSH tunnel and clean registries.

#### 📋 Instructions (Linux / macOS Environment)
* Run the command `source ./setup_proxy_env.sh` (using `source` ensures that the environment variables inject into the active Shell). You can then run Claude Code (`claude`) inside this terminal session.
* Run `bash ./restore_proxy_env.sh` to close the tunnel and clean up.

---

### 📡 Option B: Bridging Existing Local Proxy Clients (Shortcut Launcher)
**Best for**: Developers who already run clients like **v2rayN, Clash, or Shadowsocks** on their computer. This mode **bypasses the SSH tunnel setup and requires no VPS password entry**, directly bridging your active proxy configuration.

#### 💡 Core Safety Principle
Running `claude` directly while keeping a proxy app open often leaks **local DNS requests** (revealing domestic Geolocation) or triggers **timezone mismatch** flags.
This solution forces the terminal proxy protocol to **`socks5h://`**, commanding local command line runners to package DNS lookups through your local client, which resolves domains remotely on your overseas VPS, completely eliminating DNS leaks.

#### 📋 Instructions (Windows / Unix Environment)
1. Ensure your local proxy client (e.g., v2rayN) is running.
2. Find the **SOCKS5 local port** your client listens to:
   * **v2rayN Users**: Check the bottom status bar. It shows something like `SOCKS5 127.0.0.1:10808`, where `10808` is the port.
   * **Clash Users**: Check `Socks Port` in the General panel (default is usually `7890`).
3. Run the launcher script:
   * **Windows**: Double-click **`run_claude_via_v2ray.bat`**.
   * **Linux / macOS**: Run `source ./run_claude_via_v2ray.sh` or `./run_claude_via_v2ray.sh`.
4. Input the SOCKS5 port (press enter to use v2rayN's default `10808`), and confirm your IANA timezone (default `America/New_York`).
5. **No Menus & Interactive Shell**: The script automatically injects variables and configures the active terminal. Instead of choosing a single tool or auto-closing, **it drops you directly into a persistent interactive shell (Protected Sandbox Terminal)**.
6. You can directly type and run Claude Code inside this terminal:
   * Launch Claude Code: type `claude`
