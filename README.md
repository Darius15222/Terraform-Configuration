# 🔐 Cybersecurity Lab - Ubuntu Router

**Educational penetration testing environment using AWS credits**

[![Infrastructure](https://img.shields.io/badge/Infrastructure-Terraform-623CE4.svg)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900.svg)](https://aws.amazon.com/)
[![Router](https://img.shields.io/badge/Router-Ubuntu_24.04-E95420.svg)](https://ubuntu.com/)

---

## 📖 Overview

Complete cybersecurity lab infrastructure with professional network services:
- **Ubuntu Router** - DHCP, DNS, NAT, Firewall, Snort IDS
- **Kali Linux** - Penetration testing workstation
- **Ubuntu Server** - OWASP JuiceShop vulnerable application

All services configured automatically, fully utilizing your AWS promotional credits.

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

## 💰 Cost Analysis

### Infrastructure Costs (Covered by AWS Credits)