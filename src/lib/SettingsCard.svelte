<script lang="ts">
  // Svelte 5 syntax with bindable props
  let { 
    useMock = $bindable(false), 
    mockScenario = $bindable("clean") 
  } = $props<{
    useMock: boolean;
    mockScenario: string;
  }>();
</script>

<div class="settings-card">
  <div class="header">
    <svg class="header-icon" viewBox="0 0 24 24" fill="none" stroke="#00f3ff" stroke-width="2">
      <circle cx="12" cy="12" r="3"/>
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>
    </svg>
    <h3>系统控制面板</h3>
  </div>

  <div class="settings-body">
    <!-- Toggle Mock Mode -->
    <div class="setting-item-row">
      <div class="text-group">
        <span class="setting-label">演示/调试模式 (Mock)</span>
        <span class="setting-tip">开启后，系统将使用预设的环境数据进行判定。</span>
      </div>
      <label class="switch" for="mock-toggle">
        <input id="mock-toggle" type="checkbox" bind:checked={useMock} />
        <span class="slider"></span>
      </label>
    </div>

    <!-- Scenario Selection (Visible only in Mock mode) -->
    {#if useMock}
      <div class="setting-item scenario-select">
        <span class="setting-label">环境数据预设场景</span>
        <div class="scenario-grid">
          <button type="button" class="scenario-btn" class:active={mockScenario === 'clean'} onclick={() => mockScenario = 'clean'}>
            <span class="dot clean"></span>
            <div class="btn-text">
              <span class="btn-title">纯净环境</span>
              <span class="btn-desc">原生住宅ISP，完全无泄露</span>
            </div>
          </button>
          
          <button type="button" class="scenario-btn" class:active={mockScenario === 'warning'} onclick={() => mockScenario = 'warning'}>
            <span class="dot warning"></span>
            <div class="btn-text">
              <span class="btn-title">中风险</span>
              <span class="btn-desc">WebRTC泄露 / 时区冲突</span>
            </div>
          </button>
          
          <button type="button" class="scenario-btn" class:active={mockScenario === 'high_risk'} onclick={() => mockScenario = 'high_risk'}>
            <span class="dot high_risk"></span>
            <div class="btn-text">
              <span class="btn-title">高风险</span>
              <span class="btn-desc">数据中心机房IP / DNS泄露</span>
            </div>
          </button>
          
          <button type="button" class="scenario-btn" class:active={mockScenario === 'severe'} onclick={() => mockScenario = 'severe'}>
            <span class="dot severe"></span>
            <div class="btn-text">
              <span class="btn-title">秒封环境</span>
              <span class="btn-desc">被标机房IP + 双泄露 + TLS异常</span>
            </div>
          </button>
        </div>
      </div>
    {/if}
  </div>
</div>

<style>
  .settings-card {
    background: var(--card-bg);
    border: 1px solid var(--card-border);
    backdrop-filter: blur(12px);
    border-radius: 14px;
    padding: 18px;
    box-shadow: 0 8px 22px var(--shadow-color);
    width: 100%;
    box-sizing: border-box;
    display: flex;
    flex-direction: column;
    transition: background 0.4s ease, border-color 0.4s ease, box-shadow 0.4s ease;
  }

  .header {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 14px;
    border-bottom: 1px solid var(--card-border);
    padding-bottom: 10px;
  }

  .header-icon {
    width: 22px;
    height: 22px;
    animation: rotate 15s linear infinite;
  }

  @keyframes rotate {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }

  .header h3 {
    margin: 0;
    font-size: 15px;
    font-weight: 700;
    color: var(--text-primary);
    letter-spacing: 0.5px;
  }

  .settings-body {
    display: flex;
    flex-direction: column;
    gap: 14px;
  }

  .setting-item {
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .setting-item-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .text-group {
    display: flex;
    flex-direction: column;
    gap: 4px;
    max-width: 75%;
  }

  .setting-label {
    font-size: 13px;
    font-weight: 600;
    color: var(--text-primary);
  }

  .setting-tip {
    font-size: 10px;
    color: var(--text-muted);
    line-height: 1.4;
  }



  /* Switch Toggle Button */
  .switch {
    position: relative;
    display: inline-block;
    width: 44px;
    height: 22px;
    flex-shrink: 0;
  }

  .switch input {
    opacity: 0;
    width: 0;
    height: 0;
  }

  .slider {
    position: absolute;
    cursor: pointer;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: var(--box-bg);
    transition: .4s;
    border-radius: 34px;
    border: 1px solid var(--card-border);
  }

  .slider:before {
    position: absolute;
    content: "";
    height: 14px;
    width: 14px;
    left: 3px;
    bottom: 3px;
    background-color: var(--text-muted);
    transition: .4s;
    border-radius: 50%;
  }

  input:checked + .slider {
    background-color: #00f3ff;
  }

  input:checked + .slider:before {
    transform: translateX(22px);
    background-color: #0b0f19;
  }

  /* Cyberpunk Preset Buttons Group */
  .scenario-select {
    border-top: 1px solid var(--card-border);
    padding-top: 12px;
    animation: slideDown 0.3s ease;
  }

  .scenario-grid {
    display: flex;
    flex-direction: column;
    gap: 6px;
    margin-top: 8px;
  }

  .scenario-btn {
    display: flex;
    align-items: center;
    gap: 10px;
    width: 100%;
    padding: 8px 12px;
    border-radius: 8px;
    border: 1px solid var(--card-border);
    background: var(--box-bg);
    cursor: pointer;
    text-align: left;
    transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  }

  .scenario-btn:hover {
    background: var(--box-bg);
    border-color: var(--border-hover);
  }

  .scenario-btn.active {
    background: var(--box-bg);
  }

  .scenario-btn.active:has(.dot.clean) {
    border-color: rgba(0, 243, 255, 0.5);
    box-shadow: 0 0 12px rgba(0, 243, 255, 0.15), inset 0 0 8px rgba(0, 243, 255, 0.05);
  }
  
  .scenario-btn.active:has(.dot.warning) {
    border-color: rgba(255, 170, 0, 0.5);
    box-shadow: 0 0 12px rgba(255, 170, 0, 0.15), inset 0 0 8px rgba(255, 170, 0, 0.05);
  }

  .scenario-btn.active:has(.dot.high_risk) {
    border-color: rgba(255, 93, 0, 0.5);
    box-shadow: 0 0 12px rgba(255, 93, 0, 0.15), inset 0 0 8px rgba(255, 93, 0, 0.05);
  }

  .scenario-btn.active:has(.dot.severe) {
    border-color: rgba(255, 0, 85, 0.5);
    box-shadow: 0 0 12px rgba(255, 0, 85, 0.15), inset 0 0 8px rgba(255, 0, 85, 0.05);
  }

  .dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .dot.clean { background: #00f3ff; box-shadow: 0 0 6px #00f3ff; }
  .dot.warning { background: #ffaa00; box-shadow: 0 0 6px #ffaa00; }
  .dot.high_risk { background: #ff5d00; box-shadow: 0 0 6px #ff5d00; }
  .dot.severe { background: #ff0055; box-shadow: 0 0 6px #ff0055; }

  .btn-text {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .btn-title {
    font-size: 13px;
    font-weight: 700;
    color: var(--text-secondary);
  }

  .scenario-btn.active .btn-title {
    color: var(--text-primary);
  }

  .btn-desc {
    font-size: 10px;
    color: var(--text-muted);
  }

  .scenario-btn.active .btn-desc {
    color: var(--text-secondary);
  }

  @keyframes slideDown {
    from { opacity: 0; transform: translateY(-10px); }
    to { opacity: 1; transform: translateY(0); }
  }
</style>
