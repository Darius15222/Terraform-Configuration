# 🔐 Cybersecurity Lab - AWS Infrastructure

**Educational penetration testing environment built with Terraform**

[![Security Audit](https://img.shields.io/badge/Security-76%25-green.svg)](SECURITY_AUDIT_REPORT.md)
[![Infrastructure](https://img.shields.io/badge/Infrastructure-Terraform-623CE4.svg)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900.svg)](https://aws.amazon.com/)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-success.svg)](AUDIT_SUMMARY.md)

---

## 📖 Overview

This project deploys a complete cybersecurity lab environment on AWS for educational purposes. It includes a pfSense firewall, Kali Linux penetration testing workstation, and Ubuntu server running vulnerable applications for security testing.

### 🎯 Purpose

Created for the "System Protection Applications" university course to provide hands-on experience with:
- Network security and firewall configuration
- Penetration testing methodologies
- Vulnerability assessment
- Traffic analysis and intrusion detection
- Infrastructure as Code best practices

---

## 🏗️ Architecture

```
                    INTERNET
                       │
                       │ Public IP: Elastic IP
                       ▼
            ┌─────────────────────┐
            │  pfSense Firewall   │
            │  - DNS Server       │
            │  - DHCP Server      │
            │  - Snort IDS        │
            │  - NAT/Routing      │
            └──────────┬──────────┘
                       │
          ┌────────────┴────────────┐
          │                         │
          ▼                         ▼
   ┌─────────────┐          ┌─────────────┐
   │ Kali Linux  │          │   Ubuntu    │
   │  (Attacker) │          │   (Target)  │
   │             │          │             │
   │ - Wireshark │─────────▶│ - JuiceShop │
   │ - CyberChef │          │ - Docker    │
   │ - Burp Suite│          │             │
   └─────────────┘          └─────────────┘
   10.0.2.0/24               10.0.3.0/24
```

---

## ✨ Features

### 🔥 Network Security
- **pfSense Firewall** - Multi-interface routing and NAT
- **Snort IDS** - Real-time intrusion detection
- **Network Segmentation** - Isolated subnets for attacker/target
- **DNS/DHCP Services** - Centralized network services

### 🛠️ Penetration Testing
- **Kali Linux** - Full suite of pentesting tools
- **OWASP JuiceShop** - Intentionally vulnerable web application
- **Wireshark** - Packet capture and analysis
- **Burp Suite** - HTTP/HTTPS interception
- **CyberChef** - Data encoding/decoding and analysis

### 🔒 Security Hardening
- **IMDSv2 Enforced** - SSRF attack prevention
- **EBS Encryption** - Data at rest protection
- **Restricted Access** - IP-based admin access control
- **Private Subnets** - No direct internet exposure
- **Security Groups** - Defense-in-depth network filtering

### 📚 Infrastructure as Code
- **Terraform** - Reproducible deployments
- **Automated Setup** - Docker-based service deployment
- **Version Controlled** - Git-friendly configuration
- **Well Documented** - Comprehensive guides included

---

## 🚀 Quick Start

### Prerequisites

- AWS account with configured credentials
- Terraform v1.0+ installed
- Your public IP address ([check here](https://whatismyip.com))

### Deployment (5 commands)

```bash
# 1. Clone repository
git clone <your-repo-url>
cd cybersecurity-lab

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

**Total deployment time:** ~15 minutes (5 min Terraform + 10 min user-data)

---

## 📋 Services Deployed

| Service | Location | Port | Purpose |
|---------|----------|------|---------|
| **pfSense** | Public IP | 443 | Firewall management |
| **JuiceShop** | Ubuntu | 3000 | Vulnerable web app |
| **CyberChef** | Kali | 8000 | Data analysis tool |
| **Snort IDS** | pfSense | - | Intrusion detection |
| **DNS Server** | pfSense | 53 | Name resolution |
| **DHCP Server** | pfSense | 67 | IP address management |

---

## 📚 Documentation

### 📖 Essential Guides

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Complete deployment walkthrough
- **[FINAL_TESTING_CHECKLIST.md](FINAL_TESTING_CHECKLIST.md)** - 100+ verification steps
- **[SECURITY_AUDIT_REPORT.md](SECURITY_AUDIT_REPORT.md)** - Security posture analysis
- **[AUDIT_SUMMARY.md](AUDIT_SUMMARY.md)** - Comprehensive audit results

### 🛠️ Configuration Files

- **[pfsense-userdata.sh](pfsense-userdata.sh)** - pfSense configuration guide (DNS, DHCP, Cert, Snort)
- **[ubuntu-userdata.sh](ubuntu-userdata.sh)** - JuiceShop deployment automation
- **[kali-userdata.sh](kali-userdata.sh)** - CyberChef deployment automation

### 📄 Infrastructure Code

```
├── providers.tf          # Terraform and AWS provider config
├── variables.tf          # Input variables and validation
├── locals.tf             # Computed values and tags
├── data.tf               # Data sources (AMIs, AZs)
├── networking.tf         # VPC, subnets, network interfaces
├── security.tf           # Security groups
├── routing.tf            # Route tables and associations
├── keys.tf               # SSH key generation
├── instances.tf          # EC2 instances
└── outputs.tf            # Output values
```

---

## 🎓 Educational Use Cases

### Network Security
- Configure firewall rules in pfSense
- Set up DNS and DHCP services
- Implement network segmentation
- Monitor traffic with Snort IDS
- Analyze packets with Wireshark

### Penetration Testing
- SQL Injection attacks on JuiceShop
- Cross-Site Scripting (XSS)
- Session hijacking and cookie theft
- Broken authentication exploitation
- Traffic interception with Burp Suite

### Security Analysis
- Decode JWT tokens with CyberChef
- Analyze encrypted traffic
- Investigate Snort IDS alerts
- Document attack methodologies
- Practice incident response

---

## 💰 Cost

### Running Costs

```
Component          Instance Type    Cost/Hour    Cost/Day
──────────────────────────────────────────────────────────
pfSense            t3.small         $0.0208      $0.50
Kali Linux         t3.small         $0.0208      $0.50
Ubuntu Server      t3.micro         $0.0104      $0.25
Elastic IP         -                $0.005       $0.12
──────────────────────────────────────────────────────────
TOTAL (if running 24/7):            $0.30/hour   $7.20/day
```

### Cost Optimization

**💡 Stop instances when not in use:** $0/hour when stopped

```bash
# Stop all instances (keeps data, no compute charges)
aws ec2 stop-instances --instance-ids \
  $(terraform output -json instance_ids | jq -r '.[]')

# Start when needed
aws ec2 start-instances --instance-ids <instance-ids>
```

**Estimated actual cost:** $5-10/month (3-4 hours/week usage)

---

## 🔐 Security

### Security Posture: 76% (Checkov Scan)

✅ **Implemented Security Controls:**
- IMDSv2 enforced (SSRF prevention)
- EBS volume encryption
- Network isolation (private subnets)
- Security group restrictions
- Admin IP whitelisting
- SSH key authentication (4096-bit RSA)

### Security Scan Results

```
Total Checks: 62
Passed: 47 (76%)
Failed: 15 (intentional cost optimizations)
Critical Issues: 0
```

See [SECURITY_AUDIT_REPORT.md](SECURITY_AUDIT_REPORT.md) for detailed analysis.

---

## 🧪 Testing

### Automated Tests

```bash
# Run security scan
checkov -d . --framework terraform

# Validate Terraform
terraform validate

# Check formatting
terraform fmt -check
```

### Manual Verification

Complete testing checklist available in [FINAL_TESTING_CHECKLIST.md](FINAL_TESTING_CHECKLIST.md)

---

## 🛠️ Configuration

### After Deployment

**pfSense requires manual configuration (50 minutes):**

1. **DNS Resolver** (5 min) - Services > DNS Resolver
2. **DHCP Server** (10 min) - Services > DHCP Server  
3. **SSL Certificate** (5 min) - System > Cert Manager
4. **Snort IDS** (30 min) - System > Package Manager

See [pfsense-userdata.sh](pfsense-userdata.sh) for detailed step-by-step guide.

---

## 📊 Project Structure

```
cybersecurity-lab/
├── README.md                      # This file
├── DEPLOYMENT_GUIDE.md            # Complete deployment guide
├── FINAL_TESTING_CHECKLIST.md     # Verification checklist
├── SECURITY_AUDIT_REPORT.md       # Security analysis
├── AUDIT_SUMMARY.md               # Audit results summary
│
├── *.tf                           # Terraform configuration files
├── *-userdata.sh                  # Instance initialization scripts
├── terraform.tfvars.example       # Example variables file
├── .gitignore                     # Git ignore rules
│
└── .terraform.lock.hcl            # Terraform provider lock file
```

---

## 🎯 Success Criteria

Your lab is fully operational when:

- ✅ All 3 EC2 instances running
- ✅ pfSense web interface accessible
- ✅ JuiceShop accessible from Kali
- ✅ CyberChef accessible from Kali
- ✅ DNS resolution working
- ✅ DHCP leases assigned
- ✅ Snort IDS generating alerts
- ✅ Wireshark capturing traffic
- ✅ SQL injection attack successful
- ✅ Cookie interception working

---

## 🚨 Troubleshooting

### Common Issues

**Can't access pfSense:**
→ Check `admin_cidr` in `terraform.tfvars` matches your current IP

**JuiceShop not responding:**
→ SSH to Ubuntu, run: `docker restart juiceshop`

**No internet on Kali/Ubuntu:**
→ Verify pfSense instance is running and routes are correct

**Snort not generating alerts:**
→ Wait 5 minutes after attack, verify rules downloaded

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) troubleshooting section for more.

---

## 🧹 Cleanup

### Destroy Infrastructure

```bash
# ⚠️ WARNING: This deletes ALL resources and data
terraform destroy

# Type: yes
```

### Verify Cleanup

```bash
# Check no resources remain
terraform state list
# Expected: empty

# Check AWS console
aws ec2 describe-instances --filters "Name=tag:Project,Values=CyberLab"
# Expected: no instances
```

---

## 📝 License

This project is created for educational purposes as part of university coursework.

---

## 🤝 Contributing

This is an educational project. Improvements welcome:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📞 Support

### Documentation
- Start with [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- Check [FINAL_TESTING_CHECKLIST.md](FINAL_TESTING_CHECKLIST.md) for verification
- Review [SECURITY_AUDIT_REPORT.md](SECURITY_AUDIT_REPORT.md) for security info

### Quick Reference

```bash
# Get all outputs
terraform output

# Get specific IP
terraform output pfsense_public_ip

# SSH to instances
terraform output -json ssh_commands

# View network architecture
terraform output network_architecture
```

---

## 🎓 Academic Context

**Course:** System Protection Applications  
**Institution:** University of Sibiu, Romania  
**Purpose:** Hands-on cybersecurity education  
**Topics Covered:**
- Network security architecture
- Firewall configuration
- Intrusion detection systems
- Penetration testing methodologies
- Vulnerability assessment
- Traffic analysis and forensics

---

## ⚠️ Disclaimer

This infrastructure is designed for **educational purposes only**. The vulnerable applications (JuiceShop) are intentionally insecure and should **never** be exposed to the public internet or used in production environments.

**Use responsibly:**
- ✅ Educational learning
- ✅ Controlled lab environment
- ✅ Personal skill development
- ❌ Production workloads
- ❌ Storing sensitive data
- ❌ Public internet exposure

---

## 🏆 Acknowledgments

**Technologies:**
- [Terraform](https://www.terraform.io/) - Infrastructure as Code
- [pfSense](https://www.pfsense.org/) - Open-source firewall
- [Kali Linux](https://www.kali.org/) - Penetration testing distribution
- [OWASP JuiceShop](https://owasp.org/www-project-juice-shop/) - Vulnerable web app
- [CyberChef](https://gchq.github.io/CyberChef/) - Data analysis tool
- [Snort](https://www.snort.org/) - Intrusion detection system
- [AWS](https://aws.amazon.com/) - Cloud infrastructure

**Security Tools:**
- [Checkov](https://www.checkov.io/) - Infrastructure security scanner
- [Wireshark](https://www.wireshark.org/) - Network protocol analyzer
- [Burp Suite](https://portswigger.net/burp) - Web security testing

---

## 📈 Project Status

- ✅ **Infrastructure:** Complete and tested
- ✅ **Documentation:** Comprehensive guides provided
- ✅ **Security Audit:** 76% compliance achieved
- ✅ **Testing:** All scenarios documented
- ✅ **Ready for Use:** Approved for deployment

**Last Updated:** January 29, 2026  
**Status:** Production Ready ✅

---

**Made with ❤️ for cybersecurity education**
