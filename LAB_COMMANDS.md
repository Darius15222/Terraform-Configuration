## 📋 INSTANCE INFORMATION

```
INSTANCE IDs:
  Router: i-0de2c457331324932
  Kali:   i-021f1421bd412336f
  Ubuntu: i-07f9820e0c3d0349e

IP ADDRESSES:
  Router Public:   18.159.181.174
  Router LAN:      10.0.2.10
  Router OPT:      10.0.3.10
  Kali Private:    10.0.2.100
  Ubuntu Private:  10.0.3.100

SERVICES:
  Router Web:  https://18.159.181.174
  JuiceShop:   http://10.0.3.100:3000
  CyberChef:   http://localhost:8000 (from Kali browser)
```

---

## 🔄 UPDATE ADMIN IP (When Location Changes)

### Change Admin IP Before Presentation

```powershell
# 1. Get your new IP
curl https://checkip.amazonaws.com

# 2. Edit terraform.tfvars
notepad terraform.tfvars
# Change: admin_cidr = "NEW_IP/32"

# 3. Verify what will change
terraform plan

# 4. Apply (only updates security group - instances NOT touched)
terraform apply -auto-approve

# 5. Test access
curl -k https://18.159.181.174
```

---

## 🔐 SSH ACCESS COMMANDS

### Access Router
```powershell
ssh -i ./lab-key.pem ubuntu@18.159.181.174
```

### Access Kali (via Jump Host)
```powershell
ssh -i ./lab-key.pem -J ubuntu@18.159.181.174 kali@10.0.2.100
```

### Access Ubuntu (via Jump Host)
```powershell
ssh -i ./lab-key.pem -J ubuntu@18.159.181.174 ubuntu@10.0.3.100
```

### Alternative: ProxyCommand Method
```powershell
# Kali
ssh -o ProxyCommand="ssh -i ./lab-key.pem -W %h:%p ubuntu@18.159.181.174" -i ./lab-key.pem kali@10.0.2.100

# Ubuntu
ssh -o ProxyCommand="ssh -i ./lab-key.pem -W %h:%p ubuntu@18.159.181.174" -i ./lab-key.pem ubuntu@10.0.3.100
```

---

## 🌐 WEB INTERFACE ACCESS

### Router Web Interface
```
URL:      https://18.159.181.174
Access:   From admin IP only
Status:   router-status (via SSH)
```

### JuiceShop (from Kali browser or Router shell)
```
URL: http://10.0.3.100:3000
```

### CyberChef (from Kali browser only)
```
URL: http://localhost:8000
```

---

## ⚡ INSTANCE MANAGEMENT

### Start All Instances
```powershell
aws ec2 start-instances --instance-ids i-0de2c457331324932 i-021f1421bd412336f i-07f9820e0c3d0349e
```

### Stop All Instances (Save Money!)
```powershell
aws ec2 stop-instances --instance-ids i-0de2c457331324932 i-021f1421bd412336f i-07f9820e0c3d0349e
```

### Check Instance Status
```powershell
# All instances
aws ec2 describe-instances --instance-ids i-0de2c457331324932 i-021f1421bd412336f i-07f9820e0c3d0349e --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name}'

# Single instance state
aws ec2 describe-instances --instance-ids i-0de2c457331324932 --query 'Reservations[0].Instances[0].State.Name'
```

---

## 🔍 VERIFICATION COMMANDS

### From Kali
```bash
# Check routing (CRITICAL - must use Router gateway)
ip route show
# Expected: default via 10.0.2.10 dev eth0 ✅
# Wrong: default via 10.0.2.1 dev eth0 ❌

# Fix routing if needed
sudo ip route del default via 10.0.2.1
sudo ip route add default via 10.0.2.10 dev eth0

# Test internet through Router
ping -c 3 8.8.8.8

# Check Docker containers (Docker pre-installed in AMI)
docker ps

# Test CyberChef locally
curl http://localhost:8000 | head -20

# Test JuiceShop access
curl http://10.0.3.100:3000 | head -20

# Check network configuration
ip addr show

# Test DNS (after Router configured)
nslookup google.com

# Note: user-data log will show failures (expected - no internet during boot)
# Docker was pre-installed, so CyberChef still deployed
tail -50 /var/log/userdata.log
```

### From Ubuntu
```bash
# Check Docker containers (use sudo first time, or add to group)
sudo docker ps
# OR add to group permanently:
sudo usermod -aG docker ubuntu
# Then logout/login

# Check JuiceShop logs (shows successful attacks)
docker logs juiceshop | grep "Solved"

# Test JuiceShop locally
curl http://localhost:3000 | head -20

# Check Docker service
systemctl status docker

# Note: user-data log will show failures (expected - no internet during boot)
# Docker was pre-installed, so JuiceShop still deployed
tail -50 /var/log/userdata.log
```

### From Router Shell
```bash
# Check router status
router-status

# Test connectivity
ping -c 3 10.0.2.100  # Kali
ping -c 3 10.0.3.100  # Ubuntu

# Test services
curl http://10.0.3.100:3000 | head -30      # JuiceShop
curl http://10.0.2.100:8000 | head -30      # CyberChef

# Test if ports are open
nc -zv 10.0.3.100 3000  # JuiceShop
nc -zv 10.0.2.100 8000  # CyberChef

# Check HTTP response
curl -I http://10.0.3.100:3000

# Check DHCP leases
cat /var/lib/misc/dnsmasq.leases

# View firewall rules
iptables -L -n -v

# View NAT rules
iptables -t nat -L -n -v

# Check DNS resolution
nslookup google.com

# Monitor Snort alerts
tail -f /var/log/snort/alert
```

---

## 🐳 DOCKER MANAGEMENT

### Kali - CyberChef

```bash
# List containers
docker ps

# View logs
docker logs cyberchef

# Follow logs in real-time
docker logs -f cyberchef

# Restart container
docker restart cyberchef

# Stop container
docker stop cyberchef

# Start container
docker start cyberchef

# Check container status
docker inspect cyberchef | grep Status
```

### Ubuntu - JuiceShop

```bash
# List containers
docker ps

# View logs
docker logs juiceshop

# View last 50 lines
docker logs --tail 50 juiceshop

# Follow logs in real-time
docker logs -f juiceshop

# Restart container
docker restart juiceshop

# Stop container
docker stop juiceshop

# Start container
docker start juiceshop

# Remove and recreate container
docker rm -f juiceshop
docker run -d --name juiceshop --restart unless-stopped -p 3000:3000 -e NODE_ENV=unsafe bkimminich/juice-shop:latest
```

---

## 🔥 ROUTER OPERATIONS

### Router Management Commands (via SSH)

```bash
# Check router status
router-status

# Restart services
sudo systemctl restart dnsmasq    # DHCP + DNS
sudo systemctl restart nginx      # Web interface
sudo systemctl restart snort      # IDS

# View service status
systemctl status dnsmasq
systemctl status nginx
systemctl status snort

# Check DHCP leases
cat /var/lib/misc/dnsmasq.leases

# View firewall rules
sudo iptables -L -n -v

# View NAT rules
sudo iptables -t nat -L -n -v

# View routing table
ip route show

# Check interface status
ip addr show

# Monitor dnsmasq logs
sudo journalctl -u dnsmasq -f

# Monitor Snort alerts
sudo tail -f /var/log/snort/alert

# View router setup log
cat /var/log/router-setup.log
```

### SSL Certificate Management (if using Let's Encrypt)

```bash
# Show certificate details
sudo certbot certificates

# Test renewal (dry run)
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal

# Check auto-renewal timer
systemctl status certbot.timer

# View renewal logs
journalctl -u certbot.timer
```

---

## 🧪 ATTACK SCENARIOS & TRAFFIC CAPTURE

### SQL Injection Attack

**Method 1: Browser (Kali GUI)**
```
Open: http://10.0.3.100:3000
Login with: ' OR 1=1--
Password: anything
```

**Method 2: Command Line (Kali)**
```bash
curl -X POST http://10.0.3.100:3000/rest/user/login \
  -H "Content-Type: application/json" \
  -d '{"email":"'\'' OR 1=1--","password":"test"}'
```

---

### Complete Traffic Capture Workflow

**Step 1: Capture on Kali**
```bash
# Start capture
sudo tcpdump -i eth0 -w /tmp/sql_injection.pcap host 10.0.3.100 and port 3000 &
sleep 2

# Perform attack
curl -X POST http://10.0.3.100:3000/rest/user/login \
  -H "Content-Type: application/json" \
  -d '{"email":"'\'' OR 1=1--","password":"anything"}'
sleep 2

# Stop capture
sudo pkill tcpdump

# Copy to home
sudo cp /tmp/sql_injection.pcap /home/kali/
sudo chown kali:kali /home/kali/sql_injection.pcap
```

**Step 2: Download to Windows**
```powershell
scp -o ProxyCommand="ssh -i ./lab-key.pem -W %h:%p ubuntu@18.159.181.174" -i ./lab-key.pem kali@10.0.2.100:/home/kali/sql_injection.pcap ./sql_injection.pcap
```

**Step 3: Analyze in Wireshark**
```
1. Open Wireshark → File → Open → sql_injection.pcap
2. Right-click POST packet → Follow → HTTP Stream
3. Screenshot SQL injection payload and admin JWT response
```

**Common Wireshark Filters:**
- `http` - Show HTTP traffic only
- `http.request.method == "POST"` - POST requests
- `http contains "OR 1=1"` - Find SQL injection
- `tcp.port == 3000` - JuiceShop traffic only

---

## 📊 MONITORING COMMANDS

### Check User-Data Script Status

```bash
# On Kali or Ubuntu
tail -100 /var/log/userdata.log

# Real-time monitoring
tail -f /var/log/userdata.log

# Check for completion
grep "Setup Completed" /var/log/userdata.log

# Check for errors
grep -i error /var/log/userdata.log
```

### Router Setup Status

```bash
# On Router
tail -100 /var/log/router-setup.log

# Real-time monitoring
tail -f /var/log/router-setup.log

# Check for completion
grep "SETUP COMPLETED" /var/log/router-setup.log
```

### System Resources

```bash
# CPU and memory usage
top

# Disk usage
df -h

# Memory usage
free -h

# Open ports
netstat -tulpn

# Active connections
netstat -an | grep ESTABLISHED
```

---

## 📁 FILE TRANSFER

### Copy FROM Instance to Local

```powershell
# From Router (direct, no jump needed)
scp -i ./lab-key.pem ubuntu@18.159.181.174:/path/to/file ./local-file

# From Kali (via Router jump)
scp -o ProxyCommand="ssh -i ./lab-key.pem -W %h:%p ubuntu@18.159.181.174" -i ./lab-key.pem kali@10.0.2.100:/path/to/file ./local-file

# From Ubuntu (via Router jump)
scp -o ProxyCommand="ssh -i ./lab-key.pem -W %h:%p ubuntu@18.159.181.174" -i ./lab-key.pem ubuntu@10.0.3.100:/path/to/file ./local-file
```

### Copy TO Instance from Local
```powershell
# To Router
scp -i ./lab-key.pem ./local-file ubuntu@18.159.181.174:/tmp/

# To Kali (via Router jump)
scp -o ProxyCommand="ssh -i ./lab-key.pem -W %h:%p ubuntu@18.159.181.174" -i ./lab-key.pem ./local-file kali@10.0.2.100:/tmp/

# To Ubuntu (via Router jump)
scp -o ProxyCommand="ssh -i ./lab-key.pem -W %h:%p ubuntu@18.159.181.174" -i ./lab-key.pem ./local-file ubuntu@10.0.3.100:/tmp/
```

---

## 🔧 TROUBLESHOOTING

### Fix SSH Key Permissions (Windows)

```powershell
# Remove all permissions
icacls "lab-key.pem" /inheritance:r

# Grant only your user read access
icacls "lab-key.pem" /grant:r "$($env:USERNAME):(R)"

# Verify
icacls "lab-key.pem"
```

### Can't Access Router Web Interface

```powershell
# Check if instance is running
aws ec2 describe-instances --instance-ids i-0de2c457331324932 --query 'Reservations[0].Instances[0].State.Name'

# Check your current IP
curl https://checkip.amazonaws.com

# Update security group if IP changed (see "Update Admin IP" section)
```

### JuiceShop Not Responding

```bash
# SSH to Ubuntu
ssh -i ./lab-key.pem -J ubuntu@18.159.181.174 ubuntu@10.0.3.100

# Check container status
docker ps

# If not running, check logs
docker logs juiceshop

# Restart container
docker restart juiceshop

# If still not working, recreate container
docker rm -f juiceshop
docker run -d --name juiceshop --restart unless-stopped -p 3000:3000 bkimminich/juice-shop
```

### CyberChef Not Responding

```bash
# SSH to Kali
ssh -i ./lab-key.pem -J ubuntu@18.159.181.174 kali@10.0.2.100

# Check container status
docker ps

# Restart container
docker restart cyberchef

# Test locally
curl http://localhost:8000
```

### No Internet from Kali/Ubuntu

```bash
# On affected instance, check routing
ip route show
# Should show: default via 10.0.2.10 (Kali) or 10.0.3.10 (Ubuntu)

# Check DNS
nslookup google.com
# Should use Router IP as DNS server

# On Router, check NAT rules
sudo iptables -t nat -L -n -v
# Should see MASQUERADE rule for WAN interface
```

---

## 💾 BACKUP & RESTORE

### Backup Router Configuration

```bash
# SSH to Router
ssh -i ./lab-key.pem ubuntu@18.159.181.174

# Backup dnsmasq config
sudo cp /etc/dnsmasq.conf ~/dnsmasq.conf.backup

# Backup firewall rules
sudo iptables-save > ~/iptables.backup

# Backup Snort config
sudo cp /etc/snort/snort.conf ~/snort.conf.backup

# Download backups to local machine
# Exit SSH, then:
scp -i ./lab-key.pem ubuntu@18.159.181.174:~/*.backup ./
```

### Restore Router Configuration

```bash
# SSH to Router
ssh -i ./lab-key.pem ubuntu@18.159.181.174

# Restore dnsmasq
sudo cp ~/dnsmasq.conf.backup /etc/dnsmasq.conf
sudo systemctl restart dnsmasq

# Restore firewall rules
sudo iptables-restore < ~/iptables.backup
sudo iptables-save > /etc/iptables/rules.v4

# Restore Snort
sudo cp ~/snort.conf.backup /etc/snort/snort.conf
sudo systemctl restart snort
```

---

## 📊 TERRAFORM OPERATIONS

### Get Outputs

```powershell
# All outputs
terraform output

# Specific outputs
terraform output router_public_ip
terraform output kali_private_ip
terraform output ubuntu_private_ip
terraform output ssh_commands
terraform output network_architecture
```

### Refresh State

```powershell
# Refresh Terraform state
terraform refresh

# View current state
terraform show

# List resources
terraform state list
```

### Destroy Infrastructure (Careful!)

```powershell
# Preview what will be destroyed
terraform plan -destroy

# Destroy everything (CAREFUL!)
terraform destroy

# Auto-approve (skip confirmation)
terraform destroy -auto-approve
```

---

## 🚀 WORKFLOWS

### Daily Startup Workflow

```powershell
# 1. Start instances
aws ec2 start-instances --instance-ids i-0de2c457331324932 i-021f1421bd412336f i-07f9820e0c3d0349e

# 2. Wait 2-3 minutes

# 3. Get Router IP (if it changed)
terraform output router_public_ip

# 4. Access Router web interface
# Open browser: https://18.159.181.174

# 5. Verify services
# SSH to Router and test JuiceShop:
ssh -i ./lab-key.pem ubuntu@18.159.181.174
curl http://10.0.3.100:3000
```

### Daily Shutdown Workflow

```powershell
# Stop all instances to save money
aws ec2 stop-instances --instance-ids i-0de2c457331324932 i-021f1421bd412336f i-07f9820e0c3d0349e

# Verify they're stopping
aws ec2 describe-instances --instance-ids i-0de2c457331324932 i-021f1421bd412336f i-07f9820e0c3d0349e --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name}'
```

### Quick Lab Verification

```bash
# From Router shell (after SSH):

# 1. Test connectivity
ping -c 3 10.0.2.100 && ping -c 3 10.0.3.100

# 2. Test JuiceShop
curl -I http://10.0.3.100:3000

# 3. If you see "HTTP/1.1 200 OK" - Lab is ready! ✅
```

### Presentation Day Workflow

```powershell
# 1. Get your current IP at venue
curl https://checkip.amazonaws.com

# 2. Update terraform.tfvars
# Change: admin_cidr = "NEW_IP/32"

# 3. Apply changes
terraform apply -auto-approve

# 4. Start instances if stopped
aws ec2 start-instances --instance-ids i-0de2c457331324932 i-021f1421bd412336f i-07f9820e0c3d0349e

# 5. Wait 3 minutes, then access
# Browser: https://18.159.181.174
```

---

## 🎓 COURSEWORK EVIDENCE COLLECTION

### Collect Evidence

```bash
# From Kali - Export Wireshark capture
# File → Export Packet Dissections → As Plain Text
# Save as: sqlinjection_capture.txt

# From Router - Export Snort alerts
sudo cp /var/log/snort/alert ~/snort_alerts.log

# From Kali - Screenshot Burp Suite
# Take screenshot of intercepted request

# From Kali - Screenshot CyberChef
# Take screenshot of decoded JWT
```

### Generate Reports

```powershell
# Export Terraform configuration documentation
terraform output > lab_deployment_info.txt

# Export network architecture
terraform output network_architecture > network_diagram.txt

# List all resources
terraform state list > terraform_resources.txt
```

---

## 💰 COST MONITORING

### Check Current Costs

```powershell
# Get current month's costs
aws ce get-cost-and-usage `
  --time-period Start=2026-02-01,End=2026-03-01 `
  --granularity MONTHLY `
  --metrics BlendedCost
```

---

## 📝 NOTES

- Router configurations persist across stop/start
- Docker containers auto-restart on instance boot
- Always stop instances when not in use to minimize costs
- DHCP/DNS/NAT configured automatically via user-data
- Snort IDS requires manual rule configuration for advanced detection
