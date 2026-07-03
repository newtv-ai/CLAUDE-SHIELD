<script lang="ts">
  // Using Svelte 5 runes
  let { riskScore = 0, riskLevel = "未检测", isScanning = false, onScan, report = null } = $props<{
    riskScore: number;
    riskLevel: string;
    isScanning: boolean;
    onScan: () => void;
    report: any | null;
  }>();

  const radius = 75;
  const circumference = Math.PI * radius;
  
  // Derived state in Svelte 5 (values, not functions)
  let dashOffset = $derived(circumference - (Math.min(100, Math.max(0, riskScore)) / 100) * circumference);
  
  let riskColor = $derived(
    riskLevel === "未检测" ? "#a0aec0" :
    riskScore < 25 ? "#00f3ff" : // Cyan - Safe
    riskScore < 50 ? "#ffb700" : // Yellow/Orange - Warning
    riskScore < 75 ? "#ff5d00" : // Deep Orange - High Risk
    "#ff0055" // Red - Danger
  );

  let shadowColor = $derived(
    riskLevel === "未检测" ? "rgba(160, 174, 192, 0.3)" :
    riskScore < 25 ? "rgba(0, 243, 255, 0.4)" :
    riskScore < 50 ? "rgba(255, 183, 0, 0.4)" :
    riskScore < 75 ? "rgba(255, 93, 0, 0.4)" :
    "rgba(255, 0, 85, 0.4)"
  );

  let riskDescription = $derived.by(() => {
    if (riskLevel === "未检测") {
      return "请点击下方按钮启动本地访问环境的全维度深度穿透扫描。";
    }
    
    const hasTimezoneConflict = report?.consistency?.timezone_match === false;
    const hasLanguageConflict = report?.consistency?.language_match === false;
    const isUnsupportedRegion = report?.region_policy?.supported_region === false;
    const hasBrowserIntegrityIssue = (report?.browser_integrity?.risk_score || 0) >= 70;

    if (riskScore >= 75) {
      if (isUnsupportedRegion) {
        return "极高风险：当前出口地区不在 Claude 官方支持范围内，建议先切换到受支持地区的稳定网络环境。";
      }
      if (hasBrowserIntegrityIssue) {
        return "极高风险：浏览器暴露自动化、无头或关键会话能力异常信号，容易触发平台风控。";
      }
      return "极高风险：检测到高风险出口网络或严重 DNS/WebRTC 泄露，建议先修复环境再登录。";
    } else if (riskScore >= 50) {
      return "高风险：IP 画像、DNS/WebRTC、地区或浏览器完整性存在明显异常，建议修复后再使用。";
    } else if (riskScore >= 25) {
      return "检测到中度异常，通常来自 WebRTC、时区语言、浏览器指纹或出口网络画像不一致。";
    } else {
      // 低风险 (< 25)
      if (hasTimezoneConflict || hasLanguageConflict) {
        return "基本网络纯净度良好，但检测到【时区或语言指纹冲突】。强烈建议在登录前使用一键脚本或手动调整系统时区为代理节点时区。";
      }
      return "当前网络及浏览器环境未发现明显异常，时区、语言和出口地区对齐良好。";
    }
  });
</script>

<div class="dashboard-card">
  <div class="glow-effect" style="--glow-color: {shadowColor}"></div>
  
  <div class="gauge-container">
    <svg class="gauge-svg" viewBox="0 0 200 120">
      <defs>
        <!-- Filter for HUD neon glow -->
        <filter id="neon-glow" x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur stdDeviation="5" result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
        <!-- Grid pattern for cyberpunk visual theme -->
        <pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse">
          <path d="M 10 0 L 0 0 0 10" fill="none" stroke="rgba(255, 255, 255, 0.03)" stroke-width="0.5" />
        </pattern>
      </defs>

      <!-- Background Grid -->
      <rect width="200" height="120" fill="url(#grid)" />

      <!-- Outer Tick Marks -->
      <path class="ticks" d="M 25 100 A 75 75 0 0 1 175 100" fill="none" stroke="var(--card-border)" stroke-width="3" stroke-dasharray="1 6" />

      <!-- Guage Background Track -->
      <path class="track" d="M 25 100 A 75 75 0 0 1 175 100" fill="none" stroke="var(--card-border)" stroke-width="10" stroke-linecap="round" style="opacity: 0.5;" />

      <!-- Guage Dynamic Value Fill -->
      <path class="value-fill" d="M 25 100 A 75 75 0 0 1 175 100" fill="none" stroke={riskColor} stroke-width="10" stroke-linecap="round" stroke-dasharray={circumference} stroke-dashoffset={dashOffset} filter="url(#neon-glow)" style="transition: stroke-dashoffset 1.5s cubic-bezier(0.19, 1, 0.22, 1), stroke 0.8s ease;" />

      <!-- Center Text Elements -->
      <text x="100" y="70" class="score-num" fill={riskColor}>{riskLevel === "未检测" ? "--" : Math.round(riskScore)}</text>
      <text x="100" y="92" class="score-label" fill="var(--text-muted)">风控危险指数 (R)</text>
    </svg>
  </div>

  <div class="info-panel">
    <div class="risk-badge" style="background-color: {riskColor}33; color: {riskColor}; border-color: {riskColor}80">
      {riskLevel}
    </div>
    <p class="description">{riskDescription}</p>
  </div>

  <button class="scan-button" onclick={onScan} disabled={isScanning} style="--btn-color: {riskColor}">
    {#if isScanning}
      <span class="spinner"></span>
      <span>正在穿透审计...</span>
    {:else}
      <svg class="scan-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M22 12A10 10 0 1 1 12 2v10z"/>
      </svg>
      <span>启动风险环境核验</span>
    {/if}
  </button>
</div>

<style>
  .dashboard-card {
    position: relative;
    background: var(--dashboard-bg);
    border: 1px solid var(--dashboard-border);
    backdrop-filter: blur(16px);
    border-radius: 16px;
    padding: 18px;
    display: flex;
    flex-direction: column;
    align-items: center;
    overflow: hidden;
    box-shadow: 0 14px 28px var(--shadow-color);
    box-sizing: border-box;
    transition: background 0.4s ease, border-color 0.4s ease, box-shadow 0.4s ease;
  }

  .glow-effect {
    position: absolute;
    top: -50%;
    left: -50%;
    width: 200%;
    height: 200%;
    background: radial-gradient(circle, var(--glow-color) 0%, transparent 60%);
    pointer-events: none;
    z-index: 0;
    opacity: 0.15;
    transition: background 1s ease;
  }

  .gauge-container {
    position: relative;
    width: 100%;
    max-width: 218px;
    z-index: 1;
  }

  .gauge-svg {
    width: 100%;
    height: auto;
  }

  .score-num {
    font-size: 30px;
    font-weight: 800;
    text-anchor: middle;
    font-family: 'Outfit', 'Inter', sans-serif;
  }

  .score-label {
    font-size: 8px;
    font-weight: 600;
    text-anchor: middle;
    letter-spacing: 1px;
    text-transform: uppercase;
  }

  .info-panel {
    text-align: center;
    margin-top: 8px;
    margin-bottom: 16px;
    z-index: 1;
    max-width: 360px;
  }

  .risk-badge {
    display: inline-block;
    padding: 5px 14px;
    border-radius: 30px;
    font-size: 14px;
    font-weight: 700;
    letter-spacing: 1px;
    border: 1px solid;
    margin-bottom: 8px;
    transition: all 0.5s ease;
  }

  .description {
    font-size: 13px;
    line-height: 1.45;
    color: var(--text-secondary);
    margin: 0;
    min-height: 38px;
    transition: color 0.4s ease;
  }

  .scan-button {
    position: relative;
    z-index: 1;
    width: 100%;
    padding: 12px 20px;
    border-radius: 10px;
    border: 1px solid var(--card-border);
    background: var(--box-bg);
    color: var(--text-primary);
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    overflow: hidden;
  }

  .scan-button:hover:not(:disabled) {
    background: var(--btn-color);
    box-shadow: 0 0 20px var(--btn-color);
    border-color: transparent;
    transform: translateY(-2px);
    color: #0b0f19;
  }

  .scan-button:hover:not(:disabled) .scan-icon {
    transform: rotate(45deg);
  }

  .scan-button:active:not(:disabled) {
    transform: translateY(0);
  }

  .scan-button:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .scan-icon {
    width: 20px;
    height: 20px;
    transition: transform 0.5s ease;
  }

  .spinner {
    width: 18px;
    height: 18px;
    border: 2px solid var(--text-muted);
    border-top-color: var(--text-primary);
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }
</style>
