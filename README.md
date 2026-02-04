# 🔐 Cybersecurity Lab - Ubuntu Router Version

**Educational penetration testing environment - NOW USING AWS CREDITS!**

[![Infrastructure](https://img.shields.io/badge/Infrastructure-Terraform-623CE4.svg)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900.svg)](https://aws.amazon.com/)
[![Router](https://img.shields.io/badge/Router-Ubuntu_24.04-E95420.svg)](https://ubuntu.com/)

---

## 🎉 What Changed

**Replaced pfSense Plus with Ubuntu 24.04 LTS**

**Result:** Uses your $200 AWS credits (saves ~$30/month)!

---

## 📖 Overview

Complete cybersecurity lab with:
- **Ubuntu Router** - DHCP, DNS, NAT, Firewall, Snort IDS
- **Kali Linux** - Penetration testing workstation
- **Ubuntu Server** - OWASP JuiceShop vulnerable application

All pfSense functionality preserved, zero marketplace charges.

---

## ✨ Features

### 🔥 Network Services (Ubuntu Router)
- **DHCP Server** (dnsmasq) - Automatic IP assignment
- **DNS Resolver** (dnsmasq) - Domain: cyberlab.local
- **NAT/Routing** (iptables) - Internet access for internal networks
- **Firewall** (iptables) - Access control
- **Snort IDS** - Intrusion detection

### 🛠️ Penetration Testing
- **Kali Linux** - Full suite of pentesting tools
- **OWASP JuiceShop** - Vulnerable web application
- **Wireshark** - Packet capture and analysis
- **Burp Suite** - HTTP/HTTPS interception
- **CyberChef** - Data encoding/decoding

### 🔒 Security Hardening
- **IMDSv2 Enforced** - SSRF attack prevention
- **EBS Encryption** - Data at rest protection
- **Restricted Access** - IP-based admin access control
- **Private Subnets** - No direct internet exposure

---

## 🚀 Quick Start

### Prerequisites

- AWS account with configured credentials
- Terraform v1.0+ installed
- Your public IP address ([check here](https://whatismyip.com))

### Deployment (5 commands)

```bash
# 1. Clone/extract files to your project directory

# 2. Configure your admin IP
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: admin_cidr = "YOUR_IP/32"

# 3. Initialize Terraform
terraform init

# 4. Review deployment plan
terraform plan

# 5. Deploy infrastructure
terraform apply
```

**Total deployment time:** ~15 minutes (5 min Terraform + 10 min auto-config)

---

## 💰 Cost Comparison

### Before (pfSense)
```
EC2:          $0.0208/hour
Marketplace:  $0.04/hour (NOT covered by credits)
-------------------------
Total:        $0.0608/hour = $44/month
Your cost:    ~$30/month
```

### After (Ubuntu Router)
```
EC2:          $0.0208/hour
Marketplace:  $0/hour
-------------------------
Total:        $0.0208/hour = $15/month
Credits:      FULLY APPLIED
Your cost:    $0 (covered by your $200 credits)
```

**Savings:** ~$30/month or $360/year! 🎉

---

## 📋 What's Configured (from pfSense XML)

Everything from your pfSense configuration was replicated:

### Network Configuration
- **WAN:** 10.0.1.0/24 (DHCP)
- **LAN:** 10.0.2.10/24 (Kali network)
- **OPT1:** 10.0.3.10/24 (Ubuntu network)

### DHCP Server
```
LAN:
  Range: 10.0.2.100-200
  Gateway: 10.0.2.10
  DNS: 10.0.2.10
  Domain: cyberlab.local

OPT1:
  Range: 10.0.3.100-200
  Gateway: 10.0.3.10
  DNS: 10.0.3.10
  Domain: cyberlab.local
```

### DNS Resolver
- Domain: cyberlab.local
- Upstream: 8.8.8.8, 8.8.4.4
- DNSSEC: Enabled

### Firewall Rules
```
WAN:  SSH (22), HTTP (80) from admin_cidr
LAN:  Allow all from 10.0.2.0/24
OPT1: Allow all from 10.0.3.0/24
NAT:  Masquerade to WAN
```

### Snort IDS
- Monitoring: WAN interface
- Rules: Community rules
- Logging: /var/log/snort/alert

---

## 📚 Access Information

### Router
```bash
# SSH
ssh -i lab-key.pem ubuntu@<public-ip>

# Web Interface
https://<public-ip>

# Check status
router-status
```

### Kali Linux
```bash
# SSH (via router jump)
ssh -i lab-key.pem -J ubuntu@<public-ip> kali@10.0.2.100

# JuiceShop
http://10.0.3.100:3000

# CyberChef
http://localhost:8000 (from Kali browser)
```

### Ubuntu Server
```bash
# SSH (via router jump)
ssh -i lab-key.pem -J ubuntu@<public-ip> ubuntu@10.0.3.100

# Check JuiceShop
docker ps
docker logs juiceshop
```

---

## ✅ Verification Checklist

After deployment, verify:

### Router
- ✅ SSH access works
- ✅ Web interface shows status
- ✅ `router-status` command works

### DHCP Leases
- ✅ Kali has IP 10.0.2.100
- ✅ Ubuntu has IP 10.0.3.100
- Check: `cat /var/lib/misc/dnsmasq.leases`

### DNS Resolution
- ✅ `nslookup google.com` works from Kali
- ✅ `nslookup google.com` works from Ubuntu
- Server should be 10.0.2.10 (Kali) or 10.0.3.10 (Ubuntu)

### Internet Access
- ✅ `ping 8.8.8.8` works from Kali
- ✅ `curl http://google.com` works from Ubuntu

### Services
- ✅ JuiceShop accessible from Kali
- ✅ CyberChef accessible from Kali
- ✅ Snort IDS running on router

---

## 🔧 Management Commands

### Router Status
```bash
router-status                          # Full status
cat /var/lib/misc/dnsmasq.leases      # DHCP leases
iptables -L -n -v                      # Firewall rules
systemctl status snort                 # Snort IDS
tail -f /var/log/snort/alert          # Snort alerts
```

### Restart Services
```bash
systemctl restart dnsmasq     # DHCP+DNS
systemctl restart snort        # IDS
systemctl restart nginx        # Web interface
```

### Edit Configuration
```bash
# DHCP/DNS
sudo nano /etc/dnsmasq.conf
sudo systemctl restart dnsmasq

# Firewall
sudo nano /etc/iptables/rules.v4
sudo iptables-restore < /etc/iptables/rules.v4
```

---

## 🛠️ Troubleshooting

### Can't access router

```bash
# Check instance state
aws ec2 describe-instances --filters "Name=tag:Name,Values=ubuntu-router"

# Verify your IP is allowed
terraform output deployment_summary
```

### DHCP not working

```bash
# On router, check dnsmasq
systemctl status dnsmasq
journalctl -u dnsmasq -n 50
```

### No internet from Kali/Ubuntu

```bash
# On router, check NAT
iptables -t nat -L -n -v

# Should see MASQUERADE rule
```

---

## 📊 Project Structure

```
cybersecurity-lab/
├── README.md                      # This file
├── MIGRATION_GUIDE.md             # pfSense → Ubuntu migration details
│
├── main.tf                        # Project documentation
├── providers.tf                   # AWS provider configuration
├── variables.tf                   # Variables (Ubuntu AMI)
├── locals.tf                      # Computed values
├── data.tf                        # Data sources
├── networking.tf                  # VPC, subnets, NICs
├── security.tf                    # Security groups
├── routing.tf                     # Route tables
├── keys.tf                        # SSH keys
├── instances.tf                   # EC2 instances
├── outputs.tf                     # Outputs
│
├── router-userdata.sh             # Router configuration
├── kali-userdata.sh               # Kali setup
├── ubuntu-userdata.sh             # JuiceShop deployment
│
└── terraform.tfvars.example       # Example variables
```

---

## 🎓 Educational Use Cases

### Network Administration
- DHCP configuration
- DNS resolution
- NAT and routing
- Firewall rule management

### Penetration Testing
- SQL injection attacks
- XSS exploitation
- Session hijacking
- Traffic analysis

### Security Monitoring
- IDS configuration
- Alert analysis
- Packet capture
- Forensics

---

## 💾 Maintenance

### Start All Instances
```bash
terraform output -json instance_ids | jq -r '.[]' | xargs aws ec2 start-instances --instance-ids
```

### Stop All Instances (save money!)
```bash
terraform output -json instance_ids | jq -r '.[]' | xargs aws ec2 stop-instances --instance-ids
```

### Destroy Infrastructure
```bash
terraform destroy
```

---

## 📝 Documentation

- **MIGRATION_GUIDE.md** - Detailed pfSense → Ubuntu migration info
- **router-userdata.sh** - Router configuration script (commented)
- All Terraform files have inline comments

---

## ⚠️ Disclaimer

Educational purposes only. Never expose to public internet or use in production.

---

## 🏆 Acknowledgments

**Technologies:**
- [Terraform](https://www.terraform.io/)
- [Ubuntu](https://ubuntu.com/)
- [Kali Linux](https://www.kali.org/)
- [OWASP JuiceShop](https://owasp.org/www-project-juice-shop/)
- [Snort](https://www.snort.org/)
- [AWS](https://aws.amazon.com/)

---

**Made with ❤️ for cybersecurity education - Now using AWS credits!** 🎉
