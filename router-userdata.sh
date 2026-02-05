#!/bin/bash
# ============================================================
# UBUNTU ROUTER - Network Services Configuration
# ============================================================

set -e
set -x

# We use simple variables ($LOG_FILE) so Terraform ignores them.
LOG_FILE="/var/log/router-setup.log"
exec > >(tee -a $LOG_FILE) 2>&1

echo "========================================"
echo "Ubuntu Router Setup Started"
echo "Timestamp: $(date)"

# [TERRAFORM VARS] We keep braces here because we WANT Terraform to fill these in
echo "Admin CIDR: ${admin_cidr}"

if [ -z "${domain_name}" ]; then
    echo "Domain: NONE (using self-signed)"
else
    echo "Domain: ${domain_name}"
fi
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
    
    # Using $max_wait without braces
    echo "❌ Interface $interface not available after $max_wait seconds"
    return 1
}

# ============================================================
# STEP 1: System Updates
# ============================================================
log_step "[1/8] Updating system packages"

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y
apt-get install -y dnsmasq iptables-persistent snort oinkmaster net-tools tcpdump curl wget nginx openssl certbot python3-certbot-nginx
check_success "System update and install"

# ============================================================
# STEP 2: Enable IP Forwarding
# ============================================================
log_step "[2/8] Enabling IP forwarding"

if grep -q "^net.ipv4.ip_forward = 1" /etc/sysctl.conf; then
    echo "IP forwarding already configured"
else
    cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 0
EOF
fi

sysctl -p
check_success "IP forwarding enabled"

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
      addresses: [10.0.2.10/24]
      dhcp4: false
    ens7:
      addresses: [10.0.3.10/24]
      dhcp4: false
EOF

netplan apply
sleep 5
check_success "Network configuration applied"

# ============================================================
# STEP 4: Configure DHCP + DNS (dnsmasq)
# ============================================================
log_step "[4/8] Configuring DHCP and DNS"

if [ -f /etc/dnsmasq.conf ]; then
    mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup
fi

cat > /etc/dnsmasq.conf <<'EOF'
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

# DHCP Ranges
dhcp-range=set:lan,10.0.2.100,10.0.2.200,255.255.255.0,12h
dhcp-option=tag:lan,option:router,10.0.2.10
dhcp-option=tag:lan,option:dns-server,10.0.2.10

dhcp-range=set:opt1,10.0.3.100,10.0.3.200,255.255.255.0,12h
dhcp-option=tag:opt1,option:router,10.0.3.10
dhcp-option=tag:opt1,option:dns-server,10.0.3.10

log-queries
log-dhcp
dhcp-authoritative
EOF

systemctl restart dnsmasq
check_success "dnsmasq configured"

# ============================================================
# STEP 5: Firewall (iptables)
# ============================================================
log_step "[5/8] Configuring Firewall"

iptables -F
iptables -t nat -F
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# [TERRAFORM VAR] Allow Admin Access
iptables -A INPUT -i ens5 -p tcp --dport 22 -s ${admin_cidr} -j ACCEPT
iptables -A INPUT -i ens5 -p tcp --dport 443 -s ${admin_cidr} -j ACCEPT

# Allow HTTP for Let's Encrypt validation
iptables -A INPUT -i ens5 -p tcp --dport 80 -j ACCEPT

# Allow LAN/OPT1
iptables -A INPUT -i ens6 -j ACCEPT
iptables -A FORWARD -i ens6 -j ACCEPT
iptables -A INPUT -i ens7 -j ACCEPT
iptables -A FORWARD -i ens7 -j ACCEPT

# NAT
iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE

iptables-save > /etc/iptables/rules.v4
check_success "Firewall rules applied"

# ============================================================
# STEP 6: Snort IDS
# ============================================================
log_step "[6/8] Configuring Snort"

cat > /etc/snort/snort.debian.conf <<'EOF'
DEBIAN_SNORT_STARTUP="boot"
DEBIAN_SNORT_HOME_NET="10.0.0.0/8"
DEBIAN_SNORT_INTERFACE="ens5"
EOF

sed -i 's/^ipvar HOME_NET .*/ipvar HOME_NET 10.0.0.0\/8/' /etc/snort/snort.conf
sed -i 's/^ipvar EXTERNAL_NET .*/ipvar EXTERNAL_NET any/' /etc/snort/snort.conf

systemctl restart snort || echo "Snort restart deferred"

# ============================================================
# STEP 7: Web Interface & SSL
# ============================================================
log_step "[7/8] Configuring Web Interface"

# Using $PUBLIC_IP (no braces)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
CERT_PATH=""

if [ -n "${domain_name}" ] && [ -n "${ssl_email}" ]; then
    log_step "Attempting Let's Encrypt SSL..."
    
    # Nginx config - variables are escaped with slash
    cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80 default_server;
    server_name ${domain_name};
    location /.well-known/acme-challenge/ { root /var/www/html; }
    location / { return 301 https://\$host\$request_uri; }
}
EOF
    systemctl restart nginx
    
    certbot certonly --nginx --non-interactive --agree-tos --email ${ssl_email} --domain ${domain_name}
    
    if [ $? -eq 0 ]; then
        CERT_PATH="/etc/letsencrypt/live/${domain_name}/fullchain.pem"
        
        # SSL Config
        cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80 default_server;
    server_name ${domain_name};
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl default_server;
    server_name ${domain_name};
    ssl_certificate /etc/letsencrypt/live/${domain_name}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain_name}/privkey.pem;
    root /var/www/html;
    index index.html;
    location / { try_files \$uri \$uri/ =404; }
}
EOF
    fi
fi

# Fallback to Self-Signed
if [ ! -f "$CERT_PATH" ]; then
    log_step "Generating Self-Signed Cert..."
    
    # Using $PUBLIC_IP
    cat > /tmp/san.cnf <<EOF
[req]
distinguished_name = dn
req_extensions = req_ext
x509_extensions = v3_ca
prompt = no
[dn]
CN = router.local
[req_ext]
subjectAltName = @alt_names
[v3_ca]
subjectAltName = @alt_names
[alt_names]
IP.1 = $PUBLIC_IP
IP.2 = 10.0.2.10
IP.3 = 10.0.3.10
EOF
    
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
      -keyout /etc/ssl/private/router.key \
      -out /etc/ssl/certs/router.crt \
      -config /tmp/san.cnf 2>/dev/null
      
    cat > /etc/nginx/sites-available/default <<'EOF'
server {
    listen 443 ssl default_server;
    ssl_certificate /etc/ssl/certs/router.crt;
    ssl_certificate_key /etc/ssl/private/router.key;
    root /var/www/html;
    index index.html;
    server_name _;
    location / { try_files $uri $uri/ =404; }
}
EOF
fi

echo "Router Operational" > /var/www/html/index.html
systemctl restart nginx

# ============================================================
# STEP 8: Final Status Script
# ============================================================
cat > /usr/local/bin/router-status <<'EOF'
#!/bin/bash
echo "Network:"
ip -br addr show ens5 ens6 ens7
echo "Services:"
systemctl is-active dnsmasq snort nginx
EOF
chmod +x /usr/local/bin/router-status

log_step "Setup Complete"