# ✅ CYBERSECURITY LAB - FINAL TESTING CHECKLIST

This checklist ensures your lab is fully operational before starting coursework exercises.

---

## 📋 PRE-DEPLOYMENT CHECKS

### Before Running `terraform apply`

- [ ] **AWS Credentials Configured**
  ```bash
  aws sts get-caller-identity
  # Should return your AWS account info
  ```

- [ ] **Terraform Installed**
  ```bash
  terraform version
  # Should show v1.0 or higher
  ```

- [ ] **Admin IP Configured**
  ```bash
  grep admin_cidr terraform.tfvars
  # Should show: admin_cidr = "YOUR_IP/32"
  ```

- [ ] **AMI IDs Valid for Region**
  ```bash
  grep aws_region terraform.tfvars
  # Verify matches region in variables.tf
  ```

- [ ] **Git Ignored Sensitive Files**
  ```bash
  cat .gitignore | grep -E "tfstate|tfvars|pem"
  # Should include: *.tfstate, *.tfvars, *.pem
  ```

---

## 🚀 DEPLOYMENT CHECKS

### During Terraform Apply

- [ ] **Terraform Init Successful**
  ```bash
  terraform init
  # "Terraform has been successfully initialized!"
  ```

- [ ] **Terraform Plan Shows Expected Resources**
  ```bash
  terraform plan
  # Should show ~25 resources to add
  ```

- [ ] **Terraform Apply Completes**
  ```bash
  terraform apply
  # "Apply complete! Resources: XX added"
  # Time: 3-5 minutes
  ```

- [ ] **Outputs Display Correctly**
  ```bash
  terraform output
  # Should show: IPs, SSH commands, network diagram
  ```

- [ ] **SSH Key Generated**
  ```bash
  ls -la lab-key.pem
  # Should exist with permissions 0400 (-r--------)
  ```

---

## ⏱️ POST-DEPLOYMENT WAIT PERIOD

**CRITICAL:** User-data scripts run in background after Terraform completes.

- [ ] **Wait 10 Minutes** ⏰
  - Ubuntu: Installing Docker, deploying JuiceShop (~5 min)
  - Kali: Installing Docker, deploying CyberChef (~5 min)
  - pfSense: Booting and initializing (~3 min)

---

## 🔍 INFRASTRUCTURE VALIDATION

### 1. AWS Console Verification

- [ ] **EC2 Instances Running**
  ```
  AWS Console → EC2 → Instances
  - pfsense-firewall: Running ✅
  - kali-linux: Running ✅
  - ubuntu-minimal-server: Running ✅
  ```

- [ ] **VPC Created**
  ```
  AWS Console → VPC → Your VPCs
  - cyber-lab-vpc: Available ✅
  - CIDR: 10.0.0.0/16 ✅
  ```

- [ ] **Subnets Created**
  ```
  AWS Console → VPC → Subnets
  - subnet-wan: 10.0.1.0/24 (Public) ✅
  - subnet-kali: 10.0.2.0/24 (Private) ✅
  - subnet-ubuntu: 10.0.3.0/24 (Private) ✅
  ```

- [ ] **Security Groups Configured**
  ```
  AWS Console → EC2 → Security Groups
  - pfsense-wan-sg ✅
  - pfsense-internal-sg ✅
  - kali-sg ✅
  - ubuntu-sg ✅
  ```

- [ ] **Elastic IP Attached**
  ```
  AWS Console → EC2 → Elastic IPs
  - Should see 1 EIP allocated and associated ✅
  ```

### 2. Network Connectivity Tests

- [ ] **pfSense Reachable from Internet**
  ```bash
  PFSENSE_IP=$(terraform output -raw pfsense_public_ip)
  curl -k https://$PFSENSE_IP
  # Expected: HTML response (pfSense login page)
  ```

- [ ] **SSH to pfSense Works**
  ```bash
  ssh -i lab-key.pem admin@$PFSENSE_IP
  # Default password: pfsense
  # Should get pfSense shell prompt
  ```

---

## 🖥️ INSTANCE VERIFICATION

### 3. Kali Linux Checks

- [ ] **SSH Connection Works**
  ```bash
  PFSENSE_IP=$(terraform output -raw pfsense_public_ip)
  KALI_IP=$(terraform output -raw kali_private_ip)
  ssh -i lab-key.pem -J admin@$PFSENSE_IP kali@$KALI_IP
  # Should connect successfully
  ```

- [ ] **User-Data Script Completed**
  ```bash
  # From Kali SSH session:
  tail -50 /var/log/userdata.log
  # Look for: "✅ Kali Linux Setup Completed"
  ```

- [ ] **Docker Installed and Running**
  ```bash
  docker --version
  # Should show: Docker version XX.X.X
  
  systemctl status docker
  # Should show: active (running)
  ```

- [ ] **CyberChef Container Running**
  ```bash
  docker ps
  # Should show: cyberchef container, Up X minutes, 0.0.0.0:8000->8000/tcp
  ```

- [ ] **CyberChef Accessible Locally**
  ```bash
  curl http://localhost:8000 | head -20
  # Should return: HTML (CyberChef interface)
  ```

- [ ] **Desktop Files Created**
  ```bash
  ls -la /home/kali/Desktop/
  # Should see: cyberchef.desktop, LAB_TARGETS.txt
  ```

- [ ] **Internet Connectivity Works**
  ```bash
  ping -c 3 8.8.8.8
  # Should receive replies (via pfSense NAT)
  ```

### 4. Ubuntu Server Checks

- [ ] **SSH Connection Works**
  ```bash
  UBUNTU_IP=$(terraform output -raw ubuntu_private_ip)
  ssh -i lab-key.pem -J admin@$PFSENSE_IP ubuntu@$UBUNTU_IP
  # Should connect successfully
  ```

- [ ] **User-Data Script Completed**
  ```bash
  # From Ubuntu SSH session:
  tail -50 /var/log/userdata.log
  # Look for: "✅ Ubuntu Server Setup Completed"
  ```

- [ ] **Docker Installed and Running**
  ```bash
  docker --version
  systemctl status docker
  # Should show: active (running)
  ```

- [ ] **JuiceShop Container Running**
  ```bash
  docker ps
  # Should show: juiceshop container, Up X minutes, 0.0.0.0:3000->3000/tcp
  ```

- [ ] **JuiceShop Accessible Locally**
  ```bash
  curl http://localhost:3000 | head -20
  # Should return: HTML (JuiceShop homepage)
  ```

- [ ] **JuiceShop Logs Show No Errors**
  ```bash
  docker logs juiceshop | tail -30
  # Should show: Server listening on port 3000
  ```

- [ ] **Internet Connectivity Works**
  ```bash
  ping -c 3 8.8.8.8
  # Should receive replies (via pfSense NAT)
  ```

---

## 🌐 CROSS-INSTANCE CONNECTIVITY

### 5. Kali → Ubuntu Traffic

- [ ] **Kali Can Reach Ubuntu IP**
  ```bash
  # From Kali SSH session:
  ping -c 3 10.0.3.100
  # Should receive replies
  ```

- [ ] **Kali Can Access JuiceShop**
  ```bash
  # From Kali:
  curl http://10.0.3.100:3000 | head -20
  # Should return: HTML (JuiceShop homepage)
  ```

- [ ] **HTTP Request Works**
  ```bash
  # From Kali:
  curl -I http://10.0.3.100:3000
  # Should show: HTTP/1.1 200 OK
  ```

### 6. DNS Resolution Tests

- [ ] **DNS Works from Kali**
  ```bash
  # From Kali:
  nslookup google.com
  # Should show: Server: 10.0.2.10 (pfSense)
  # Note: Requires pfSense DNS configured
  ```

- [ ] **DNS Works from Ubuntu**
  ```bash
  # From Ubuntu:
  nslookup google.com
  # Should show: Server: 10.0.3.10 (pfSense)
  # Note: Requires pfSense DNS configured
  ```

---

## 🔥 PFSENSE CONFIGURATION

### 7. pfSense Web Interface

- [ ] **Web Interface Accessible**
  ```bash
  # From your browser:
  https://$(terraform output -raw pfsense_public_ip)
  # Should show: pfSense login page
  ```

- [ ] **Default Login Works**
  ```
  Username: admin
  Password: pfsense
  # Should login successfully
  ⚠️ CHANGE PASSWORD IMMEDIATELY!
  ```

- [ ] **Dashboard Loads**
  ```
  After login, should see:
  - System information
  - Interface status (WAN, LAN, OPT1)
  - CPU/Memory usage
  ```

### 8. pfSense DNS Configuration

- [ ] **Navigate to DNS Resolver**
  ```
  Services → DNS Resolver
  ```

- [ ] **Enable DNS Resolver**
  ```
  ☑ Enable DNS Resolver
  ☑ Enable DNSSEC Support
  Network Interfaces: LAN, OPT1
  Click "Save" → "Apply Changes"
  ```

- [ ] **Verify DNS Service Running**
  ```
  Status → Services
  Look for: unbound - running ✅
  ```

### 9. pfSense DHCP Configuration

- [ ] **Configure DHCP on LAN**
  ```
  Services → DHCP Server → LAN
  ☑ Enable DHCP server on LAN interface
  Range: 10.0.2.100 to 10.0.2.200
  DNS Server: 10.0.2.10
  Gateway: 10.0.2.10
  Domain: cyberlab.local
  Click "Save"
  ```

- [ ] **Configure DHCP on OPT1**
  ```
  Services → DHCP Server → OPT1
  ☑ Enable DHCP server on OPT1 interface
  Range: 10.0.3.100 to 10.0.3.200
  DNS Server: 10.0.3.10
  Gateway: 10.0.3.10
  Domain: cyberlab.local
  Click "Save"
  ```

- [ ] **Verify DHCP Leases**
  ```
  Status → DHCP Leases
  Should see:
  - 10.0.2.100 - kali-linux ✅
  - 10.0.3.100 - ubuntu-server ✅
  ```

### 10. pfSense SSL Certificate

- [ ] **Navigate to Certificate Manager**
  ```
  System → Cert Manager → Certificates
  ```

- [ ] **Create Internal Certificate**
  ```
  Click "Add/Sign"
  Method: Create an Internal Certificate
  Descriptive name: pfSense Lab Certificate
  Common Name: cyberlab.local
  Lifetime: 3650 days
  Click "Save"
  ```

- [ ] **Apply Certificate to Web Interface**
  ```
  System → Advanced → Admin Access
  SSL/TLS Certificate: pfSense Lab Certificate
  Click "Save"
  ```

- [ ] **Verify Certificate Applied**
  ```
  Close browser, reopen:
  https://<PFSENSE_IP>
  Click certificate icon in address bar
  Should show: "Issued to: cyberlab.local"
  ```

### 11. pfSense Snort IDS

- [ ] **Install Snort Package**
  ```
  System → Package Manager → Available Packages
  Search: "snort"
  Click "Install" on Snort package
  Wait 5 minutes for installation
  ```

- [ ] **Verify Snort Installed**
  ```
  Services menu should now show "Snort"
  ```

- [ ] **Register for Snort Oinkcode**
  ```
  1. Visit: https://www.snort.org/users/sign_up
  2. Create free account
  3. Get Oinkcode from: https://www.snort.org/oinkcodes
  ```

- [ ] **Configure Snort Global Settings**
  ```
  Services → Snort → Global Settings
  Paste Oinkcode
  Enable: Emerging Threats Open (free)
  Click "Save"
  ```

- [ ] **Update Snort Rules**
  ```
  Services → Snort → Updates
  Click "Update Rules"
  Wait 5-10 minutes for download
  ```

- [ ] **Enable Snort on WAN**
  ```
  Services → Snort → Snort Interfaces
  Click "Add"
  Interface: WAN
  Enable: ☑ Checked
  Click "Save"
  ```

- [ ] **Configure Snort Rules**
  ```
  Click edit (pencil icon) on WAN interface
  WAN Categories tab:
    ☑ Use IPS Policy: Connectivity
  WAN Rules tab:
    ☑ Enable all rule categories
  Click "Save"
  Click "Start" on WAN interface
  ```

- [ ] **Verify Snort Running**
  ```
  Services → Snort → Snort Interfaces
  WAN interface should show: "Running" ✅
  ```

---

## 🎯 ATTACK SCENARIO TESTS

### 12. SQL Injection Test

- [ ] **Launch Wireshark on Kali**
  ```bash
  # From Kali (GUI):
  sudo wireshark
  # Select interface: eth0
  # Click "Start Capturing"
  ```

- [ ] **Browse to JuiceShop**
  ```
  # From Kali browser:
  http://10.0.3.100:3000
  ```

- [ ] **Perform SQL Injection**
  ```
  Click "Account" → "Login"
  Email: ' OR 1=1--
  Password: anything
  Click "Log in"
  # Should bypass authentication ✅
  ```

- [ ] **Stop Wireshark Capture**
  ```
  Click red stop button
  Filter: http && tcp.port==3000
  Should see: POST /rest/user/login with malicious payload
  ```

- [ ] **Check Snort Alerts**
  ```
  pfSense: Services → Snort → Alerts
  Should see: SQL injection alert ✅
  (May take 1-2 minutes to appear)
  ```

- [ ] **Export Wireshark Capture**
  ```
  File → Export Packet Dissections → As Plain Text
  Save as: sqlinjection_capture.txt
  ```

### 13. Cookie Interception Test

- [ ] **Launch Burp Suite on Kali**
  ```bash
  # From Kali:
  burpsuite
  ```

- [ ] **Configure Browser Proxy**
  ```
  Firefox → Settings → Network Settings
  Manual proxy: 127.0.0.1:8080
  ☑ Use proxy for all protocols
  ```

- [ ] **Enable Burp Intercept**
  ```
  Burp Suite → Proxy → Intercept → On
  ```

- [ ] **Login to JuiceShop**
  ```
  Browser: http://10.0.3.100:3000
  Create account or login
  # Burp intercepts request
  ```

- [ ] **View Cookie in Burp**
  ```
  Look for: Cookie: token=eyJhbGci...
  Copy the JWT token value
  ```

- [ ] **Analyze in CyberChef**
  ```
  Open: http://localhost:8000
  Paste JWT token
  Operation: "JWT Decode"
  Drag to "Recipe"
  Should see decoded payload ✅
  ```

- [ ] **Screenshot Evidence**
  ```
  - Screenshot of Burp intercepted request ✅
  - Screenshot of CyberChef decoded JWT ✅
  ```

---

## 📊 MONITORING & LOGGING

### 14. Log Verification

- [ ] **pfSense System Logs**
  ```
  Status → System Logs → System
  Should show recent system events
  ```

- [ ] **pfSense Firewall Logs**
  ```
  Status → System Logs → Firewall
  Should show traffic logs
  ```

- [ ] **Snort Alert Logs**
  ```
  Services → Snort → Alerts
  Should show attack detections
  ```

- [ ] **Docker Logs - JuiceShop**
  ```bash
  # From Ubuntu:
  docker logs juiceshop | tail -50
  # Should show HTTP requests
  ```

- [ ] **Docker Logs - CyberChef**
  ```bash
  # From Kali:
  docker logs cyberchef | tail -20
  # Should show service running
  ```

---

## 📝 DOCUMENTATION COLLECTION

### 15. Coursework Evidence

- [ ] **Network Diagram**
  ```bash
  terraform output network_architecture > network_diagram.txt
  ```

- [ ] **Wireshark Captures**
  ```
  - sqlinjection.pcap ✅
  - cookie_intercept.pcap ✅
  - dns_queries.pcap ✅
  ```

- [ ] **Screenshots Collected**
  ```
  - pfSense dashboard ✅
  - DHCP leases ✅
  - DNS resolver config ✅
  - Snort alerts ✅
  - Burp Suite intercept ✅
  - CyberChef analysis ✅
  - JuiceShop vulnerability ✅
  ```

- [ ] **Configuration Files**
  ```bash
  # Export Terraform configs
  tar -czf terraform_configs.tar.gz *.tf *.md
  ```

- [ ] **Snort Alert Logs**
  ```
  pfSense: Diagnostics → Command Prompt
  cat /var/log/snort/snort_<interface>/alert
  Copy to file: snort_alerts.log
  ```

---

## 🔐 SECURITY VERIFICATION

### 16. Security Posture Check

- [ ] **IMDSv2 Enforced**
  ```bash
  # From any instance:
  curl http://169.254.169.254/latest/meta-data/
  # Should fail (IMDSv2 required) ✅
  
  # Correct method (should work):
  TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/
  ```

- [ ] **EBS Volumes Encrypted**
  ```bash
  # AWS Console:
  EC2 → Volumes → Select volume → Description
  Should show: Encrypted: Yes ✅
  ```

- [ ] **Security Group Rules Correct**
  ```bash
  # Check admin IP restriction:
  aws ec2 describe-security-groups \
    --group-ids $(terraform state show aws_security_group.pfsense_wan_sg | grep "id " | awk '{print $3}' | tr -d '"') \
    --query 'SecurityGroups[0].IpPermissions[0].IpRanges[0].CidrIp'
  # Should match your admin_cidr
  ```

- [ ] **pfSense Password Changed**
  ```
  ⚠️ CRITICAL: Change default password!
  pfSense → System → User Manager → admin → Edit
  New password: [strong password]
  Click "Save"
  ```

---

## 💰 COST MONITORING

### 17. AWS Cost Check

- [ ] **Current Running Instances**
  ```bash
  terraform output instance_ids
  # Verify only expected instances running
  ```

- [ ] **Check Estimated Costs**
  ```
  AWS Console → Billing → Cost Explorer
  Filter: Last 7 days
  Group by: Service
  Expected: ~$0.30/hour (~$7.20/day)
  ```

- [ ] **Set Up Cost Alert** (Optional)
  ```
  AWS Console → Billing → Budgets → Create budget
  Budget type: Cost
  Amount: $50/month
  Alert threshold: 80%
  Email: your@email.com
  ```

---

## ✅ FINAL VERIFICATION

### All Systems Operational Checklist

```
INFRASTRUCTURE:
[✓] All EC2 instances running
[✓] VPC and subnets created
[✓] Security groups configured
[✓] Elastic IP attached
[✓] SSH key generated and working

SERVICES:
[✓] pfSense web interface accessible
[✓] JuiceShop running on Ubuntu
[✓] CyberChef running on Kali
[✓] Docker containers healthy

NETWORKING:
[✓] Kali can reach Ubuntu
[✓] Internet connectivity works
[✓] DNS resolution works (after pfSense config)
[✓] DHCP leases assigned (after pfSense config)

SECURITY:
[✓] Admin IP restricted access
[✓] IMDSv2 enforced
[✓] EBS encryption enabled
[✓] pfSense password changed
[✓] Private keys secured

PFSENSE:
[✓] DNS Resolver configured
[✓] DHCP Server configured
[✓] SSL Certificate created
[✓] Snort IDS installed and running

TESTING:
[✓] SQL Injection successful
[✓] Cookie interception successful
[✓] Wireshark captures working
[✓] Snort alerts generated
[✓] CyberChef analysis working

DOCUMENTATION:
[✓] Network diagram exported
[✓] Screenshots collected
[✓] Wireshark captures saved
[✓] Snort logs exported
[✓] Configuration files backed up
```

---

## 🎉 SUCCESS CRITERIA

Your lab is **FULLY OPERATIONAL** when ALL of the following are true:

1. ✅ All 3 EC2 instances are running
2. ✅ pfSense web interface accessible from your IP
3. ✅ JuiceShop accessible from Kali browser
4. ✅ CyberChef accessible from Kali browser
5. ✅ DNS resolution working (after pfSense config)
6. ✅ DHCP leases visible in pfSense (after config)
7. ✅ Snort IDS generating alerts
8. ✅ Wireshark capturing traffic successfully
9. ✅ SQL injection attack successful
10. ✅ Cookie interception successful

**Total Setup Time:** 60-70 minutes  
**Lab Status:** ✅ **READY FOR COURSEWORK**

---

## 🚨 TROUBLESHOOTING QUICK REFERENCE

**Problem: Can't access pfSense**
→ Check admin_cidr in terraform.tfvars matches your current IP

**Problem: JuiceShop not responding**
→ SSH to Ubuntu, run: `docker restart juiceshop`

**Problem: CyberChef not loading**
→ SSH to Kali, run: `docker restart cyberchef`

**Problem: No internet on Kali/Ubuntu**
→ Verify pfSense instance is running and routes are correct

**Problem: Snort not generating alerts**
→ Wait 5 minutes after attack, check rules are downloaded and enabled

**Problem: DNS not working**
→ Verify pfSense DNS Resolver is configured and running

---

**Good luck with your cybersecurity coursework!** 🎓🔐

**Next Step:** Start with SQL Injection attack scenario to verify full lab functionality.
