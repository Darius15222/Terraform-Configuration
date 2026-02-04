## 📋 INSTANCE INFORMATION

```
INSTANCE IDs:
  pfSense: i-0de2c457331324932
  Kali:    i-021f1421bd412336f
  Ubuntu:  i-07f9820e0c3d0349e

IP ADDRESSES:
  pfSense Public:  18.159.181.174
  pfSense LAN:     10.0.2.10
  pfSense OPT:     10.0.3.10
  Kali Private:    10.0.2.100
  Ubuntu Private:  10.0.3.100

SERVICES:
  pfSense Web:  https://18.159.181.174
  JuiceShop:    http://10.0.3.100:3000
  CyberChef:    http://localhost:8000 (from Kali browser)
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

### Access pfSense
```powershell
ssh -i ./lab-key.pem admin@18.159.181.174
```

### Access Kali
```powershell
# Step 1: SSH to pfSense
ssh -i /root/.ssh/lab-key.pem kali@10.0.2.100

# Step 2: Choose option 8 (Shell)
# Type: 8

# Step 3: SSH to Kali from pfSense
ssh kali@10.0.2.100
```

### Access Ubuntu
```powershell
# Step 1: SSH to pfSense
ssh -i /root/.ssh/lab-key.pem ubuntu@10.0.3.100

# Step 2: Choose option 8 (Shell)
# Type: 8

# Step 3: SSH to Ubuntu from pfSense
ssh ubuntu@10.0.3.100
```

### Alternative: Jump Host Method
```powershell
# Kali
ssh -o ProxyCommand="ssh -i ./lab-key.pem -W %h:%p admin@18.159.181.174" -i ./lab-key.pem kali@10.0.2.100

# Ubuntu
ssh -o ProxyCommand="ssh -i ./lab-key.pem -W %h:%p admin@18.159.181.174" -i ./lab-key.pem ubuntu@10.0.3.100
```

---

## 🌐 WEB INTERFACE ACCESS

### pfSense Web Interface
```
URL:      https://18.159.181.174
Username: admin
Password: [your-password]
```

### JuiceShop (from Kali browser or pfSense shell)
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

##  🔍 VERIFICATION COMMANDS

### From Kali
```bash
# Check routing (CRITICAL - must use pfSense gateway)
ip route show
# Expected: default via 10.0.2.10 dev eth0 ✅
# Wrong: default via 10.0.2.1 dev eth0 ❌

# Fix routing if needed
sudo ip route del default via 10.0.2.1
sudo ip route add default via 10.0.2.10 dev eth0

# Test internet through pfSense
ping -c 3 8.8.8.8

# Check Docker containers (Docker pre-installed in AMI)
docker ps

# Test CyberChef locally
curl http://localhost:8000 | head -20

# Test JuiceShop access
curl http://10.0.3.100:3000 | head -20

# Check network configuration
ip addr show

# Test DNS (after pfSense configured)
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

### From pfSense Shell
```bash
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
```

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

## 🔥 PFSENSE OPERATIONS

### pfSense Menu Options (via SSH)

```
0)  Logout
1)  Assign Interfaces
2)  Set interface IP address
3)  Reset admin password
4)  Reset to factory defaults
5)  Reboot system
6)  Halt system
7)  Ping host
8)  Shell (access command line)
11) Restart GUI
```

### pfSense Shell Commands

```bash
# Restart web interface
pfSsh.php playback restartgui

# Check interface status
ifconfig

# View active firewall rules
pfctl -sr

# View firewall states
pfctl -ss

# View firewall state table
pfctl -s state

# Test connectivity
ping -c 3 google.com

# Check DNS
nslookup google.com

# View routing table
netstat -rn
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
scp -o ProxyCommand="ssh -i ./lab-key.pem -W %h:%p admin@18.159.181.174" -i ./lab-key.pem kali@10.0.2.100:/home/kali/sql_injection.pcap ./sql_injection.pcap
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

### Capture Attack Traffic (Kali)
```bash
# Start capture
sudo tcpdump -i eth0 -w /tmp/sql_injection.pcap host 10.0.3.100 and port 3000 &

# Wait 2 seconds
sleep 2

# Perform SQL injection
curl -X POST http://10.0.3.100:3000/rest/user/login \
  -H "Content-Type: application/json" \
  -d '{"email":"'\'' OR 1=1--","password":"anything"}'

# Wait 2 seconds
sleep 2

# Stop capture
sudo pkill tcpdump

# Copy to home directory
sudo cp /tmp/sql_injection.pcap /home/kali/
sudo chown kali:kali /home/kali/sql_injection.pcap
```

### Download to Windows
```powershell
# From Windows PowerShell
scp -o ProxyCommand="ssh -i ./lab-key.pem -W %h:%p admin@18.159.181.174" -i ./lab-key.pem kali@10.0.2.100:/home/kali/sql_injection.pcap ./sql_injection.pcap
```

### Analyze in Wireshark (Windows)
```
1. Open Wireshark → File → Open → sql_injection.pcap
2. Right-click POST packet → Follow → HTTP Stream
3. Screenshot the SQL injection payload and admin response
```

**Common filters:**
- `http` - Show only HTTP traffic
- `http.request.method == "POST"` - Show POST requests
- `http contains "OR 1=1"` - Find SQL injection

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
# From pfSense (direct, no jump needed)
scp -i ./lab-key.pem admin@18.159.181.174:/path/to/file ./local-file

# From Kali (via pfSense jump)
scp -o ProxyCommand="ssh -i ./lab-key.pem -W %h:%p admin@18.159.181.174" -i ./lab-key.pem kali@10.0.2.100:/path/to/file ./local-file

# From Ubuntu (via pfSense jump)
scp -o ProxyCommand="ssh -i ./lab-key.pem -W %h:%p admin@18.159.181.174" -i ./lab-key.pem ubuntu@10.0.3.100:/path/to/file ./local-file
```

### Copy TO Instance from Local
```powershell
# To pfSense
scp -i ./lab-key.pem ./local-file admin@18.159.181.174:/tmp/

# To Kali (via pfSense jump)
scp -o ProxyCommand="ssh -i ./lab-key.pem -W %h:%p admin@18.159.181.174" -i ./lab-key.pem ./local-file kali@10.0.2.100:/tmp/

# To Ubuntu (via pfSense jump)
scp -o ProxyCommand="ssh -i ./lab-key.pem -W %h:%p admin@18.159.181.174" -i ./lab-key.pem ./local-file ubuntu@10.0.3.100:/tmp/
```

---


### Fix SSH Key Permissions (Windows)

```powershell
# Remove all permissions
icacls "lab-key.pem" /inheritance:r

# Grant only your user read access
icacls "lab-key.pem" /grant:r "$($env:USERNAME):(R)"

# Verify
icacls "lab-key.pem"
```

### Can't Access pfSense Web Interface

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
ssh -i ./lab-key.pem admin@18.159.181.174
# Option 8, then: ssh ubuntu@10.0.3.100

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
ssh -i ./lab-key.pem admin@18.159.181.174
# Option 8, then: ssh kali@10.0.2.100

# Check container status
docker ps

# Restart container
docker restart cyberchef

# Test locally
curl http://localhost:8000
```

### Reset pfSense Web Password

```powershell
# SSH to pfSense
ssh -i ./lab-key.pem admin@18.159.181.174

# Choose option 3
# Enter new password when prompted
```

---

## 💾 BACKUP & RESTORE

### Backup pfSense Configuration

```
Web Interface:
1. Navigate to: Diagnostics → Backup & Restore
2. Click: Backup area → "Download configuration as XML"
3. Save file locally
```
---

## 📊 TERRAFORM OPERATIONS

### Get Outputs

```powershell
# All outputs
terraform output

# Specific outputs
terraform output pfsense_public_ip
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


### Daily Startup Workflow

```powershell
# 1. Start instances
aws ec2 start-instances --instance-ids i-0de2c457331324932 i-021f1421bd412336f i-07f9820e0c3d0349e

# 2. Wait 2-3 minutes

# 3. Get pfSense IP (if it changed)
terraform output pfsense_public_ip

# 4. Access pfSense web interface
# Open browser: https://18.159.181.174

# 5. Verify services
# SSH to pfSense and test JuiceShop:
ssh -i ./lab-key.pem admin@18.159.181.174
# Option 8, then: curl http://10.0.3.100:3000
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
# From pfSense shell (after SSH option 8):

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


### Collect Evidence

```bash
# From Kali - Export Wireshark capture
# File → Export Packet Dissections → As Plain Text
# Save as: sqlinjection_capture.txt

# From pfSense - Export Snort alerts
# Services → Snort → Alerts → Download

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
  --time-period Start=2026-01-01,End=2026-02-01 `
  --granularity MONTHLY `
  --metrics BlendedCost
```
---




## ToDo: Dhcp, dns, ssl, snort configuration automatically after the apply so that the kali and ubuntu have access to internet to access docker (FROM XML BACKUP), certificat semnat de o autoritate recunoscuta => am nevoie de domeniu 📚
