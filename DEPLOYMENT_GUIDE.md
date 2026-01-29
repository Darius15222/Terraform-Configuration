# 🚀 CYBERSECURITY LAB - DEPLOYMENT GUIDE

## ⚡ QUICK START (5 commands)

```bash
# 1. Set your public IP
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: admin_cidr = "YOUR_IP/32"

# 2. Initialize Terraform
terraform init

# 3. Review changes
terraform plan

# 4. Deploy infrastructure
terraform apply

# 5. Wait 10 minutes, then configure pfSense
# See outputs for pfSense URL and configuration guide
```

---

## 📋 PRE-DEPLOYMENT CHECKLIST

### ✅ Requirements

- [ ] AWS Account with credentials configured
- [ ] Terraform installed (v1.0+)
- [ ] Your public IP address ([check here](https://whatismyip.com))
- [ ] SSH client installed
- [ ] 50-60 minutes for full setup

### ✅ Cost Awareness

**Hourly Cost:** ~$0.30/hour (~$7.20/day)
- pfSense (t3.small): $0.0208/hour
- Kali (t3.small): $0.0208/hour
- Ubuntu (t3.micro): $0.0104/hour
- EIP: $0.005/hour (while attached)

**💡 Cost Saving:** Stop instances when not in use!

```bash
# Stop all instances (keeps data, no charges for compute)
aws ec2 stop-instances --instance-ids \
  $(terraform output -json instance_ids | jq -r '.pfsense') \
  $(terraform output -json instance_ids | jq -r '.kali') \
  $(terraform output -json instance_ids | jq -r '.ubuntu')

# Start when needed
aws ec2 start-instances --instance-ids <instance-ids>
```

---

## 🛠️ DETAILED DEPLOYMENT STEPS

### Step 1: Configure Variables (5 minutes)

```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Get your public IP
curl https://checkip.amazonaws.com

# Edit terraform.tfvars
nano terraform.tfvars
```

**Required:** Set `admin_cidr` to your IP:
```hcl
admin_cidr = "YOUR_IP_HERE/32"  # Example: "203.0.113.42/32"
```

**Optional:** Override defaults (if needed):
```hcl
aws_region = "eu-central-1"
vpc_cidr   = "10.0.0.0/16"
# ... other variables
```

### Step 2: Initialize Terraform (2 minutes)

```bash
# Download provider plugins
terraform init

# Expected output:
# - Downloading hashicorp/aws v5.100.0
# - Downloading hashicorp/local v2.6.1
# - Downloading hashicorp/tls v4.1.0
# - Terraform has been successfully initialized!
```

### Step 3: Review Deployment Plan (2 minutes)

```bash
# See what will be created
terraform plan

# Review:
# - 3 EC2 instances (pfSense, Kali, Ubuntu)
# - 1 VPC with 3 subnets
# - 4 Security groups
# - 3 Route tables
# - 1 Internet Gateway
# - 1 Elastic IP
# - SSH key pair
# Total: ~25 resources
```

### Step 4: Deploy Infrastructure (5 minutes)

```bash
# Deploy everything
terraform apply

# Type: yes

# Wait for completion (3-5 minutes)
# Watch for: "Apply complete! Resources: XX added"
```

### Step 5: Wait for User-Data (10 minutes)

After Terraform completes, **user-data scripts run in background**:

**Ubuntu:** Installing Docker, deploying JuiceShop  
**Kali:** Installing Docker, deploying CyberChef  
**pfSense:** Booting up (manual config required)

**How to monitor:**
```bash
# Get instance IDs
terraform output -json instance_ids

# Check instance status
aws ec2 describe-instance-status --instance-ids <ubuntu-id>

# SSH and check logs (after ~5 minutes)
# See Step 6 for SSH commands
```

### Step 6: Verify Deployment (10 minutes)

#### 6.1 Verify pfSense

```bash
# Get pfSense IP
PFSENSE_IP=$(terraform output -raw pfsense_public_ip)

# Test HTTPS access
curl -k https://$PFSENSE_IP

# Expected: HTML response (pfSense login page)

# SSH to pfSense
ssh -i lab-key.pem admin@$PFSENSE_IP
# Default password: pfsense
# ⚠️ CHANGE IT IMMEDIATELY!
```

#### 6.2 Verify Kali Linux

```bash
# Get IPs
PFSENSE_IP=$(terraform output -raw pfsense_public_ip)
KALI_IP=$(terraform output -raw kali_private_ip)

# SSH via pfSense jump host
ssh -i lab-key.pem -J admin@$PFSENSE_IP kali@$KALI_IP

# Once connected, verify CyberChef:
curl http://localhost:8000
# Expected: HTML response

# Check Docker:
docker ps
# Expected: cyberchef container running

# Check logs:
tail -50 /var/log/userdata.log
# Expected: "✅ Kali Linux Setup Completed"
```

#### 6.3 Verify Ubuntu + JuiceShop

```bash
# SSH to Ubuntu
UBUNTU_IP=$(terraform output -raw ubuntu_private_ip)
ssh -i lab-key.pem -J admin@$PFSENSE_IP ubuntu@$UBUNTU_IP

# Check Docker:
docker ps
# Expected: juiceshop container running

# Check JuiceShop:
curl http://localhost:3000
# Expected: HTML response

# Check logs:
tail -50 /var/log/userdata.log
# Expected: "✅ Ubuntu Server Setup Completed"

# View JuiceShop logs:
docker logs juiceshop
```

#### 6.4 Test from Kali to Ubuntu

```bash
# From Kali (SSH'd in):
curl http://10.0.3.100:3000

# Expected: HTML response (JuiceShop homepage)

# If this works, network routing is correct! ✅
```

### Step 7: Configure pfSense (50 minutes)

**CRITICAL:** pfSense requires manual configuration via web interface.

See detailed guide in the deployed `pfsense-userdata.sh` file or run:
```bash
terraform output verification_steps
```

**Configuration tasks:**
1. **DNS Resolver** (5 min) - Services > DNS Resolver
2. **DHCP Server** (10 min) - Services > DHCP Server
3. **SSL Certificate** (5 min) - System > Cert Manager
4. **Snort IDS** (30 min) - System > Package Manager

**Complete guide:** See `pfsense-userdata.sh` for step-by-step instructions

---

## 🧪 TESTING & VERIFICATION

### Test 1: DNS Resolution

```bash
# From Kali:
nslookup google.com

# Expected output:
# Server: 10.0.2.10 (pfSense LAN IP)
# Answer: google.com IP address
```

### Test 2: Internet Connectivity

```bash
# From Kali:
ping -c 4 8.8.8.8

# From Ubuntu:
ping -c 4 8.8.8.8

# Expected: Successful pings via pfSense NAT
```

### Test 3: JuiceShop Accessibility

```bash
# From Kali:
firefox http://10.0.3.100:3000

# Or via CLI:
curl http://10.0.3.100:3000 | grep -i juice

# Expected: JuiceShop homepage loads
```

### Test 4: CyberChef

```bash
# From Kali:
firefox http://localhost:8000

# Expected: CyberChef interface loads
```

### Test 5: Wireshark Capture

```bash
# From Kali (GUI):
sudo wireshark

# 1. Select interface: eth0
# 2. Start capture
# 3. Browse to JuiceShop
# 4. Stop capture
# 5. Filter: http
# 6. Should see HTTP traffic to 10.0.3.100:3000
```

### Test 6: SQL Injection + Snort Detection

```bash
# Prerequisites: Snort configured on pfSense

# From Kali browser:
# 1. Go to: http://10.0.3.100:3000
# 2. Click "Login"
# 3. Email: ' OR 1=1--
# 4. Password: anything
# 5. Submit

# Check pfSense:
# - Services > Snort > Alerts
# - Should see SQL injection alert

# In Wireshark:
# - Filter: http && tcp.port==3000
# - Find POST /rest/user/login
# - Should see ' OR 1=1-- in payload
```

### Test 7: Cookie Interception

```bash
# From Kali:
# 1. Launch: burpsuite
# 2. Configure browser proxy: 127.0.0.1:8080
# 3. Burp: Proxy > Intercept > On
# 4. Browser: http://10.0.3.100:3000
# 5. Login as normal user
# 6. Burp shows intercepted request with Cookie header
# 7. Copy JWT token
# 8. Open CyberChef: http://localhost:8000
# 9. Operation: JWT Decode
# 10. Paste token
# 11. View decoded payload
```

---

## 🚨 TROUBLESHOOTING

### Issue: "Connection refused" to JuiceShop

**Diagnosis:**
```bash
# SSH to Ubuntu
ssh -i lab-key.pem -J admin@$PFSENSE_IP ubuntu@$UBUNTU_IP

# Check if container is running
docker ps

# If not running:
docker logs juiceshop

# Common issues:
# - Docker failed to pull image (internet connectivity)
# - Port already in use
# - Out of memory
```

**Solution:**
```bash
# Restart container
docker restart juiceshop

# Or redeploy:
docker rm -f juiceshop
docker run -d --name juiceshop --restart unless-stopped -p 3000:3000 bkimminich/juice-shop
```

### Issue: Can't access pfSense web interface

**Diagnosis:**
```bash
# Check security group allows your IP
terraform output pfsense_public_ip

# Test connectivity
curl -k https://$(terraform output -raw pfsense_public_ip)

# Check if your IP changed
curl https://checkip.amazonaws.com
```

**Solution:**
```bash
# Update terraform.tfvars with new IP
admin_cidr = "NEW_IP/32"

# Apply changes
terraform apply
```

### Issue: CyberChef not loading

**Diagnosis:**
```bash
# SSH to Kali
docker ps | grep cyberchef

# Check logs
docker logs cyberchef
```

**Solution:**
```bash
# Restart container
docker restart cyberchef

# Test locally
curl http://localhost:8000
```

### Issue: Kali can't reach Ubuntu

**Diagnosis:**
```bash
# From Kali:
ping 10.0.3.100

# If no response:
# 1. Check routing
ip route

# 2. Check pfSense is running
ping 10.0.2.10  # pfSense LAN gateway
```

**Solution:**
- Verify pfSense instance is running in AWS Console
- Check security groups allow traffic
- Verify route tables are correctly associated

### Issue: User-data script didn't run

**Diagnosis:**
```bash
# Check cloud-init logs
ssh to instance
sudo cat /var/log/cloud-init-output.log
sudo cat /var/log/userdata.log
```

**Solution:**
If scripts didn't run, manually execute:
```bash
# Get script from Terraform
terraform show -json | jq '.values.root_module.resources[] | select(.address=="aws_instance.ubuntu") | .values.user_data'

# Or re-run commands from script
```

---

## 🔐 SECURITY BEST PRACTICES

### 1. Change Default Passwords
```bash
# pfSense: System > User Manager > admin
# Default: pfsense
# Change to strong password immediately!
```

### 2. Restrict Admin Access
```bash
# Update terraform.tfvars when IP changes
admin_cidr = "YOUR_NEW_IP/32"
terraform apply
```

### 3. Stop Instances When Not in Use
```bash
# Stop (no compute charges, data persists)
aws ec2 stop-instances --instance-ids \
  $(terraform output -json instance_ids | jq -r '.pfsense, .kali, .ubuntu')

# Start when needed
aws ec2 start-instances --instance-ids <ids>
```

### 4. Monitor Costs
```bash
# Check current month's costs
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

### 5. Backup Important Data
```bash
# Export Wireshark captures
# Export Snort alerts
# Screenshot pfSense configs
# Export JuiceShop data (if modified)
```

---

## 🧹 CLEANUP

### Temporary Cleanup (Keep Infrastructure)
```bash
# Stop instances (no compute charges)
aws ec2 stop-instances --instance-ids $(terraform output -json instance_ids | jq -r '.[]')

# Clear local sensitive files
rm -f lab-key.pem
rm -f terraform.tfstate.backup
```

### Full Cleanup (Destroy Everything)
```bash
# ⚠️ WARNING: This deletes ALL resources
# You will lose all configurations and data

terraform destroy

# Type: yes

# Verify in AWS Console:
# - EC2 > Instances (all terminated)
# - VPC > Your VPCs (cyber-lab-vpc deleted)
# - EC2 > Elastic IPs (released)
```

### Post-Cleanup Verification
```bash
# Check no resources remain
terraform state list
# Expected: empty

# Check no lingering costs
aws ec2 describe-instances --filters "Name=tag:Project,Values=CyberLab"
# Expected: no instances
```

---

## 📚 COURSEWORK DOCUMENTATION

### Required Evidence

**1. Network Architecture**
- [ ] Network diagram (use output from `terraform output network_architecture`)
- [ ] IP addressing scheme
- [ ] Subnet configuration

**2. pfSense Configuration**
- [ ] DNS Resolver screenshot
- [ ] DHCP Server leases
- [ ] Certificate details
- [ ] Snort IDS configuration

**3. Attack Demonstrations**
- [ ] SQL Injection (Wireshark capture + Snort alert)
- [ ] Cookie Interception (Burp + CyberChef analysis)
- [ ] XSS attack (if applicable)
- [ ] Any other OWASP Top 10 vulnerabilities

**4. Traffic Analysis**
- [ ] Wireshark .pcap files
- [ ] Snort alert logs
- [ ] CyberChef analysis screenshots

**5. Infrastructure as Code**
- [ ] Terraform configuration files
- [ ] Deployment logs
- [ ] Security hardening measures (Checkov report)

### Quick Documentation Commands
```bash
# Export network architecture
terraform output network_architecture > network_architecture.txt

# Export all outputs
terraform output > lab_deployment_info.txt

# Generate Checkov security report
checkov -d . --output-file-path . --output cli
```

---

## ❓ FAQ

**Q: How long does deployment take?**  
A: 3-5 minutes for Terraform, then 10 minutes for user-data scripts

**Q: Can I use a different AWS region?**  
A: Yes, but you must update AMI IDs in `variables.tf` for that region

**Q: What if my IP changes?**  
A: Update `admin_cidr` in `terraform.tfvars` and run `terraform apply`

**Q: Can I add more vulnerable apps?**  
A: Yes! Edit `ubuntu-userdata.sh` to add more Docker containers

**Q: Is this safe to run?**  
A: Yes, but only for educational purposes. Never expose to public internet without proper security.

**Q: How do I get Let's Encrypt certificate?**  
A: Requires real domain name and DNS configuration. Self-signed is easier for labs.

**Q: Can I snapshot the instances?**  
A: Yes! AWS Console > EC2 > Instances > Actions > Image and templates > Create image

**Q: How do I update AMI IDs?**  
A: See instructions in `data.tf` or run AWS CLI commands to find latest AMIs

---

## 📞 SUPPORT

**Issues with Terraform:**
- Check AWS credentials: `aws sts get-caller-identity`
- Verify region: `terraform.tfvars`
- Check state: `terraform state list`

**Issues with Services:**
- Check logs: `/var/log/userdata.log` and `/var/log/cloud-init-output.log`
- Verify Docker: `docker ps` and `docker logs <container>`
- Test connectivity: `ping`, `curl`, `telnet`

**AWS Console Links:**
- [EC2 Instances](https://console.aws.amazon.com/ec2/v2/home#Instances)
- [VPC Dashboard](https://console.aws.amazon.com/vpc/home)
- [Cost Explorer](https://console.aws.amazon.com/cost-management/home)

---

## ✅ DEPLOYMENT SUCCESS CRITERIA

Your lab is **fully operational** when:

- ✅ pfSense web interface accessible
- ✅ DNS resolution working from Kali/Ubuntu
- ✅ DHCP leases visible in pfSense
- ✅ JuiceShop accessible from Kali
- ✅ CyberChef accessible from Kali
- ✅ Wireshark captures traffic
- ✅ Snort generates alerts on attacks
- ✅ Cookie interception successful
- ✅ All user-data logs show "Setup Completed"

**Total Setup Time:** 60-70 minutes  
**Lab Ready:** ✅

---

**Good luck with your cybersecurity coursework!** 🎓🔐
