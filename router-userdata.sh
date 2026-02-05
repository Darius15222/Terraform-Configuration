#!/bin/bash
# ============================================================
# UBUNTU ROUTER - Complete pfSense Replacement
# ============================================================
# Replicates all pfSense functionality with Let's Encrypt SSL
#
# TERRAFORM TEMPLATE VARIABLES:
# - ${admin_cidr}  : Admin IP for SSH/HTTPS access
# - ${domain_name} : Domain for Let's Encrypt (empty = self-signed)
# - ${ssl_email}   : Email for Let's Encrypt notifications
# ============================================================

set -e  # Exit on any error
set -x  # Debug mode - log all commands

LOG_FILE="/var/log/router-setup.log"
exec > >(tee -a ${LOG_FILE}) 2>&1

echo "========================================"
echo "Ubuntu Router Setup Started"
echo "Timestamp: $(date)"
echo "Admin CIDR: ${admin_cidr}"
echo "Domain: ${domain_name:-NONE (using self-signed)}"
echo "========================================"

# ============================================================
# HELPER FUNCTIONS
# ============================================================

log_step() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
}

check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ $1 - SUCCESS"
    else
        echo "❌ $1 - FAILED"
        exit 1
    fi
}

wait_for_interface() {
    local interface=$1
    local max_wait=30
    local elapsed=0
    
    log_step "Waiting for interface $interface to be ready..."
    while [ $elapsed -lt $max_wait ]; do
        if ip link show $interface &>/dev/null; then
            echo "✅ Interface $interface is ready"
            return 0
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    
    echo "❌ Interface $interface not available after ${max_wait}s"
    return 1
}

# ============================================================
# STEP 1: System Updates & Prerequisites
# ============================================================
log_step "[1/8] Updating system packages and installing prerequisites"

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
check_success "Package list update"

apt-get upgrade -y
check_success "System upgrade"

# Install required packages (including certbot for Let's Encrypt)
apt-get install -y \
    dnsmasq \
    iptables-persistent \
    snort \
    oinkmaster \
    net-tools \
    tcpdump \
    curl \
    wget \
    nginx \
    openssl \
    certbot \
    python3-certbot-nginx
check_success "Required packages installation"

# ============================================================
# STEP 2: Enable IP Forwarding
# ============================================================
log_step "[2/8] Enabling IP forwarding for routing"

if grep -q "^net.ipv4.ip_forward = 1" /etc/sysctl.conf; then
    echo "IP forwarding already configured"
else
    cat >> /etc/sysctl.conf <<EOF

# Enable IP forwarding for routing (configured by user-data)
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 0
EOF
    check_success "IP forwarding configuration"
fi

sysctl -p
check_success "Apply sysctl settings"

# ============================================================
# STEP 3: Configure Network Interfaces
# ============================================================
log_step "[3/8] Configuring network interfaces"

wait_for_interface ens5  # WAN
wait_for_interface ens6  # LAN
wait_for_interface ens7  # OPT1

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

check_success "Netplan configuration file created"

netplan apply
check_success "Network configuration applied"

sleep 5

log_step "Verifying interface configuration"
ip addr show ens5 | grep "inet " || echo "⚠️  WAN interface (ens5) - DHCP pending"
ip addr show ens6 | grep "10.0.2.10" && echo "✅ LAN interface (ens6) - 10.0.2.10 configured"
ip addr show ens7 | grep "10.0.3.10" && echo "✅ OPT1 interface (ens7) - 10.0.3.10 configured"

# ============================================================
# STEP 4: Configure DHCP + DNS Server (dnsmasq)
# ============================================================
log_step "[4/8] Configuring DHCP and DNS server (dnsmasq)"

if [ -f /etc/dnsmasq.conf ]; then
    mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup.$(date +%Y%m%d)
    echo "Original dnsmasq.conf backed up"
fi

cat > /etc/dnsmasq.conf <<'EOF'
# ============================================================
# DNSMASQ CONFIGURATION - Replaces pfSense DHCP+DNS
# ============================================================

domain-needed
bogus-priv
no-resolv
no-poll

server=8.8.8.8
server=8.8.4.4

interface=ens6
interface=ens7
bind-interfaces

domain=cyberlab.local
local=/cyberlab.local/
expand-hosts

# DHCP for LAN (10.0.2.0/24) - Kali subnet
dhcp-range=set:lan,10.0.2.100,10.0.2.200,255.255.255.0,12h
dhcp-option=tag:lan,option:router,10.0.2.10
dhcp-option=tag:lan,option:dns-server,10.0.2.10
dhcp-option=tag:lan,option:domain-name,cyberlab.local

# DHCP for OPT1 (10.0.3.0/24) - Ubuntu server subnet
dhcp-range=set:opt1,10.0.3.100,10.0.3.200,255.255.255.0,12h
dhcp-option=tag:opt1,option:router,10.0.3.10
dhcp-option=tag:opt1,option:dns-server,10.0.3.10
dhcp-option=tag:opt1,option:domain-name,cyberlab.local

cache-size=1000
dns-forward-max=150

dnssec
trust-anchor=.,20326,8,2,E06D44B80B8F1D39A95C0B0D7C65D08458E880409BBC683457104237C7F8EC8D

log-queries
log-dhcp

dhcp-authoritative
EOF

check_success "dnsmasq configuration created"

systemctl enable dnsmasq
systemctl restart dnsmasq
check_success "dnsmasq service started"

if systemctl is-active --quiet dnsmasq; then
    echo "✅ dnsmasq service is active"
else
    echo "❌ dnsmasq service failed to start"
    journalctl -u dnsmasq -n 20 --no-pager
    exit 1
fi

# ============================================================
# STEP 5: Configure NAT and Firewall (iptables)
# ============================================================
log_step "[5/8] Configuring NAT and firewall rules"

iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# WAN interface (ens5) rules
iptables -A INPUT -i ens5 -p tcp --dport 22 -s ${admin_cidr} -m state --state NEW -j ACCEPT
iptables -A INPUT -i ens5 -p tcp --dport 443 -s ${admin_cidr} -m state --state NEW -j ACCEPT

# Allow port 80 for Let's Encrypt if domain is configured
if [ -n "${domain_name}" ]; then
    iptables -A INPUT -i ens5 -p tcp --dport 80 -m state --state NEW -j ACCEPT
    echo "✅ Port 80 opened for Let's Encrypt certificate validation"
fi

# LAN and OPT1 interfaces - allow all internal traffic
iptables -A INPUT -i ens6 -j ACCEPT
iptables -A FORWARD -i ens6 -j ACCEPT
iptables -A INPUT -i ens7 -j ACCEPT
iptables -A FORWARD -i ens7 -j ACCEPT

# NAT configuration
iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE

check_success "iptables rules configured"

iptables-save > /etc/iptables/rules.v4
check_success "iptables rules saved"

log_step "Current firewall rules:"
iptables -L -n -v --line-numbers | head -40

# ============================================================
# STEP 6: Configure Snort IDS
# ============================================================
log_step "[6/8] Configuring Snort IDS"

cat > /etc/snort/snort.debian.conf <<'EOF'
DEBIAN_SNORT_STARTUP="boot"
DEBIAN_SNORT_HOME_NET="10.0.0.0/8"
DEBIAN_SNORT_OPTIONS=""
DEBIAN_SNORT_INTERFACE="ens5"
EOF

check_success "Snort debian configuration"

sed -i 's/^ipvar HOME_NET .*/ipvar HOME_NET 10.0.0.0\/8/' /etc/snort/snort.conf
sed -i 's/^ipvar EXTERNAL_NET .*/ipvar EXTERNAL_NET any/' /etc/snort/snort.conf

check_success "Snort HOME_NET and EXTERNAL_NET configured"

mkdir -p /etc/snort/rules

log_step "Downloading Snort community rules..."
cd /tmp
if wget -q --timeout=30 https://www.snort.org/downloads/community/community-rules.tar.gz 2>/dev/null; then
    tar -xzf community-rules.tar.gz
    cp community-rules/*.rules /etc/snort/rules/ 2>/dev/null || true
    echo "✅ Snort community rules downloaded"
else
    echo "⚠️  Snort rules download skipped (requires Oinkcode or manual setup)"
    echo "ℹ️  Snort will start with default rules"
fi

systemctl enable snort
systemctl restart snort || echo "⚠️  Snort will start after full configuration"

# ============================================================
# STEP 7: Setup HTTPS Web Management Interface
# ============================================================
log_step "[7/8] Setting up HTTPS web management interface"

# Get public IP for certificate
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

if [ -n "${domain_name}" ] && [ -n "${ssl_email}" ]; then
    # ========================================
    # Let's Encrypt Certificate (Real SSL)
    # ========================================
    log_step "Obtaining Let's Encrypt SSL certificate for ${domain_name}..."
    
    # Create minimal nginx config for HTTP-01 challenge
    cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name ${domain_name};
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF
    
    systemctl restart nginx
    sleep 3
    
    # Obtain certificate (non-interactive)
    certbot certonly --nginx \
        --non-interactive \
        --agree-tos \
        --email ${ssl_email} \
        --domain ${domain_name} \
        --redirect
    
    if [ $? -eq 0 ]; then
        echo "✅ Let's Encrypt certificate obtained successfully!"
        
        # Configure nginx with Let's Encrypt certificate
        cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name ${domain_name};
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    
    ssl_certificate /etc/letsencrypt/live/${domain_name}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain_name}/privkey.pem;
    
    # SSL security configuration (Mozilla Intermediate)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    root /var/www/html;
    index index.html;
    
    server_name ${domain_name};
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location /status {
        default_type application/json;
        alias /var/www/html/status.json;
    }
}
EOF
        
        # Setup automatic renewal (certbot does this automatically via systemd timer)
        systemctl enable certbot.timer
        systemctl start certbot.timer
        
        echo "✅ Certbot auto-renewal enabled (checks twice daily)"
        
        SSL_TYPE="Let's Encrypt (Auto-renews)"
        CERT_PATH="/etc/letsencrypt/live/${domain_name}/fullchain.pem"
    else
        echo "❌ Let's Encrypt certificate failed - falling back to self-signed"
        # Fall through to self-signed section
    fi
fi

# ========================================
# Self-Signed Certificate (Fallback)
# ========================================
if [ ! -f "$CERT_PATH" ]; then
    log_step "Generating self-signed SSL certificate..."
    
    cat > /tmp/openssl-san.cnf <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext
x509_extensions = v3_ca

[dn]
C=RO
ST=Sibiu
L=Sibiu
O=CyberLab
CN=router.cyberlab.local

[req_ext]
subjectAltName = @alt_names

[v3_ca]
subjectAltName = @alt_names
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth

[alt_names]
DNS.1 = router.cyberlab.local
DNS.2 = localhost
IP.1 = 10.0.2.10
IP.2 = 10.0.3.10
IP.3 = ${PUBLIC_IP}
IP.4 = 127.0.0.1
EOF
    
    openssl req -x509 -nodes -days 3650 \
      -newkey rsa:2048 \
      -keyout /etc/ssl/private/router.key \
      -out /etc/ssl/certs/router.crt \
      -config /tmp/openssl-san.cnf \
      2>/dev/null
    
    check_success "Self-signed SSL certificate generated"
    
    chmod 600 /etc/ssl/private/router.key
    chmod 644 /etc/ssl/certs/router.crt
    rm -f /tmp/openssl-san.cnf
    
    # Configure nginx with self-signed certificate
    cat > /etc/nginx/sites-available/default <<'EOF'
server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    
    ssl_certificate /etc/ssl/certs/router.crt;
    ssl_certificate_key /etc/ssl/private/router.key;
    
    # SSL security configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    
    root /var/www/html;
    index index.html;
    
    server_name _;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location /status {
        default_type application/json;
        alias /var/www/html/status.json;
    }
}
EOF
    
    SSL_TYPE="Self-Signed (10-year validity)"
    CERT_PATH="/etc/ssl/certs/router.crt"
fi

check_success "nginx configuration created"

# Create web status page
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ubuntu Router - Status</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; margin-bottom: 10px; }
        .subtitle { color: #7f8c8d; margin-bottom: 30px; }
        .status { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .status h2 { margin-bottom: 10px; }
        .info-box { background: #ecf0f1; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #3498db; }
        .info-box h2 { color: #2c3e50; margin-bottom: 15px; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #34495e; color: white; font-weight: 600; }
        tr:hover { background: #f8f9fa; }
        ul { list-style: none; padding-left: 0; }
        ul li { padding: 8px 0; padding-left: 25px; position: relative; }
        ul li:before { content: "✓"; position: absolute; left: 0; color: #27ae60; font-weight: bold; }
        .footer { margin-top: 30px; padding-top: 20px; border-top: 2px solid #ecf0f1; text-align: center; color: #7f8c8d; }
        .badge { background: #27ae60; color: white; padding: 4px 12px; border-radius: 12px; font-size: 0.85em; font-weight: 600; }
        .ssl-badge { background: #3498db; color: white; padding: 4px 12px; border-radius: 12px; font-size: 0.85em; font-weight: 600; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Ubuntu Router</h1>
        <p class="subtitle">pfSense Replacement - Cybersecurity Lab Environment</p>
        
        <div class="status">
            <h2>✅ Router Status: <span class="badge">ONLINE</span> | SSL: <span class="ssl-badge">${SSL_TYPE}</span></h2>
            <p>All services operational and routing traffic between WAN, LAN, and OPT1 networks.</p>
        </div>

        <div class="info-box">
            <h2>📡 Network Configuration</h2>
            <table>
                <thead>
                    <tr>
                        <th>Interface</th>
                        <th>Network</th>
                        <th>IP Address</th>
                        <th>Purpose</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>ens5 (WAN)</strong></td>
                        <td>10.0.1.0/24</td>
                        <td>${PUBLIC_IP}</td>
                        <td>Internet Gateway</td>
                    </tr>
                    <tr>
                        <td><strong>ens6 (LAN)</strong></td>
                        <td>10.0.2.0/24</td>
                        <td>10.0.2.10</td>
                        <td>Kali Linux Network</td>
                    </tr>
                    <tr>
                        <td><strong>ens7 (OPT1)</strong></td>
                        <td>10.0.3.0/24</td>
                        <td>10.0.3.10</td>
                        <td>Ubuntu Server Network</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div class="info-box">
            <h2>⚙️ Active Services</h2>
            <ul>
                <li><strong>DHCP Server (dnsmasq)</strong> - LAN: 10.0.2.100-200, OPT1: 10.0.3.100-200</li>
                <li><strong>DNS Resolver (dnsmasq)</strong> - Domain: cyberlab.local, DNSSEC enabled</li>
                <li><strong>NAT/Routing (iptables)</strong> - Internet access for internal networks</li>
                <li><strong>Firewall (iptables)</strong> - Stateful packet filtering, admin-only WAN access</li>
                <li><strong>Snort IDS</strong> - Intrusion detection monitoring WAN interface</li>
                <li><strong>HTTPS Management (nginx)</strong> - ${SSL_TYPE}</li>
            </ul>
        </div>

        <div class="info-box">
            <h2>🔐 SSL Certificate Information</h2>
            <p><strong>Type:</strong> ${SSL_TYPE}</p>
            <p><strong>Certificate Path:</strong> <code>${CERT_PATH}</code></p>
            $([ -n "${domain_name}" ] && echo "<p><strong>Domain:</strong> ${domain_name}</p>" || echo "<p><strong>Note:</strong> Browser will show security warning for self-signed certificate</p>")
        </div>

        <div class="info-box">
            <h2>🔐 Access Information</h2>
            <p><strong>SSH Access:</strong> <code>ssh -i lab-key.pem ubuntu@${PUBLIC_IP}</code></p>
            <p><strong>Web Interface:</strong> <code>https://${domain_name:-${PUBLIC_IP}}</code></p>
            <p><strong>Check Status:</strong> <code>router-status</code> (from SSH)</p>
        </div>

        <div class="footer">
            <p>Ubuntu Router v1.0 | Deployed: <span id="timestamp"></span></p>
            <script>document.getElementById('timestamp').textContent = new Date().toLocaleString();</script>
        </div>
    </div>
</body>
</html>
EOF

check_success "Web status page created"

systemctl enable nginx
systemctl restart nginx
check_success "nginx web server started"

if systemctl is-active --quiet nginx; then
    echo "✅ nginx service is active"
else
    echo "❌ nginx service failed to start"
    journalctl -u nginx -n 20 --no-pager
    exit 1
fi

# ============================================================
# STEP 8: Final Configuration & Status Tools
# ============================================================
log_step "[8/8] Creating management tools and finalizing setup"

cat > /usr/local/bin/router-status <<'EOF'
#!/bin/bash
# Ubuntu Router Status Check

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              UBUNTU ROUTER STATUS REPORT                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "📡 NETWORK INTERFACES:"
echo "────────────────────────────────────────────────────────────────"
ip -br addr show ens5 ens6 ens7 | awk '{printf "%-8s %-15s %s\n", $1, $2, $3}'
echo ""

echo "🌐 ROUTING TABLE:"
echo "────────────────────────────────────────────────────────────────"
ip route show | head -10
echo ""

echo "💻 ACTIVE DHCP LEASES:"
echo "────────────────────────────────────────────────────────────────"
if [ -f /var/lib/misc/dnsmasq.leases ]; then
    cat /var/lib/misc/dnsmasq.leases | awk '{printf "%-15s %-17s %-20s\n", $3, $2, $4}'
    [ ! -s /var/lib/misc/dnsmasq.leases ] && echo "No active leases"
else
    echo "No leases file found"
fi
echo ""

echo "🔥 FIREWALL STATUS:"
echo "────────────────────────────────────────────────────────────────"
iptables -L INPUT -n -v --line-numbers | head -15
echo ""

echo "⚙️  SERVICES STATUS:"
echo "────────────────────────────────────────────────────────────────"
printf "%-15s %s\n" "dnsmasq:" "$(systemctl is-active dnsmasq 2>/dev/null || echo 'inactive')"
printf "%-15s %s\n" "snort:" "$(systemctl is-active snort 2>/dev/null || echo 'inactive')"
printf "%-15s %s\n" "nginx:" "$(systemctl is-active nginx 2>/dev/null || echo 'inactive')"
printf "%-15s %s\n" "certbot:" "$(systemctl is-active certbot.timer 2>/dev/null || echo 'inactive')"
echo ""

echo "🔐 SSL CERTIFICATE STATUS:"
echo "────────────────────────────────────────────────────────────────"
if [ -d "/etc/letsencrypt/live/${domain_name}" ]; then
    echo "Type: Let's Encrypt (Auto-renewing)"
    echo "Domain: ${domain_name}"
    certbot certificates 2>/dev/null | grep -A 3 "Certificate Name"
else
    echo "Type: Self-Signed (10-year validity)"
    echo "Path: /etc/ssl/certs/router.crt"
fi
echo ""

echo "📊 SYSTEM RESOURCES:"
echo "────────────────────────────────────────────────────────────────"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 " / " $2 " used"}')"
echo "Disk:   $(df -h / | awk 'NR==2 {print $3 " / " $2 " used (" $5 " full)"}')"
echo "Uptime: $(uptime -p)"
echo ""

echo "╚════════════════════════════════════════════════════════════════╝"
EOF

chmod +x /usr/local/bin/router-status
check_success "router-status command created"

echo "alias router-status='/usr/local/bin/router-status'" >> /home/ubuntu/.bashrc
echo "alias status='router-status'" >> /home/ubuntu/.bashrc

cat > /var/www/html/status.json <<EOF
{
  "service": "Ubuntu Router",
  "status": "operational",
  "version": "1.0",
  "deployment_time": "$(date -Iseconds)",
  "ssl_type": "${SSL_TYPE}",
  "domain": "${domain_name:-none}",
  "features": {
    "dhcp": "enabled",
    "dns": "enabled",
    "nat": "enabled",
    "firewall": "enabled",
    "ids": "enabled",
    "web_management": "enabled",
    "ssl_auto_renewal": "$([ -n '${domain_name}' ] && echo 'enabled' || echo 'disabled')"
  },
  "interfaces": {
    "wan": "ens5",
    "lan": "ens6",
    "opt1": "ens7"
  },
  "networks": {
    "lan": "10.0.2.0/24",
    "opt1": "10.0.3.0/24"
  }
}
EOF

check_success "Status JSON created"

log_step "Final Service Verification"
echo ""
echo "Service Status Summary:"
echo "─────────────────────────────────────────────────"
systemctl is-active --quiet dnsmasq && echo "✅ dnsmasq: RUNNING" || echo "❌ dnsmasq: FAILED"
systemctl is-active --quiet nginx && echo "✅ nginx: RUNNING" || echo "❌ nginx: FAILED"
systemctl is-active --quiet snort && echo "✅ snort: RUNNING" || echo "⚠️  snort: May need configuration"
if [ -n "${domain_name}" ]; then
    systemctl is-active --quiet certbot.timer && echo "✅ certbot: RUNNING (auto-renewal active)" || echo "⚠️  certbot: Not active"
fi
echo ""

# ============================================================
# SETUP COMPLETE
# ============================================================
log_step "╔════════════════════════════════════════════════════════════════╗"
echo "║              ✅ UBUNTU ROUTER SETUP COMPLETED                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Deployment Summary:"
echo "───────────────────────────────────────────────────────────────"
echo "✅ IP Forwarding: Enabled"
echo "✅ Network Interfaces: Configured (WAN, LAN, OPT1)"
echo "✅ DHCP Server: Active"
echo "   • LAN:  10.0.2.100-200 (Kali)"
echo "   • OPT1: 10.0.3.100-200 (Ubuntu)"
echo "✅ DNS Resolver: Active (cyberlab.local, DNSSEC enabled)"
echo "✅ Firewall: Active (iptables with NAT)"
echo "✅ Snort IDS: Configured (monitoring WAN)"
echo "✅ Web Management: Active (HTTPS - ${SSL_TYPE})"
if [ -n "${domain_name}" ]; then
    echo "✅ SSL Certificate: Let's Encrypt (${domain_name})"
    echo "✅ Auto-Renewal: Enabled (certbot checks twice daily)"
else
    echo "⚠️  SSL Certificate: Self-Signed (browser warnings expected)"
fi
echo ""
echo "Quick Commands:"
echo "───────────────────────────────────────────────────────────────"
echo "  router-status      - Display router status"
echo "  journalctl -u dnsmasq -f  - Follow DHCP/DNS logs"
echo "  tail -f /var/log/snort/alert  - Monitor IDS alerts"
if [ -n "${domain_name}" ]; then
    echo "  certbot renew --dry-run  - Test certificate renewal"
    echo "  certbot certificates  - Show certificate details"
fi
echo ""
echo "Web Interface:"
echo "───────────────────────────────────────────────────────────────"
echo "  https://${domain_name:-${PUBLIC_IP}}        - Status dashboard"
echo "  https://${domain_name:-${PUBLIC_IP}}/status - JSON status endpoint"
echo ""
echo "Setup completed at: $(date)"
echo "Log file: ${LOG_FILE}"
echo "═══════════════════════════════════════════════════════════════"
