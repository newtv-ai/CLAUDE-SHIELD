<script lang="ts">
  // Svelte 5 syntax
  let { report = null, webrtcIps = [] } = $props<{
    report: any | null;
    webrtcIps: string[];
  }>();

  // Helper to format true/false into status text
  function getStatusText(success: boolean) {
    return success ? "对齐/安全" : "异常/冲突";
  }
</script>

<div class="details-grid">
  <!-- Panel 1: IP Geolocation & Reputation -->
  <div class="card-panel">
    <div class="panel-header">
      <svg class="panel-icon" viewBox="0 0 24 24" fill="none" stroke="#00f3ff" stroke-width="2">
        <circle cx="12" cy="12" r="10"/>
        <path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/>
        <path d="M2 12h20"/>
      </svg>
      <h3>IP信誉与托管画像</h3>
    </div>
    
    <div class="panel-content">
      {#if report && report.ip_info}
        <div class="data-row">
          <span class="label">出口公网 IP:</span>
          <span class="value font-mono highlight">{report.ip_info.query || "未知"}</span>
        </div>
        <div class="data-row">
          <span class="label">地理位置:</span>
          <span class="value">{report.ip_info.country || "未知"} ({report.ip_info.countryCode || ""})</span>
        </div>
        <div class="data-row">
          <span class="label">互联网运营商:</span>
          <span class="value text-truncate">{report.ip_info.isp || "未知"}</span>
        </div>
        <div class="data-row">
          <span class="label">出口连接类型:</span>
          <span class="value capitalize font-bold" class:warn={report.ipqs_info?.connection_type.includes("datacenter")}>
            {report.ipqs_info?.connection_type || "未知"}
          </span>
        </div>
        {#if report.region_policy}
          <div class="data-row">
            <span class="label">Claude 支持地区:</span>
            <span class="value font-bold" class:safe={report.region_policy.supported_region} class:danger={!report.region_policy.supported_region}>
              {report.region_policy.supported_region ? "支持" : "不支持"} ({report.region_policy.country_code})
            </span>
          </div>
        {/if}
        
        {#if report.ipqs_info}
          <div class="fraud-section">
            <div class="fraud-header">
              <span class="label">IPQS 欺诈风险值:</span>
              <span class="fraud-score-val" class:high={report.ipqs_info.fraud_score > 50} class:med={report.ipqs_info.fraud_score >= 15 && report.ipqs_info.fraud_score <= 50}>
                {report.ipqs_info.fraud_score} / 100
              </span>
            </div>
            <div class="progress-bar-bg">
              <div class="progress-bar" style="width: {report.ipqs_info.fraud_score}%; background: {report.ipqs_info.fraud_score > 50 ? '#ff0055' : report.ipqs_info.fraud_score >= 15 ? '#ffaa00' : '#00f3ff'}"></div>
            </div>
          </div>
          <div class="badge-row">
            <span class="status-badge" class:danger={report.ipqs_info.active_vpn}>VPN: {report.ipqs_info.active_vpn ? "检测到" : "无"}</span>
            <span class="status-badge" class:danger={report.ipqs_info.active_tor}>TOR: {report.ipqs_info.active_tor ? "检测到" : "无"}</span>
            <span class="status-badge" class:danger={report.ipqs_info.abuse_velocity !== 'none'}>滥用速度: {report.ipqs_info.abuse_velocity}</span>
          </div>
        {/if}
        {#if report.region_policy}
          <p class="leak-description text-sm">{report.region_policy.flags[0]}</p>
        {/if}
      {:else}
        <div class="skeleton-loader">
          <div class="sk-line"></div>
          <div class="sk-line"></div>
          <div class="sk-line"></div>
          <div class="sk-bar"></div>
        </div>
      {/if}
    </div>
  </div>

  <!-- Panel 2: DNS & WebRTC Leaks -->
  <div class="card-panel">
    <div class="panel-header">
      <svg class="panel-icon" viewBox="0 0 24 24" fill="none" stroke="#ff0055" stroke-width="2">
        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
        <line x1="12" y1="9" x2="12" y2="13"/>
        <line x1="12" y1="17" x2="12.01" y2="17"/>
      </svg>
      <h3>隐私与数据泄露测试</h3>
    </div>
    
    <div class="panel-content">
      {#if report && report.dns_leak}
        <!-- DNS Leak Result -->
        <div class="sub-section">
          <div class="sub-header">
            <span class="sub-title">DNS 泄露状态:</span>
            <span class="status-indicator" class:safe={!report.dns_leak.dns_leak_detected} class:danger={report.dns_leak.dns_leak_detected}>
              {report.dns_leak.dns_leak_detected ? "检测到泄露" : "安全无泄露"}
            </span>
          </div>
          <p class="leak-description text-sm">{report.dns_leak.leak_details}</p>
          {#if report.dns_leak.dns_servers.length > 0}
            <div class="dns-server-list scrollbar font-mono text-xs">
              {#each report.dns_leak.dns_servers as server}
                <div class="dns-item">• {server}</div>
              {/each}
            </div>
          {/if}
        </div>

        <!-- WebRTC Leak Result -->
        <div class="sub-section" style="margin-top: 10px;">
          <div class="sub-header">
            <span class="sub-title">WebRTC 穿透暴露:</span>
            <span class="status-indicator" class:safe={webrtcIps.length === 0} class:warn={webrtcIps.length > 0}>
              {webrtcIps.length > 0 ? `暴露 ${webrtcIps.length} 个物理网卡` : "完全屏蔽"}
            </span>
          </div>
          {#if webrtcIps.length > 0}
            <div class="webrtc-list font-mono text-xs">
              {#each webrtcIps as ip}
                <div class="webrtc-item" class:dangerous-ip={!ip.startsWith('192.168.') && !ip.startsWith('10.') && !ip.startsWith('172.') && !ip.startsWith('127.') && ip !== report?.ip_info?.query}>
                  • {ip} 
                  {#if ip === report?.ip_info?.query}
                    <span class="int-tag safe">代理出口(安全未泄露)</span>
                  {:else if !ip.startsWith('192.168.') && !ip.startsWith('10.') && !ip.startsWith('172.') && !ip.startsWith('127.')}
                    <span class="leak-tag">真实物理IP(严重泄露)</span>
                  {:else}
                    <span class="int-tag">局域网内网IP</span>
                  {/if}
                </div>
              {/each}
            </div>
          {:else}
            <p class="leak-description text-sm">浏览器 WebRTC ICE 候选人已被成功拦截，无内网或真实公网物理 IP 泄露轨迹。</p>
          {/if}
        </div>
      {:else}
        <div class="skeleton-loader">
          <div class="sk-line"></div>
          <div class="sk-line-short"></div>
          <div class="sk-block"></div>
        </div>
      {/if}
    </div>
  </div>

  <!-- Panel 3: Local Environment Consistency -->
  <div class="card-panel">
    <div class="panel-header">
      <svg class="panel-icon" viewBox="0 0 24 24" fill="none" stroke="#ffaa00" stroke-width="2">
        <circle cx="12" cy="12" r="10"/>
        <polyline points="12 6 12 12 16 14"/>
      </svg>
      <h3>系统指纹环境一致性</h3>
    </div>
    
    <div class="panel-content">
      {#if report && report.consistency}
        <div class="consistency-item">
          <div class="cons-header">
            <span>本地系统时区 vs 出口IP时区</span>
            <span class="match-indicator" class:match={report.consistency.timezone_match}>
              {getStatusText(report.consistency.timezone_match)}
            </span>
          </div>
          <div class="cons-body font-mono text-xs">
            <div>系统本地时区: <span class="highlight">{report.consistency.system_timezone}</span></div>
            <div>出口节点时区: <span class="highlight">{report.ip_info?.timezone || "获取失败"}</span></div>
          </div>
          {#if !report.consistency.timezone_match}
            <p class="fix-tip">⚠️ 警告：当前系统时区与IP出口属地严重冲突。这在 Claude 的反欺诈模型中是极高风险特征。请在登录前将系统时区调整为代理节点所在时区。</p>
          {/if}
        </div>

        <div class="consistency-item" style="margin-top: 10px;">
          <div class="cons-header">
            <span>系统语言环境 vs 出口IP属地</span>
            <span class="match-indicator" class:match={report.consistency.language_match}>
              {getStatusText(report.consistency.language_match)}
            </span>
          </div>
          <div class="cons-body font-mono text-xs">
            <div>本地首选语言: <span class="highlight">{report.consistency.system_language}</span></div>
            <div>出口国家代码: <span class="highlight">{report.ip_info?.countryCode || "未知"}</span></div>
          </div>
          {#if !report.consistency.language_match}
            <p class="fix-tip">⚠️ 提示：本地系统语言主要为中文，而代理节点出口在美国或其他英语国家，容易被风控标记为异常环境。建议设置英文为浏览器首选语言。</p>
          {/if}
        </div>
      {:else}
        <div class="skeleton-loader">
          <div class="sk-line"></div>
          <div class="sk-block"></div>
          <div class="sk-line"></div>
        </div>
      {/if}
    </div>
  </div>

  <!-- Panel 4: TLS (JA4) Fingerprint Audit -->
  <div class="card-panel">
    <div class="panel-header">
      <svg class="panel-icon" viewBox="0 0 24 24" fill="none" stroke="#00f3ff" stroke-width="2">
        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
        <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
      </svg>
      <h3>TLS 与浏览器完整性</h3>
    </div>
    
    <div class="panel-content">
      {#if report && report.tls_fingerprint}
        <div class="ja4-section">
          <span class="label">捕获的 JA4 客户端指纹:</span>
          <div class="ja4-box font-mono select-all">
            {report.tls_fingerprint.ja4_fingerprint}
          </div>
        </div>
        
        <div class="data-row" style="margin-top: 10px;">
          <span class="label">仿真对齐判定:</span>
          <span class="value font-bold" class:safe={report.tls_fingerprint.ja4_match} class:danger={!report.tls_fingerprint.ja4_match}>
            {report.tls_fingerprint.ja4_match ? "安全：高仿真度浏览器特征" : "警告：检测到机器人/非标准指纹"}
          </span>
        </div>

        <div class="fraud-section" style="margin-top: 8px;">
          <div class="fraud-header">
            <span class="label">指纹拟合匹配度:</span>
            <span class="fraud-score-val" class:high={report.tls_fingerprint.match_score < 50}>
              {report.tls_fingerprint.match_score}%
            </span>
          </div>
          <div class="progress-bar-bg">
            <div class="progress-bar" style="width: {report.tls_fingerprint.match_score}%; background: {report.tls_fingerprint.match_score < 50 ? '#ff0055' : '#00f3ff'}"></div>
          </div>
        </div>

        {#if !report.tls_fingerprint.ja4_match}
          <div class="bot-warning border border-red-800 rounded">
            <strong>机器人指纹警报：</strong>
            当前请求的 TLS 握手协商细节（如密码套件顺序、ALPN配置）与声明的浏览器 User-Agent 不一致（例如直接暴露了底层 HTTP 库如 Rust reqwest 或 Python requests 的静态 TLS 指纹）。这会导致 Cloudflare Bot Management 触发秒封！
          </div>
        {/if}

        {#if report.browser_integrity}
          <div class="sub-section browser-integrity">
            <div class="sub-header">
              <span class="sub-title">浏览器自动化与会话能力:</span>
              <span class="status-indicator" class:safe={report.browser_integrity.risk_score === 0} class:danger={report.browser_integrity.risk_score >= 70} class:warn={report.browser_integrity.risk_score > 0 && report.browser_integrity.risk_score < 70}>
                {report.browser_integrity.risk_score === 0 ? "正常" : "异常信号"}
              </span>
            </div>
            <div class="badge-row">
              <span class="status-badge" class:danger={report.browser_integrity.webdriver}>webdriver: {report.browser_integrity.webdriver ? "暴露" : "无"}</span>
              <span class="status-badge" class:danger={report.browser_integrity.is_headless}>Headless: {report.browser_integrity.is_headless ? "是" : "否"}</span>
              <span class="status-badge" class:danger={!report.browser_integrity.cookie_enabled}>Cookie: {report.browser_integrity.cookie_enabled ? "可用" : "禁用"}</span>
              <span class="status-badge" class:danger={!report.browser_integrity.storage_available}>Storage: {report.browser_integrity.storage_available ? "可用" : "异常"}</span>
            </div>
            <div class="cons-body font-mono text-xs browser-meta">
              <div>平台: <span class="highlight">{report.browser_integrity.platform}</span> / CH: <span class="highlight">{report.browser_integrity.user_agent_platform}</span></div>
              <div>语言: <span class="highlight">{report.browser_integrity.languages.join(", ") || "未知"}</span></div>
              <div>插件数: <span class="highlight">{report.browser_integrity.plugins_count}</span> / 屏幕: <span class="highlight">{report.browser_integrity.screen}</span></div>
            </div>
            {#each report.browser_integrity.issues as issue}
              <p class="fix-tip">{issue}</p>
            {/each}
          </div>
        {/if}
      {:else}
        <div class="skeleton-loader">
          <div class="sk-line"></div>
          <div class="sk-line"></div>
          <div class="sk-block"></div>
        </div>
      {/if}
    </div>
  </div>
</div>

<style>
  .details-grid {
    display: grid;
    grid-template-columns: 1fr;
    gap: 16px;
    width: 100%;
    margin-top: 0;
    box-sizing: border-box;
    align-items: stretch;
  }

  @media (min-width: 1024px) {
    .details-grid {
      grid-template-columns: repeat(2, 1fr);
    }
  }

  .card-panel {
    background: var(--card-bg);
    border: 1px solid var(--card-border);
    backdrop-filter: blur(12px);
    border-radius: 14px;
    padding: 16px;
    box-shadow: 0 8px 22px var(--shadow-color);
    display: flex;
    flex-direction: column;
    box-sizing: border-box;
    transition: background 0.4s ease, border-color 0.4s ease, box-shadow 0.4s ease;
  }

  .panel-header {
    display: flex;
    align-items: center;
    gap: 9px;
    margin-bottom: 12px;
    border-bottom: 1px solid var(--card-border);
    padding-bottom: 9px;
  }

  .panel-icon {
    width: 21px;
    height: 21px;
  }

  .panel-header h3 {
    margin: 0;
    font-size: 14px;
    font-weight: 700;
    color: var(--text-primary);
    letter-spacing: 0.5px;
    transition: color 0.4s ease;
  }

  .panel-content {
    flex-grow: 1;
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
  }

  .data-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 7px;
    font-size: 12px;
  }

  .label {
    color: var(--text-secondary);
    transition: color 0.4s ease;
  }

  .value {
    color: var(--text-primary);
    transition: color 0.4s ease;
  }

  .highlight {
    color: var(--color-accent);
  }

  .font-mono {
    font-family: 'Fira Code', 'Courier New', Courier, monospace;
  }

  .text-truncate {
    max-width: 180px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    text-align: right;
  }

  .warn {
    color: var(--color-warning);
  }

  .safe {
    color: var(--color-accent);
  }

  .danger {
    color: var(--color-danger);
  }

  .font-bold {
    font-weight: 700;
  }

  .capitalize {
    text-transform: capitalize;
  }

  .fraud-section {
    margin-top: 8px;
    margin-bottom: 8px;
  }

  .fraud-header {
    display: flex;
    justify-content: space-between;
    font-size: 12px;
    margin-bottom: 5px;
  }

  .fraud-score-val {
    font-weight: 700;
    color: var(--color-accent);
  }

  .fraud-score-val.high {
    color: var(--color-danger);
  }

  .fraud-score-val.med {
    color: var(--color-warning);
  }

  .progress-bar-bg {
    width: 100%;
    height: 6px;
    background: var(--card-border);
    border-radius: 3px;
    overflow: hidden;
  }

  .progress-bar {
    height: 100%;
    border-radius: 3px;
    transition: width 1s ease;
  }

  .badge-row {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    margin-top: 5px;
  }

  .status-badge {
    font-size: 10px;
    padding: 3px 7px;
    border-radius: 4px;
    background: var(--box-bg);
    border: 1px solid var(--card-border);
    color: var(--text-secondary);
    transition: all 0.4s ease;
  }

  .status-badge.danger {
    background: rgba(255, 0, 85, 0.1);
    border-color: rgba(255, 0, 85, 0.3);
    color: var(--color-danger);
  }

  .sub-section {
    border-left: 2px solid var(--card-border);
    padding-left: 9px;
    transition: border-color 0.4s ease;
  }

  .sub-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 6px;
  }

  .sub-title {
    font-size: 11px;
    font-weight: 700;
    color: var(--text-primary);
    transition: color 0.4s ease;
  }

  .status-indicator {
    font-size: 10px;
    font-weight: 700;
    padding: 2px 6px;
    border-radius: 4px;
  }

  .status-indicator.safe {
    background: rgba(0, 243, 255, 0.15);
    color: var(--color-accent);
  }

  .status-indicator.danger {
    background: rgba(255, 0, 85, 0.15);
    color: var(--color-danger);
  }

  .status-indicator.warn {
    background: rgba(255, 170, 0, 0.15);
    color: var(--color-warning);
  }

  .leak-description {
    color: var(--text-muted);
    margin-top: 4px;
    margin-bottom: 5px;
    line-height: 1.32;
  }

  .dns-server-list {
    background: rgba(0, 0, 0, 0.2);
    border: 1px solid var(--card-border);
    border-radius: 8px;
    padding: 6px 10px;
    max-height: 72px;
    overflow-y: auto;
  }

  .dns-item {
    padding: 2px 0;
    color: var(--text-secondary);
  }

  .webrtc-list {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .webrtc-item {
    color: var(--text-secondary);
    padding: 3px 7px;
    background: var(--box-bg);
    border-radius: 4px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .webrtc-item.dangerous-ip {
    background: rgba(255, 0, 85, 0.08);
    border-left: 2px solid #ff0055;
  }

  .leak-tag {
    font-size: 9px;
    background: #ff0055;
    color: #ffffff;
    padding: 1px 4px;
    border-radius: 2px;
    font-weight: bold;
  }

  .int-tag {
    font-size: 9px;
    background: var(--box-bg);
    color: var(--text-secondary);
    padding: 1px 4px;
    border-radius: 2px;
  }

  .int-tag.safe {
    background: rgba(0, 243, 255, 0.12);
    color: var(--color-accent);
    border: 1px solid rgba(0, 243, 255, 0.25);
  }

  .consistency-item {
    background: var(--sub-item-bg);
    border: 1px solid var(--card-border);
    border-radius: 10px;
    padding: 9px;
    transition: background 0.4s ease, border-color 0.4s ease;
  }

  .cons-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 12px;
    font-weight: 700;
    margin-bottom: 7px;
    color: var(--text-primary);
    transition: color 0.4s ease;
  }

  .match-indicator {
    font-size: 11px;
    padding: 2px 6px;
    border-radius: 4px;
    background: rgba(255, 85, 0, 0.15);
    color: var(--color-orange);
  }

  .match-indicator.match {
    background: rgba(0, 243, 255, 0.15);
    color: var(--color-accent);
  }

  .cons-body {
    display: flex;
    flex-direction: column;
    gap: 3px;
    color: var(--text-secondary);
    transition: color 0.4s ease;
  }

  .fix-tip {
    font-size: 10px;
    color: var(--color-warning-text);
    margin: 5px 0 0 0;
    line-height: 1.3;
  }

  .ja4-box {
    background: var(--box-bg);
    border: 1px solid var(--card-border);
    border-radius: 8px;
    padding: 8px 9px;
    margin-top: 6px;
    word-break: break-all;
    font-size: 11px;
    color: var(--color-accent);
    line-height: 1.3;
    box-shadow: inset 0 2px 4px rgba(0,0,0,0.15);
    transition: background 0.4s ease, border-color 0.4s ease;
  }

  .ja4-section {
    display: flex;
    flex-direction: column;
    gap: 4px;
    font-size: 12px;
  }

  .bot-warning {
    margin-top: 10px;
    padding: 8px 10px;
    background: rgba(255, 0, 85, 0.08);
    border-color: rgba(255, 0, 85, 0.25);
    font-size: 10px;
    line-height: 1.35;
    color: var(--text-secondary);
  }

  .bot-warning strong {
    color: var(--color-danger);
  }

  .browser-integrity {
    margin-top: 10px;
  }

  .browser-meta {
    margin-top: 6px;
  }

  /* Skeleton Screen Styles */
  .skeleton-loader {
    display: flex;
    flex-direction: column;
    gap: 12px;
    width: 100%;
  }

  .sk-line, .sk-line-short, .sk-bar, .sk-block {
    background: linear-gradient(90deg, rgba(255,255,255,0.03) 25%, rgba(255,255,255,0.08) 37%, rgba(255,255,255,0.03) 63%);
    background-size: 400% 100%;
    animation: skeleton-glow 1.4s ease infinite;
    border-radius: 4px;
  }

  .sk-line {
    height: 16px;
    width: 100%;
  }

  .sk-line-short {
    height: 16px;
    width: 60%;
  }

  .sk-bar {
    height: 6px;
    width: 100%;
    margin-top: 8px;
  }

  .sk-block {
    height: 80px;
    width: 100%;
    border-radius: 8px;
  }

  @keyframes skeleton-glow {
    0% { background-position: 100% 50%; }
    100% { background-position: 0% 50%; }
  }

  /* Custom Scrollbar */
  .scrollbar::-webkit-scrollbar {
    width: 6px;
  }
  .scrollbar::-webkit-scrollbar-track {
    background: rgba(0, 0, 0, 0.05);
  }
  .scrollbar::-webkit-scrollbar-thumb {
    background: var(--border-hover);
    border-radius: 3px;
  }
  .scrollbar::-webkit-scrollbar-thumb:hover {
    background: var(--text-muted);
  }

  /* Light Theme Specific Adjustments */
  :global(.light-theme) .int-tag.safe {
    background: rgba(8, 145, 178, 0.08);
    border-color: rgba(8, 145, 178, 0.2);
  }

  :global(.light-theme) .status-indicator.safe {
    background: rgba(8, 145, 178, 0.08);
  }

  :global(.light-theme) .status-indicator.danger {
    background: rgba(220, 38, 38, 0.08);
  }

  :global(.light-theme) .status-indicator.warn {
    background: rgba(217, 119, 6, 0.08);
  }

  :global(.light-theme) .match-indicator.match {
    background: rgba(8, 145, 178, 0.08);
  }

  :global(.light-theme) .match-indicator {
    background: rgba(234, 88, 12, 0.08);
  }
</style>
