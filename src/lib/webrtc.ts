/**
 * WebRTC IP leak detector helper.
 * Initiates an RTC connection with public STUN servers to force ICE gathering and extract local and public IP addresses.
 */
export async function detectWebRtcIps(): Promise<string[]> {
  return new Promise((resolve, reject) => {
    const discoveredIps: string[] = [];
    const config: RTCConfiguration = {
      iceServers: [
        { urls: 'stun:stun1.l.google.com:19302' },
        { urls: 'stun:stun.l.google.com:19302' }
      ]
    };

    try {
      const pc = new RTCPeerConnection(config);
      // Create a dummy channel to force ICE candidates gathering
      pc.createDataChannel("leak-detector-channel");

      pc.onicecandidate = (event) => {
        if (event.candidate) {
          const candidateStr = event.candidate.candidate;
          // Extract IPv4 address via regex
          const ipv4Pattern = /([0-9]{1,3}(\.[0-9]{1,3}){3})/;
          const matches = ipv4Pattern.exec(candidateStr);
          if (matches && matches[1]) {
            const ip = matches[1];
            if (!discoveredIps.includes(ip)) {
              discoveredIps.push(ip);
            }
          }
        } else {
          // Candidates gathering completed
          pc.close();
          resolve(discoveredIps);
        }
      };

      pc.createOffer()
        .then((offer) => pc.setLocalDescription(offer))
        .catch((err) => {
          try { pc.close(); } catch(e) {}
          reject(err);
        });

      // 8 seconds timeout fallback
      setTimeout(() => {
        try { pc.close(); } catch(e) {}
        resolve(discoveredIps);
      }, 8000);
      
    } catch (err) {
      reject(err);
    }
  });
}
