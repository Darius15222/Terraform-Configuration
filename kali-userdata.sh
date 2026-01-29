#!/bin/bash
# ============================================================
# KALI LINUX - CYBERCHEF DEPLOYMENT
# ============================================================
# Sets up CyberChef for data analysis and traffic inspection
# Wireshark is pre-installed on Kali Linux
# ============================================================

set -e  # Exit on any error
set -x  # Debug mode - log all commands

LOG_FILE="/var/log/userdata.log"
exec > >(tee -a ${LOG_FILE}) 2>&1

echo "========================================"
echo "Kali Linux Setup Started"
echo "Timestamp: $(date)"
echo "========================================"

# Update system packages
echo "[1/4] Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# Install Docker
echo "[2/4] Installing Docker..."
apt-get install -y docker.io docker-compose

# Enable and start Docker service
systemctl enable docker
systemctl start docker

# Verify Docker installation
docker --version

# Deploy CyberChef for data analysis
echo "[3/4] Deploying CyberChef..."
docker run -d \
  --name cyberchef \
  --restart unless-stopped \
  -p 8000:8000 \
  mpepping/cyberchef:latest

# Wait for container to start
echo "Waiting for CyberChef to start..."
sleep 5

# Verify CyberChef is running
if docker ps | grep -q cyberchef; then
    echo "✅ CyberChef container is running"
else
    echo "❌ CyberChef container failed to start"
    docker logs cyberchef
    exit 1
fi

# Test CyberChef accessibility
if curl -f http://localhost:8000 > /dev/null 2>&1; then
    echo "✅ CyberChef is accessible on port 8000"
else
    echo "⚠️  CyberChef container running but not responding yet (may need more time)"
fi

# Create desktop shortcuts for user 'kali'
echo "[4/4] Creating desktop shortcuts..."
mkdir -p /home/kali/Desktop

# CyberChef shortcut
cat > /home/kali/Desktop/cyberchef.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=CyberChef
Comment=Web-based data analysis tool
Exec=firefox http://localhost:8000
Icon=firefox
Terminal=false
Categories=Security;
EOF

# Lab targets information file
cat > /home/kali/Desktop/LAB_TARGETS.txt <<'EOF'
╔═══════════════════════════════════════════════════════════╗
║              CYBERSECURITY LAB - TARGETS                  ║
╚═══════════════════════════════════════════════════════════╝

VULNERABLE APPLICATIONS
────────────────────────────────────────────────────────────
🎯 JuiceShop (Ubuntu Server)
   URL: http://10.0.3.100:3000
   Type: Modern vulnerable web application
   Vulnerabilities: SQLi, XSS, Broken Auth, etc.

ANALYSIS TOOLS
────────────────────────────────────────────────────────────
🔬 CyberChef (Local - Kali)
   URL: http://localhost:8000
   Purpose: Decode/analyze captured data

📊 Wireshark (Pre-installed)
   Command: sudo wireshark
   Purpose: Capture network traffic

🕵️  Burp Suite (Pre-installed)
   Command: burpsuite
   Purpose: Intercept HTTP/HTTPS, steal cookies

NETWORK INFORMATION
────────────────────────────────────────────────────────────
Kali IP:        10.0.2.100
Ubuntu IP:      10.0.3.100
pfSense LAN:    10.0.2.10
pfSense OPT:    10.0.3.10

QUICK ATTACK SCENARIOS
────────────────────────────────────────────────────────────
1. SQL Injection:
   - Browse to JuiceShop login
   - Email: ' OR 1=1--
   - Capture traffic with Wireshark

2. Cookie Interception:
   - Open Burp Suite (Proxy > Intercept On)
   - Browse to JuiceShop
   - Login as normal user
   - Copy session cookie from intercepted request
   - Analyze in CyberChef (JWT Decode)

3. Traffic Analysis:
   - Start Wireshark capture (sudo wireshark)
   - Perform attacks on JuiceShop
   - Stop capture
   - Filter: http or tcp.port==3000
   - Export as .pcap for coursework

╚═══════════════════════════════════════════════════════════╝
EOF

# Set proper permissions
chown -R kali:kali /home/kali/Desktop
chmod +x /home/kali/Desktop/*.desktop
chmod 644 /home/kali/Desktop/LAB_TARGETS.txt

# Create status file
cat > /tmp/kali-status.json <<EOF
{
  "service": "Kali_CyberChef",
  "status": "running",
  "cyberchef_port": 8000,
  "container": "$(docker ps --filter name=cyberchef --format '{{.ID}}')",
  "deployed_at": "$(date -Iseconds)"
}
EOF

echo "========================================"
echo "✅ Kali Linux Setup Completed"
echo "Timestamp: $(date)"
echo "Services:"
echo "  - Docker: $(docker --version)"
echo "  - CyberChef: http://localhost:8000"
echo "  - Wireshark: Pre-installed (GUI)"
echo "  - Burp Suite: Pre-installed (GUI)"
echo "========================================"
