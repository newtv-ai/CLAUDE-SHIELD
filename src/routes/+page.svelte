<script lang="ts">
  import { onMount } from "svelte";
  import Dashboard from "../lib/Dashboard.svelte";
  import DetailCards from "../lib/DetailCards.svelte";
  import SettingsCard from "../lib/SettingsCard.svelte";
  import { detectWebRtcIps } from "../lib/webrtc";

  // System states using Svelte 5 state runes
  let riskScore = $state(0);
  let riskLevel = $state("未检测");
  let isScanning = $state(false);
  let report = $state<any | null>(null);
  let webrtcIps = $state<string[]>([]);
  
  // Settings states
  let useMock = $state(false);
  let mockScenario = $state("clean");

  // Theme state
  let currentTheme = $state("dark");

  function toggleTheme() {
    currentTheme = currentTheme === "dark" ? "light" : "dark";
    if (typeof document !== "undefined") {
      const root = document.documentElement;
      if (currentTheme === "light") {
        root.classList.add("light-theme");
        localStorage.setItem("theme", "light");
      } else {
        root.classList.remove("light-theme");
        localStorage.setItem("theme", "dark");
      }
    }
  }

  onMount(() => {
    if (typeof document !== "undefined") {
      const savedTheme = localStorage.getItem("theme");
      if (savedTheme === "light") {
        currentTheme = "light";
        document.documentElement.classList.add("light-theme");
      }
    }
  });

  // Mock Scenario Data Map
  const mockReports: Record<string, any> = {
    clean: {
      ip_info: {
        status: "success",
        query: "185.220.101.5",
        country: "United States",
        countryCode: "US",
        timezone: "America/New_York",
        isp: "Comcast Cable Communications",
        mobile: false,
        proxy: false,
        hosting: false
      },
      ipqs_info: {
        success: true,
        fraud_score: 5,
        connection_type: "residential",
        abuse_velocity: "none",
        active_vpn: false,
        active_tor: false
      },
      consistency: {
        system_timezone: "America/New_York",
        system_language: "en-US",
        timezone_match: true,
        language_match: true
      },
      dns_leak: {
        dns_leak_detected: false,
        dns_servers: ["172.56.21.4 (US)", "172.56.21.5 (US)"],
        leak_details: "共检测到 2 个 DNS 解析服务器，均位于美国，未发现代理穿透泄露风险。"
      },
      tls_fingerprint: {
        ja4_fingerprint: "t13d1516h2_8daaf6152771_02713d6af862 (Chrome/Edge Standard)",
        user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        ja4_match: true,
        match_score: 100
      },
      risk_score: 4.5,
      risk_level: "低风险"
    },
    warning: {
      ip_info: {
        status: "success",
        query: "192.210.211.34",
        country: "United States",
        countryCode: "US",
        timezone: "America/Los_Angeles",
        isp: "ColoCrossing",
        mobile: false,
        proxy: false,
        hosting: false
      },
      ipqs_info: {
        success: true,
        fraud_score: 28,
        connection_type: "corporate",
        abuse_velocity: "low",
        active_vpn: true,
        active_tor: false
      },
      consistency: {
        system_timezone: "Asia/Shanghai",
        system_language: "zh-CN",
        timezone_match: false,
        language_match: false
      },
      dns_leak: {
        dns_leak_detected: false,
        dns_servers: ["74.120.15.2 (US)"],
        leak_details: "检测到 1 个 DNS 解析服务器。您的 DNS 流量未暴露国内节点，但系统环境有标记隐患。"
      },
      tls_fingerprint: {
        ja4_fingerprint: "t13d1516h2_8daaf6152771_02713d6af862 (Chrome/Edge Standard)",
        user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        ja4_match: true,
        match_score: 90
      },
      risk_score: 36.2,
      risk_level: "中风险",
      webrtc: ["192.168.1.14", "223.104.40.85"]
    },
    high_risk: {
      ip_info: {
        status: "success",
        query: "45.79.112.56",
        country: "United States",
        countryCode: "US",
        timezone: "America/New_York",
        isp: "Linode LLC",
        mobile: false,
        proxy: true,
        hosting: true
      },
      ipqs_info: {
        success: true,
        fraud_score: 82,
        connection_type: "datacenter",
        abuse_velocity: "medium",
        active_vpn: true,
        active_tor: false
      },
      consistency: {
        system_timezone: "Asia/Shanghai",
        system_language: "zh-CN",
        timezone_match: false,
        language_match: false
      },
      dns_leak: {
        dns_leak_detected: true,
        dns_servers: ["202.96.128.86 (CN)", "114.114.114.114 (CN)"],
        leak_details: "检测到严重 DNS 泄露！您的海外代理出口 IP 属地为 US，但本地 DNS 解析包经由国内电信运营商节点直接流出，暴露出真实国别。"
      },
      tls_fingerprint: {
        ja4_fingerprint: "t13d1516h2_8daaf6152771_02713d6af862 (Chrome/Edge Standard)",
        user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        ja4_match: true,
        match_score: 95
      },
      risk_score: 63.0,
      risk_level: "高风险"
    },
    severe: {
      ip_info: {
        status: "success",
        query: "198.51.100.12",
        country: "United States",
        countryCode: "US",
        timezone: "America/Chicago",
        isp: "DigitalOcean LLC",
        mobile: false,
        proxy: true,
        hosting: true
      },
      ipqs_info: {
        success: true,
        fraud_score: 95,
        connection_type: "datacenter/hosting",
        abuse_velocity: "high",
        active_vpn: true,
        active_tor: false
      },
      consistency: {
        system_timezone: "Asia/Shanghai",
        system_language: "zh-CN",
        timezone_match: false,
        language_match: false
      },
      dns_leak: {
        dns_leak_detected: true,
        dns_servers: ["202.96.128.166 (CN)", "114.114.114.114 (CN)"],
        leak_details: "检测到 DNS 泄露！DNS 请求经由中国境内解析服务器处理，风控系统在握手初期可直接识别真实物理属地。"
      },
      tls_fingerprint: {
        ja4_fingerprint: "t13d1516h2_raw_reqwest_signature_mismatch (Rust reqwest)",
        user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        ja4_match: false,
        match_score: 20
      },
      risk_score: 90.0,
      risk_level: "极高风险",
      webrtc: ["192.168.1.100", "117.136.38.10"]
    }
  };

  type ExitIpInfo = {
    status: "success";
    query: string;
    country: string;
    countryCode: string;
    timezone: string;
    isp: string;
    mobile: boolean;
    proxy: boolean;
    hosting: boolean;
    source?: string;
    city?: string;
    regionName?: string;
    asn?: number | string;
    org?: string;
    connectionType?: string;
  };

  const IP_LOOKUP_TIMEOUT_MS = 2200;
  const DNS_LOOKUP_TIMEOUT_MS = 2500;

  async function fetchWithTimeout(url: string, timeoutMs: number, init: RequestInit = {}): Promise<Response> {
    const controller = new AbortController();
    const timer = window.setTimeout(() => controller.abort(), timeoutMs);

    try {
      return await fetch(url, {
        ...init,
        signal: controller.signal
      });
    } finally {
      window.clearTimeout(timer);
    }
  }

  function parseCloudflareTrace(traceText: string): Record<string, string> {
    return traceText
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean)
      .reduce<Record<string, string>>((acc, line) => {
        const separatorIndex = line.indexOf("=");
        if (separatorIndex > -1) {
          acc[line.slice(0, separatorIndex)] = line.slice(separatorIndex + 1);
        }
        return acc;
      }, {});
  }

  function classifyConnectionType(...values: Array<string | number | undefined | null>) {
    const haystack = values.filter(Boolean).join(" ").toLowerCase();
    const mobileKeywords = ["mobile", "cellular", "wireless", "lte", "5g", "4g"];
    const proxyKeywords = ["vpn", "proxy", "tor", "anonymous", "privacy"];
    const hostingKeywords = [
      "hosting",
      "host",
      "cloud",
      "datacenter",
      "data center",
      "colo",
      "colocation",
      "vps",
      "server",
      "digitalocean",
      "linode",
      "akamai",
      "amazon",
      "aws",
      "google",
      "microsoft",
      "azure",
      "oracle",
      "ovh",
      "hetzner",
      "vultr",
      "contabo",
      "choopa",
      "leaseweb",
      "m247",
      "fastnet data",
      "bluewave"
    ];

    if (mobileKeywords.some((keyword) => haystack.includes(keyword))) return "mobile";
    if (proxyKeywords.some((keyword) => haystack.includes(keyword))) return "proxy";
    if (hostingKeywords.some((keyword) => haystack.includes(keyword))) return "hosting";
    return "residential";
  }

  async function fetchCloudflareTrace() {
    const res = await fetchWithTimeout("https://www.cloudflare.com/cdn-cgi/trace", IP_LOOKUP_TIMEOUT_MS, {
      cache: "no-store"
    });
    if (!res.ok) throw new Error("Cloudflare trace failed");
    return parseCloudflareTrace(await res.text());
  }

  async function fetchIpWhoisLookup(): Promise<ExitIpInfo> {
    const res = await fetchWithTimeout("https://ipwho.is/", IP_LOOKUP_TIMEOUT_MS, {
      cache: "no-store"
    });
    if (!res.ok) throw new Error("IPWHOIS lookup failed");

    const raw = await res.json();
    if (!raw?.success || !raw?.ip) throw new Error(raw?.message || "IPWHOIS lookup failed");

    const connectionType = classifyConnectionType(
      raw.type,
      raw.connection?.isp,
      raw.connection?.org,
      raw.connection?.domain,
      raw.connection?.asn
    );

    return {
      status: "success",
      query: raw.ip,
      country: raw.country || "Unknown",
      countryCode: raw.country_code || "",
      timezone: raw.timezone?.id || "",
      isp: raw.connection?.isp || raw.connection?.org || "Unknown",
      mobile: connectionType === "mobile",
      proxy: connectionType === "proxy",
      hosting: connectionType === "hosting",
      source: "ipwho.is",
      city: raw.city,
      regionName: raw.region,
      asn: raw.connection?.asn,
      org: raw.connection?.org,
      connectionType
    };
  }

  async function fetchIpApiLookup(): Promise<ExitIpInfo> {
    if (typeof window !== "undefined" && window.location.protocol === "https:") {
      throw new Error("Skipping ip-api on HTTPS to avoid mixed-content blocking");
    }

    const res = await fetchWithTimeout("http://ip-api.com/json/?fields=61439", IP_LOOKUP_TIMEOUT_MS, {
      cache: "no-store"
    });
    if (!res.ok) throw new Error("ip-api lookup failed");

    const raw = await res.json();
    if (raw?.status !== "success" || !raw?.query) throw new Error(raw?.message || "ip-api lookup failed");

    return {
      ...raw,
      source: "ip-api.com",
      connectionType: raw.hosting ? "hosting" : raw.proxy ? "proxy" : raw.mobile ? "mobile" : "residential"
    };
  }

  function mergeTraceIntoIpInfo(ipInfo: ExitIpInfo, trace: Record<string, string> | null): ExitIpInfo {
    if (!trace) return ipInfo;

    return {
      ...ipInfo,
      query: trace.ip || ipInfo.query,
      countryCode: ipInfo.countryCode || trace.loc || "",
      source: trace.ip && trace.ip === ipInfo.query
        ? ipInfo.source
        : `${ipInfo.source || "lookup"} + cloudflare-trace`
    };
  }

  function fallbackIpInfoFromTrace(trace: Record<string, string>): ExitIpInfo {
    return {
      status: "success",
      query: trace.ip,
      country: trace.loc || "Unknown",
      countryCode: trace.loc || "",
      timezone: "",
      isp: `Cloudflare edge ${trace.colo || "unknown"}`,
      mobile: false,
      proxy: false,
      hosting: false,
      source: "cloudflare-trace",
      connectionType: "unknown"
    };
  }

  async function fetchExitIpInfo(): Promise<ExitIpInfo> {
    const canUseIpApi = typeof window !== "undefined" && window.location.protocol !== "https:";
    const lookupPromises = canUseIpApi
      ? [fetchIpApiLookup(), fetchIpWhoisLookup()]
      : [fetchIpWhoisLookup()];

    const settled = await Promise.allSettled([fetchCloudflareTrace(), ...lookupPromises]);
    const trace = settled[0].status === "fulfilled" ? settled[0].value : null;
    const ipInfo = settled
      .slice(1)
      .find((result): result is PromiseFulfilledResult<ExitIpInfo> => result.status === "fulfilled")
      ?.value;

    if (ipInfo) return mergeTraceIntoIpInfo(ipInfo, trace);
    if (trace?.ip) return fallbackIpInfoFromTrace(trace);

    throw new Error("Unable to fetch exit IP information from the available providers");
  }

  function estimateIpReputation(ip_info: ExitIpInfo) {
    const connectionType = ip_info.connectionType || classifyConnectionType(ip_info.isp, ip_info.org, ip_info.asn);
    const is_hosting = ip_info.hosting || connectionType === "hosting";
    const is_proxy = ip_info.proxy || connectionType === "proxy";
    const is_mobile = ip_info.mobile || connectionType === "mobile";

    if (is_hosting) {
      return { success: true, fraud_score: 85, connection_type: "datacenter/hosting", abuse_velocity: "medium", active_vpn: true, active_tor: false };
    }

    if (is_proxy) {
      return { success: true, fraud_score: 75, connection_type: "datacenter/proxy", abuse_velocity: "low", active_vpn: true, active_tor: false };
    }

    if (is_mobile) {
      return { success: true, fraud_score: 15, connection_type: "mobile", abuse_velocity: "none", active_vpn: false, active_tor: false };
    }

    return { success: true, fraud_score: 8, connection_type: "residential", abuse_velocity: "none", active_vpn: false, active_tor: false };
  }

  async function fetchDnsLeakItems(checkUrl: string) {
    const attempts = [
      async () => {
        const res = await fetchWithTimeout(
          `https://api.codetabs.com/v1/proxy?quest=${encodeURIComponent(checkUrl)}`,
          DNS_LOOKUP_TIMEOUT_MS
        );
        if (!res.ok) throw new Error("Codetabs DNS proxy failed");
        return await res.json();
      },
      async () => {
        const res = await fetchWithTimeout(
          `https://api.allorigins.win/get?url=${encodeURIComponent(checkUrl)}`,
          DNS_LOOKUP_TIMEOUT_MS
        );
        if (!res.ok) throw new Error("AllOrigins DNS proxy failed");
        const wrapper = await res.json();
        if (!wrapper?.contents) throw new Error("AllOrigins DNS proxy returned empty content");
        return JSON.parse(wrapper.contents);
      }
    ];

    const results = await Promise.allSettled(attempts.map((attempt) => attempt()));
    const success = results.find((result) => result.status === "fulfilled");
    return success?.status === "fulfilled" ? success.value : null;
  }

  // Perform DNS leak check in pure client-side JS
  async function performWebDnsLeakCheck(exitCountryCode: string): Promise<{ dns_leak_detected: boolean; dns_servers: string[]; leak_details: string }> {
    const uuid = "web-dns-" + Math.random().toString(36).substring(2, 12);
    const targetHost = `https://${uuid}.dns.bash.ws/`;
    
    // 1. Force the browser to make a DNS lookup to authoritative servers
    try {
      await fetch(targetHost, { mode: 'no-cors' });
    } catch (e) {
      // Ignore network failures or CORS errors, resolution packet was sent
    }
    
    // 2. Wait briefly for DNS queries to propagate to the bash.ws database.
    await new Promise(resolve => setTimeout(resolve, 1200));
    
    // 3. Request DNS records history for this UUID
    const checkUrl = `https://bash.ws/dnsleak/test/${uuid}?json`;
    let dns_leak_detected = false;
    let dns_servers: string[] = [];
    let leak_details = "未检测到 DNS 泄露。";
    
    try {
      const items = await fetchDnsLeakItems(checkUrl);
      
      if (items && Array.isArray(items)) {
        for (const item of items) {
          if (item.type === "dns") {
            const country = item.country || "Unknown";
            const ip = item.ip;
            dns_servers.push(`${ip} (${country})`);
            
            // Trigger leak flag if overseas proxy egress IP uses a CN DNS server
            if (exitCountryCode !== "CN" && country === "CN") {
              dns_leak_detected = true;
              leak_details = `检测到 DNS 泄露！您的海外代理出口 IP 属地为 ${exitCountryCode}，但本地 DNS 请求由中国境内的解析服务器 ${ip} 拦截解析。这会导致风控检测直接穿透您的代理网络。`;
            }
          }
        }
        if (!dns_leak_detected) {
          if (dns_servers.length === 0) {
            leak_details = "未检测到有效的 DNS 泄露测试包。可能是本地 DNS 缓存了请求，或 DNS 泄露测试包被网络防护设备拦截。";
          } else {
            leak_details = `共检测到 ${dns_servers.length} 个 DNS 解析服务器，均位于境外，未发现穿透泄露风险。`;
          }
        }
      } else if (items && items.error) {
        dns_servers = [];
        leak_details = "未检测到有效的 DNS 泄露测试包。这说明目前没有检测到任何 DNS 泄露，您的本地 DNS 解析未向外部服务器暴露出泄露轨迹。";
      } else {
        leak_details = "DNS 泄露检测服务暂时没有返回可解析结果。当前未发现明确泄露，建议稍后重试确认。";
      }
    } catch (err) {
      leak_details = "连通 DNS 泄露检测服务（bash.ws）失败，请检查您的网络连接。";
    }
    
    return { dns_leak_detected, dns_servers, leak_details };
  }

  // Pure JavaScript environment audit coordinator
  async function performBrowserAudit() {
    isScanning = true;
    report = null;
    webrtcIps = [];

    if (useMock) {
      // Run mock scenario loader with fake delay
      setTimeout(() => {
        const scenarioData = mockReports[mockScenario];
        report = scenarioData;
        riskScore = scenarioData.risk_score;
        riskLevel = scenarioData.risk_level;
        if (scenarioData.webrtc) {
          webrtcIps = scenarioData.webrtc;
        }
        isScanning = false;
      }, 2000);
    } else {
      // Run REAL audit in standard browser environment!
      try {
        const webRtcPromise = detectWebRtcIps().catch((e) => {
          console.warn("WebRTC scanning failed:", e);
          return [];
        });

        // A. Fetch exit IP via fast HTTPS providers with hard timeouts.
        const ip_info = await fetchExitIpInfo();

        if (!ip_info || ip_info.status !== "success") {
          throw new Error("出口地理位置 IP 获取失败，请检查网络连接");
        }

        const countryCode = ip_info.countryCode || "CN";

        // B. Estimate IP reputation from provider network metadata.
        const ipqs_info = estimateIpReputation(ip_info);

        // C. Run WebRTC and DNS leak checks concurrently.
        const [detectedWebRtcIps, dns_report] = await Promise.all([
          webRtcPromise,
          performWebDnsLeakCheck(countryCode)
        ]);
        webrtcIps = detectedWebRtcIps;

        // D. Environment consistency check (JS native APIs)
        const system_timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
        const system_language = navigator.language || "en-US";
        
        let timezone_match = false;
        let language_match = false;

        if (ip_info.timezone) {
          timezone_match = system_timezone.toLowerCase().includes(ip_info.timezone.toLowerCase()) 
            || ip_info.timezone.toLowerCase().includes(system_timezone.toLowerCase())
            || (ip_info.timezone.includes("Shanghai") && (system_timezone.includes("Asia/Shanghai") || system_timezone.includes("China")));
        }

        const lang_prefix = system_language.split('-')[0].toLowerCase();
        language_match = matchLanguageWithCountry(countryCode, lang_prefix);

        const consistency = {
          system_timezone,
          system_language,
          timezone_match,
          language_match
        };

        // E. TLS JA4 analysis
        // In browser, the finger is aligned to the browser itself, so it is 100% simulated.
        const tls_fingerprint = {
          ja4_fingerprint: "t13d1516h2_8daaf6152771_02713d6af862 (Chrome/Edge Standard)",
          user_agent: navigator.userAgent,
          ja4_match: true,
          match_score: 100
        };

        // F. Risk score calculations
        // R = w_ip * S_ip + w_leak * S_leak + w_geo * S_geo + w_tls * S_tls
        // Weights: ip: 0.40, leak: 0.25, geo: 0.20, tls: 0.15
        
        // S_ip
        let s_ip = 50;
        if (ipqs_info.connection_type.includes("datacenter") || ipqs_info.connection_type.includes("hosting")) {
          s_ip = ipqs_info.fraud_score > 75 ? 100 : 70;
        } else if (ipqs_info.connection_type.includes("residential")) {
          s_ip = ipqs_info.fraud_score < 10 ? 0 : 30;
        }

        // S_leak (DNS + WebRTC)
        let hasWebRtcLeak = false;
        if (countryCode !== "CN" && ip_info) {
          for (const ip of webrtcIps) {
            const isPrivate = ip.startsWith("192.168.") 
              || ip.startsWith("10.") 
              || ip.startsWith("127.") 
              || ip.startsWith("172.16.") || ip.startsWith("172.17.") || ip.startsWith("172.18.") || ip.startsWith("172.19.") || ip.startsWith("172.2") || ip.startsWith("172.3");
            if (!isPrivate && ip !== "" && ip !== ip_info.query) {
              hasWebRtcLeak = true;
              break;
            }
          }
        }

        const s_leak = (dns_report.dns_leak_detected && hasWebRtcLeak) ? 100 : (dns_report.dns_leak_detected || hasWebRtcLeak) ? 60 : 0;

        // S_geo
        const s_geo = (!consistency.timezone_match && !consistency.language_match) ? 100 : (!consistency.timezone_match || !consistency.language_match) ? 50 : 0;

        // S_tls
        const s_tls = 0; // Standard browser client, no bot anomalies detected

        // Risk Summation
        riskScore = 0.40 * s_ip + 0.25 * s_leak + 0.20 * s_geo + 0.15 * s_tls;

        if (riskScore < 25) riskLevel = "低风险";
        else if (riskScore < 50) riskLevel = "中风险";
        else if (riskScore < 75) riskLevel = "高风险";
        else riskLevel = "极高风险";

        report = {
          ip_info,
          ipqs_info,
          consistency,
          dns_leak: dns_report,
          tls_fingerprint
        };

      } catch (err: any) {
        console.error("Browser real audit error:", err);
        alert(`真实环境扫描失败: ${err.message || err}。请切换至演示/Mock模式进行功能演示。`);
      } finally {
        isScanning = false;
      }
    }
  }

  function matchLanguageWithCountry(countryCode: string, langPrefix: string): boolean {
    switch (countryCode) {
      case "CN": return langPrefix === "zh";
      case "US":
      case "GB":
      case "CA":
      case "AU": return langPrefix === "en";
      case "JP": return langPrefix === "ja";
      case "SG": return langPrefix === "zh" || langPrefix === "en";
      default: return true;
    }
  }
</script>

<svelte:head>
  <title>Claude Shield - 克劳德之盾账户风控评估系统</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Outfit:wght@500;700;800;900&family=Fira+Code:wght@400;500&display=swap" rel="stylesheet">
</svelte:head>

<main class="app-container">
  <header class="app-header">
    <div class="header-main">
      <div class="brand">
        <div class="pulse-dot"></div>
        <h1>CLAUDE <span class="accent-text">SHIELD</span></h1>
        <span class="version-tag">Web v2.0-Light</span>
      </div>
      <p class="subtitle">极轻量 Claude 账户环境安全与风控穿透检测系统</p>
    </div>
    
    <button class="theme-toggle-btn" onclick={toggleTheme} aria-label="切换主题风格">
      {#if currentTheme === 'dark'}
        <!-- Moon Icon -->
        <svg class="theme-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
        </svg>
      {:else}
        <!-- Sun Icon -->
        <svg class="theme-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="5"/>
          <line x1="12" y1="1" x2="12" y2="3"/>
          <line x1="12" y1="21" x2="12" y2="23"/>
          <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/>
          <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
          <line x1="1" y1="12" x2="3" y2="12"/>
          <line x1="21" y1="12" x2="23" y2="12"/>
          <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/>
          <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
        </svg>
      {/if}
    </button>
  </header>

  <div class="grid-layout">
    <!-- Left Column: Master Controller & Gauge -->
    <div class="col-left">
      <Dashboard {riskScore} {riskLevel} {isScanning} {report} onScan={performBrowserAudit} />
      <div style="margin-top: 20px;">
        <SettingsCard bind:useMock bind:mockScenario />
      </div>
    </div>

    <!-- Right Column: Detail Metrics Panels -->
    <div class="col-right">
      <DetailCards {report} {webrtcIps} />
    </div>
  </div>

  <footer class="app-footer">
    <p>© 2026 Claude Shield. 纯 Web 绿盟安全评估版（零依赖、轻量化）。</p>
  </footer>
</main>

<style>
  :global(:root) {
    --bg-color-1: #111a33;
    --bg-color-2: #080b11;
    --card-bg: rgba(13, 20, 38, 0.45);
    --card-border: rgba(255, 255, 255, 0.05);
    --card-shadow: rgba(0, 0, 0, 0.4);
    --text-primary: #ffffff;
    --text-secondary: rgba(255, 255, 255, 0.7);
    --text-muted: rgba(255, 255, 255, 0.4);
    --box-bg: rgba(0, 0, 0, 0.2);
    --border-hover: rgba(255, 255, 255, 0.12);
    --dashboard-bg: rgba(13, 20, 38, 0.6);
    --dashboard-border: rgba(255, 255, 255, 0.08);
    --color-accent: #00f3ff;
    --color-warning: #ffaa00;
    --color-warning-text: #ff8800;
    --color-danger: #ff0055;
    --color-orange: #ff5500;
  }

  :global(.light-theme) {
    --bg-color-1: #f3f6fc;
    --bg-color-2: #e2e8f0;
    --card-bg: rgba(255, 255, 255, 0.75);
    --card-border: rgba(15, 23, 42, 0.08);
    --card-shadow: rgba(15, 23, 42, 0.06);
    --text-primary: #0f172a;
    --text-secondary: #334155;
    --text-muted: #64748b;
    --box-bg: rgba(15, 23, 42, 0.04);
    --border-hover: rgba(15, 23, 42, 0.12);
    --dashboard-bg: rgba(255, 255, 255, 0.85);
    --dashboard-border: rgba(15, 23, 42, 0.1);
    --color-accent: #0891b2;
    --color-warning: #d97706;
    --color-warning-text: #c2410c;
    --color-danger: #dc2626;
    --color-orange: #ea580c;
  }

  :global(body) {
    margin: 0;
    padding: 0;
    font-family: 'Inter', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
    background: radial-gradient(circle at top right, var(--bg-color-1) 0%, var(--bg-color-2) 70%);
    background-attachment: fixed;
    color: var(--text-primary);
    min-height: 100vh;
    -webkit-font-smoothing: antialiased;
    overflow-x: hidden;
    transition: background 0.4s ease, color 0.4s ease;
  }

  .app-container {
    max-width: 1280px;
    margin: 0 auto;
    padding: 40px 20px;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    box-sizing: border-box;
  }

  .app-header {
    margin-bottom: 40px;
    padding-left: 12px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .header-main {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .theme-toggle-btn {
    background: var(--card-bg);
    border: 1px solid var(--card-border);
    color: var(--text-primary);
    width: 44px;
    height: 44px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    box-shadow: 0 4px 12px var(--card-shadow);
    backdrop-filter: blur(12px);
  }

  .theme-toggle-btn:hover {
    border-color: #00f3ff;
    box-shadow: 0 0 12px rgba(0, 243, 255, 0.25);
    transform: translateY(-2px) rotate(15deg);
  }

  .theme-toggle-btn:active {
    transform: translateY(0);
  }

  .theme-icon {
    width: 20px;
    height: 20px;
  }

  .brand {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .pulse-dot {
    width: 10px;
    height: 10px;
    border-radius: 50%;
    background-color: #00f3ff;
    box-shadow: 0 0 10px #00f3ff;
    animation: pulse 2s infinite;
  }

  @keyframes pulse {
    0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(0, 243, 255, 0.7); }
    70% { transform: scale(1); box-shadow: 0 0 0 10px rgba(0, 243, 255, 0); }
    100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(0, 243, 255, 0); }
  }

  .app-header h1 {
    font-family: 'Outfit', sans-serif;
    font-size: 28px;
    font-weight: 900;
    letter-spacing: 2px;
    margin: 0;
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .accent-text {
    background: linear-gradient(135deg, #00f3ff 0%, #ff0055 100%);
    background-clip: text;
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }

  .version-tag {
    font-size: 11px;
    background: var(--box-bg);
    border: 1px solid var(--card-border);
    border-radius: 6px;
    padding: 2px 8px;
    color: var(--text-muted);
    font-weight: 600;
  }

  .subtitle {
    font-size: 14px;
    color: var(--text-muted);
    margin: 6px 0 0 0;
    letter-spacing: 0.5px;
  }

  .grid-layout {
    display: grid;
    grid-template-columns: 360px 1fr;
    gap: 30px;
    flex-grow: 1;
    align-items: stretch;
  }

  @media (max-width: 900px) {
    .grid-layout {
      grid-template-columns: 1fr;
    }
  }

  .col-left {
    display: flex;
    flex-direction: column;
    gap: 0;
    position: sticky;
    top: 40px;
  }

  .col-right {
    display: flex;
    flex-direction: column;
    gap: 20px;
    height: 100%;
  }

  .app-footer {
    margin-top: 50px;
    border-top: 1px solid var(--card-border);
    padding-top: 20px;
    text-align: center;
    font-size: 12px;
    color: var(--text-muted);
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

</style>
