#!/bin/bash
# ============================================================
# UBUNTU SERVER - JUICESHOP DEPLOYMENT
# ============================================================
# Deploys OWASP JuiceShop vulnerable web application
# Educational target for penetration testing exercises
# ============================================================

set -e  # Exit on any error
set -x  # Debug mode - log all commands

LOG_FILE="/var/log/userdata.log"
exec > >(tee -a ${LOG_FILE}) 2>&1

echo "========================================"
echo "Ubuntu Server Setup Started"
echo "Timestamp: $(date)"
echo "========================================"

# Update system packages
echo "[1/5] Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# Install Docker prerequisites
echo "[2/5] Installing Docker prerequisites..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo "[3/5] Configuring Docker repository..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
echo "[4/5] Installing Docker Engine..."
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker service
systemctl enable docker
systemctl start docker

# Verify Docker installation
docker --version

# Deploy OWASP JuiceShop
echo "[5/5] Deploying OWASP JuiceShop..."
docker run -d \
  --name juiceshop \
  --restart unless-stopped \
  -p 3000:3000 \
  -e NODE_ENV=unsafe \
  bkimminich/juice-shop:latest

# Wait for container to be healthy
echo "Waiting for JuiceShop to start..."
sleep 10

# Verify JuiceShop is running
if docker ps | grep -q juiceshop; then
    echo "✅ JuiceShop container is running"
    docker logs juiceshop | tail -20
else
    echo "❌ JuiceShop container failed to start"
    docker logs juiceshop
    exit 1
fi

# Test JuiceShop accessibility
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ JuiceShop is accessible on port 3000"
else
    echo "⚠️  JuiceShop container running but not responding yet (may need more time)"
fi

# Create status file for monitoring
cat > /var/www/html/status.json <<EOF
{
  "service": "JuiceShop",
  "status": "running",
  "port": 3000,
  "container": "$(docker ps --filter name=juiceshop --format '{{.ID}}')",
  "deployed_at": "$(date -Iseconds)"
}
EOF

echo "========================================"
echo "✅ Ubuntu Server Setup Completed"
echo "Timestamp: $(date)"
echo "Services:"
echo "  - Docker: $(docker --version)"
echo "  - JuiceShop: http://$(hostname -I | awk '{print $1}'):3000"
echo "========================================"
