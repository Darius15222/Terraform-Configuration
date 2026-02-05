#!/bin/bash
# ============================================================
# UBUNTU ROUTER - Complete pfSense Replacement
# ============================================================
# Replicates all pfSense functionality:
# - Routing/NAT between WAN, LAN, OPT1
# - DHCP Server (LAN: 10.0.2.100-200, OPT1: 10.0.3.100-200)
# - DNS Resolver (dnsmasq with DNSSEC)
# - Firewall (iptables)
# - Snort IDS
# ============================================================

set -e
exec > >(tee -a /var/log/router-setup.log) 2>&1

echo "========================================"
echo "Ubuntu Router Setup Started"
echo "Timestamp: $(date)"
echo "========================================"

# ============================================================
# STEP 1: System Updates & Prerequisites
# ============================================================
echo "[1/8] Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y \
    dnsmasq \
    iptables-persistent \
    snort \
    oinkmaster \
    net-tools \
    tcpdump \
    curl \
    wget

# ============================================================
# STEP 2: Enable IP Forwarding
# ============================================================
echo "[2/8] Enabling IP forwarding..."
cat >> /etc/sysctl.conf <<EOF

# Enable IP forwarding for routing
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 0
EOF

sysctl -p

# ============================================================
# STEP 3: Configure Network Interfaces
# ============================================================
echo "[3/8] Configuring network interfaces..."

# Interface mapping from pfSense:
# WAN:  ens5  (10.0.1.0/24, DHCP)
# LAN:  ens6  (10.0.2.10/24)
# OPT1: ens7  (10.0.3.10/24)

cat > /etc/netplan/60-router.yaml <<'EOF'
network:
  version: 2
  ethernets:
    ens5:
      dhcp4: true
      dhcp6: false
    ens6:
      addresses:
        - 10.0.2.10/24
      dhcp4: false
      dhcp6: false
    ens7:
      addresses:
        - 10.0.3.10/24
      dhcp4: false
      dhcp6: false
EOF

netplan apply
sleep 5

# ============================================================
# STEP 4: Configure DHCP Server (dnsmasq)
# ============================================================
echo "[4/8] Configuring DHCP server..."

# Backup original
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup

cat > /etc/dnsmasq.conf <<'EOF'
# ============================================================
# DNSMASQ CONFIGURATION - Replaces pfSense DHCP+DNS
# ============================================================

# General settings
domain-needed
bogus-priv
no-resolv
no-poll
server=8.8.8.8
server=8.8.4.4

# Listen on LAN and OPT1 only (not WAN)
interface=ens6
interface=ens7
bind-interfaces

# Domain configuration
domain=cyberlab.local
local=/cyberlab.local/
expand-hosts

# DHCP for LAN (10.0.2.0/24)
dhcp-range=set:lan,10.0.2.100,10.0.2.200,255.255.255.0,12h
dhcp-option=tag:lan,option:router,10.0.2.10
dhcp-option=tag:lan,option:dns-server,10.0.2.10
dhcp-option=tag:lan,option:domain-name,cyberlab.local

# DHCP for OPT1 (10.0.3.0/24)
dhcp-range=set:opt1,10.0.3.100,10.0.3.200,255.255.255.0,12h
dhcp-option=tag:opt1,option:router,10.0.3.10
dhcp-option=tag:opt1,option:dns-server,10.0.3.10
dhcp-option=tag:opt1,option:domain-name,cyberlab.local

# DNS settings
cache-size=1000
dns-forward-max=150

# DNSSEC (like pfSense)
dnssec
trust-anchor=.,20326,8,2,E06D44B80B8F1D39A95C0B0D7C65D08458E880409BBC683457104237C7F8EC8D

# Logging
log-queries
log-dhcp

# DHCP authoritative
dhcp-authoritative
EOF

# Restart dnsmasq
systemctl enable dnsmasq
systemctl restart dnsmasq

# ============================================================
# STEP 5: Configure NAT/Firewall (iptables)
# ============================================================
echo "[5/8] Configuring NAT and firewall..."

# Clear existing rules
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# WAN interface (ens5) - Allow SSH and HTTPS from admin IP
# Note: admin_cidr will be replaced by Terraform
iptables -A INPUT -i ens5 -p tcp --dport 22 -s ${admin_cidr} -j ACCEPT
iptables -A INPUT -i ens5 -p tcp --dport 443 -s ${admin_cidr} -j ACCEPT

# LAN interface (ens6) - Allow all from LAN
iptables -A INPUT -i ens6 -j ACCEPT
iptables -A FORWARD -i ens6 -j ACCEPT

# OPT1 interface (ens7) - Allow all from OPT1
iptables -A INPUT -i ens7 -j ACCEPT
iptables -A FORWARD -i ens7 -j ACCEPT

# NAT for internet access (like pfSense)
iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE

# Save rules
iptables-save > /etc/iptables/rules.v4

# ============================================================
# STEP 6: Configure Snort IDS
# ============================================================
echo "[6/8] Configuring Snort IDS..."

# Configure Snort to listen on WAN interface
cat > /etc/snort/snort.debian.conf <<'EOF'
DEBIAN_SNORT_STARTUP="boot"
DEBIAN_SNORT_HOME_NET="10.0.0.0/8"
DEBIAN_SNORT_OPTIONS=""
DEBIAN_SNORT_INTERFACE="ens5"
EOF

# Update Snort configuration
sed -i 's/^ipvar HOME_NET .*/ipvar HOME_NET 10.0.0.0\/8/' /etc/snort/snort.conf
sed -i 's/^ipvar EXTERNAL_NET .*/ipvar EXTERNAL_NET any/' /etc/snort/snort.conf

# Enable community rules
if [ ! -d /etc/snort/rules ]; then
    mkdir -p /etc/snort/rules
fi

# Download community rules
cd /tmp
wget https://www.snort.org/downloads/community/community-rules.tar.gz -O community-rules.tar.gz 2>/dev/null || echo "Snort rules download may require manual setup"
if [ -f community-rules.tar.gz ]; then
    tar -xzf community-rules.tar.gz
    cp community-rules/*.rules /etc/snort/rules/ 2>/dev/null || true
fi

# Enable Snort service
systemctl enable snort
systemctl restart snort || echo "Snort will start after configuration"

# ============================================================
# STEP 7: Create Management Web Interface (HTTPS)
# ============================================================
echo "[7/8] Setting up HTTPS web management..."

# Install nginx for web interface
apt-get install -y nginx openssl

# Generate self-signed SSL certificate
echo "Generating self-signed SSL certificate..."
openssl req -x509 -nodes -days 3650 \
  -newkey rsa:2048 \
  -keyout /etc/ssl/private/router.key \
  -out /etc/ssl/certs/router.crt \
  -subj "/C=RO/ST=Sibiu/L=Sibiu/O=CyberLab/CN=router.cyberlab.local"

# Set proper permissions
chmod 600 /etc/ssl/private/router.key
chmod 644 /etc/ssl/certs/router.crt

# Configure nginx for HTTPS
cat > /etc/nginx/sites-available/default <<'EOF'
server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    
    ssl_certificate /etc/ssl/certs/router.crt;
    ssl_certificate_key /etc/ssl/private/router.key;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    
    root /var/www/html;
    index index.html;
    
    server_name _;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Ubuntu Router - Status</title>
    <style>
        body { font-family: Arial; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        .status { background: #e8f5e9; padding: 15px; border-radius: 4px; margin: 20px 0; }
        .info { background: #e3f2fd; padding: 15px; border-radius: 4px; margin: 20px 0; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f5f5f5; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Ubuntu Router Status</h1>
        
        <div class="status">
            <h2>✅ Router is Online</h2>
            <p>Ubuntu-based router replacing pfSense functionality</p>
        </div>

        <div class="info">
            <h2>Network Configuration</h2>
            <table>
                <tr><th>Interface</th><th>Network</th><th>IP Address</th><th>Service</th></tr>
                <tr><td>ens5 (WAN)</td><td>10.0.1.0/24</td><td>DHCP</td><td>Internet Gateway</td></tr>
                <tr><td>ens6 (LAN)</td><td>10.0.2.0/24</td><td>10.0.2.10</td><td>Kali Network</td></tr>
                <tr><td>ens7 (OPT1)</td><td>10.0.3.0/24</td><td>10.0.3.10</td><td>Ubuntu Network</td></tr>
            </table>
        </div>

        <div class="info">
            <h2>Services Running</h2>
            <ul>
                <li>✅ DHCP Server (dnsmasq) - LAN: 10.0.2.100-200, OPT1: 10.0.3.100-200</li>
                <li>✅ DNS Resolver (dnsmasq) - cyberlab.local</li>
                <li>✅ NAT/Routing (iptables)</li>
                <li>✅ Firewall (iptables)</li>
                <li>✅ Snort IDS (monitoring WAN)</li>
            </ul>
        </div>

        <div class="info">
            <h2>Access Information</h2>
            <p><strong>SSH:</strong> ssh -i lab-key.pem ubuntu@&lt;public-ip&gt;</p>
            <p><strong>Web Status:</strong> https://&lt;public-ip&gt;</p>
        </div>
    </div>
</body>
</html>
EOF

systemctl enable nginx
systemctl restart nginx

# ============================================================
# STEP 8: Final Configuration
# ============================================================
echo "[8/8] Final configuration..."

# Create status script
cat > /usr/local/bin/router-status.sh <<'EOF'
#!/bin/bash
echo "========================================"
echo "Ubuntu Router Status"
echo "========================================"
echo ""
echo "Network Interfaces:"
ip addr show | grep -E "ens[5-7]|inet "
echo ""
echo "Routing Table:"
ip route
echo ""
echo "Active DHCP Leases:"
cat /var/lib/misc/dnsmasq.leases 2>/dev/null || echo "No leases yet"
echo ""
echo "Firewall Rules:"
iptables -L -n -v --line-numbers | head -30
echo ""
echo "Services Status:"
systemctl status dnsmasq --no-pager -l 0 | grep Active
systemctl status snort --no-pager -l 0 | grep Active
systemctl status nginx --no-pager -l 0 | grep Active
echo ""
echo "========================================"
EOF

chmod +x /usr/local/bin/router-status.sh

# Add to ubuntu user's profile
echo "alias router-status='/usr/local/bin/router-status.sh'" >> /home/ubuntu/.bashrc

# Create completion marker
cat > /var/www/html/status.json <<EOF
{
  "service": "Ubuntu Router",
  "status": "configured",
  "timestamp": "$(date -Iseconds)",
  "features": ["DHCP", "DNS", "NAT", "Firewall", "Snort IDS"]
}
EOF

echo "========================================"
echo "✅ Ubuntu Router Setup Completed"
echo "Timestamp: $(date)"
echo ""
echo "Services configured:"
echo "  - IP Forwarding: Enabled"
echo "  - DHCP Server: LAN (10.0.2.100-200), OPT1 (10.0.3.100-200)"
echo "  - DNS Resolver: cyberlab.local (dnsmasq)"
echo "  - Firewall: iptables with NAT"
echo "  - Snort IDS: Monitoring WAN interface"
echo "  - Web Status: https://<public-ip>"
echo ""
echo "Check status: router-status"
echo "========================================"

# Reboot to ensure all changes take effect
echo "Rebooting in 10 seconds to apply all changes..."
sleep 10
reboot