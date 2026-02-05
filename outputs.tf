output "router_public_ip" {
  description = "Public IP address to access router"
  value       = aws_eip.wan_eip.public_ip
}

output "router_web_interface" {
  description = "URL to access router web interface"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_eip.wan_eip.public_ip}"
}

output "ssl_certificate_info" {
  description = "SSL certificate information"
  value = {
    type         = var.domain_name != "" ? "Let's Encrypt (Auto-renewing)" : "Self-Signed"
    domain       = var.domain_name != "" ? var.domain_name : "None (using IP)"
    access_url   = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_eip.wan_eip.public_ip}"
    auto_renewal = var.domain_name != "" ? "Enabled (certbot checks twice daily)" : "N/A"
    note         = var.domain_name != "" ? "No browser warnings - Real SSL certificate" : "Browser will show security warning (expected for self-signed)"
  }
}

output "ami_information" {
  description = "AMI IDs used for deployment (dynamically fetched latest versions)"
  value = {
    router_ami      = data.aws_ami.ubuntu_router.id
    router_ami_name = data.aws_ami.ubuntu_router.name
    kali_ami        = data.aws_ami.kali.id
    kali_ami_name   = data.aws_ami.kali.name
    ubuntu_ami      = data.aws_ami.ubuntu_server.id
    ubuntu_ami_name = data.aws_ami.ubuntu_server.name
  }
}

output "ssh_key_path" {
  description = "Path to the SSH private key file"
  value       = local_file.ssh_key.filename
}

output "kali_private_ip" {
  description = "Private IP address of Kali Linux instance"
  value       = aws_instance.kali.private_ip
}

output "ubuntu_private_ip" {
  description = "Private IP address of Ubuntu server instance"
  value       = aws_instance.ubuntu.private_ip
}

output "juiceshop_url" {
  description = "URL to access JuiceShop from Kali Linux"
  value       = "http://${aws_instance.ubuntu.private_ip}:3000"
}

output "cyberchef_url" {
  description = "CyberChef URL (accessible from Kali Linux)"
  value       = "http://localhost:8000 (access from Kali browser)"
}

output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = {
    router = "ssh -i ${local_file.ssh_key.filename} ubuntu@${aws_eip.wan_eip.public_ip}"
    kali   = "ssh -i ${local_file.ssh_key.filename} -J ubuntu@${aws_eip.wan_eip.public_ip} kali@${aws_instance.kali.private_ip}"
    ubuntu = "ssh -i ${local_file.ssh_key.filename} -J ubuntu@${aws_eip.wan_eip.public_ip} ubuntu@${aws_instance.ubuntu.private_ip}"
  }
}

output "instance_ids" {
  description = "EC2 Instance IDs for management"
  value = {
    router = aws_instance.router.id
    kali   = aws_instance.kali.id
    ubuntu = aws_instance.ubuntu.id
  }
}

output "network_architecture" {
  description = "Visual guide to network layout"
  value = <<-EOT
  
  ╔════════════════════════════════════════════════════════════════╗
  ║                      NETWORK ARCHITECTURE                       ║
  ╚════════════════════════════════════════════════════════════════╝
  
  ┌──────────────────────────────────────────────────────────────┐
  │                         INTERNET                              │
  └─────────────────────────────┬────────────────────────────────┘
                                │
                                │ Public IP: ${aws_eip.wan_eip.public_ip}
                                │ ${var.domain_name != "" ? "Domain: ${var.domain_name}" : ""}
                                │
                  ┌─────────────▼─────────────┐
                  │   Ubuntu Router           │
                  │   WAN: ${var.subnet_cidrs["wan"]}        │
                  │   Services:               │
                  │   - DHCP (dnsmasq)        │
                  │   - DNS (dnsmasq)         │
                  │   - NAT (iptables)        │
                  │   - Firewall (iptables)   │
                  │   - Snort IDS             │
                  │   - ${var.domain_name != "" ? "Let's Encrypt SSL" : "Self-Signed SSL"}    │
                  └───────────┬───────────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
              ▼                               ▼
  ┌──────────────────────┐      ┌──────────────────────┐
  │  LAN (Kali Subnet)   │      │  OPT (Ubuntu Subnet) │
  │  ${var.subnet_cidrs["kali"]}           │      │  ${var.subnet_cidrs["ubuntu"]}           │
  │                      │      │                      │
  │  Gateway: ${local.pfsense_lan_ip}     │      │  Gateway: ${local.pfsense_opt_ip}     │
  └──────────┬───────────┘      └──────────┬───────────┘
             │                             │
             ▼                             ▼
  ┌──────────────────────┐      ┌──────────────────────┐
  │   Kali Linux         │      │   Ubuntu Server      │
  │   IP: ${local.kali_ip}       │      │   IP: ${local.ubuntu_ip}       │
  │   Role: Attacker     │      │   Role: Target       │
  │   Tools:             │      │   Services:          │
  │   - Wireshark        │      │   - JuiceShop:3000   │
  │   - CyberChef:8000   │      │   - Docker           │
  │   - Burp Suite       │      │                      │
  └──────────────────────┘      └──────────────────────┘
  
  ═══════════════════════════════════════════════════════════════
  Security Groups:
  • WAN: ${var.admin_cidr} → Router (SSH/HTTPS${var.domain_name != "" ? "/HTTP*" : ""})
  ${var.domain_name != "" ? "  *HTTP only for Let's Encrypt certificate validation" : ""}
  • Internal: All VPC traffic allowed between instances
  • Ubuntu: Port 3000, SSH, ICMP explicitly allowed
  • Egress: Unrestricted (required for lab functionality)
  ═══════════════════════════════════════════════════════════════
  EOT
}

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    region            = var.aws_region
    vpc_cidr          = var.vpc_cidr
    availability_zone = data.aws_availability_zones.available.names[0]
    router_wan_ip     = aws_eip.wan_eip.public_ip
    router_lan_ip     = local.pfsense_lan_ip
    router_opt_ip     = local.pfsense_opt_ip
    kali_ip           = local.kali_ip
    ubuntu_ip         = local.ubuntu_ip
    juiceshop_port    = 3000
    cyberchef_port    = 8000
    ssl_type          = var.domain_name != "" ? "Let's Encrypt" : "Self-Signed"
    domain            = var.domain_name != "" ? var.domain_name : "None"
    project           = var.project_name
    environment       = var.environment
  }
}

output "quick_start" {
  description = "Quick start commands"
  value = <<-EOT
  
  ╔════════════════════════════════════════════════════════════════╗
  ║                    QUICK START GUIDE                            ║
  ╚════════════════════════════════════════════════════════════════╝
  
  🚀 ROUTER ACCESS
  ════════════════════════════════════════════════════════════════
  SSH: ssh -i ${local_file.ssh_key.filename} ubuntu@${aws_eip.wan_eip.public_ip}
  Web: ${var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_eip.wan_eip.public_ip}"}
  
  ${var.domain_name != "" ? "✅ Let's Encrypt SSL - No browser warnings!" : "⚠️  Self-Signed SSL - Browser will show security warning (expected)"}
  
  After SSH, check status:
    router-status
  
  📋 WHAT'S CONFIGURED (Automatic)
  ════════════════════════════════════════════════════════════════
  ✅ DHCP Server:
     - LAN:  10.0.2.100-200 (for Kali)
     - OPT1: 10.0.3.100-200 (for Ubuntu)
  
  ✅ DNS Resolver:
     - Domain: cyberlab.local
     - Upstream: 8.8.8.8, 8.8.4.4
     - DNSSEC: Enabled
  
  ✅ Firewall:
     - WAN: SSH/HTTPS from ${var.admin_cidr}
     ${var.domain_name != "" ? "- HTTP (80): Let's Encrypt validation only" : ""}
     - LAN/OPT: Full access
  
  ✅ NAT: Internet access via WAN
  
  ✅ Snort IDS: Monitoring WAN interface
  
  ✅ SSL Certificate: ${var.domain_name != "" ? "Let's Encrypt (Auto-renewing)" : "Self-Signed (10-year)"}
  
  ${var.domain_name != "" ? "🔐 SSL CERTIFICATE MANAGEMENT\n════════════════════════════════════════════════════════════════\n  certbot certificates       - Show certificate details\n  certbot renew --dry-run    - Test renewal\n  systemctl status certbot.timer - Check auto-renewal status\n" : ""}
  🔍 VERIFY SETUP
  ════════════════════════════════════════════════════════════════
  1. Router web interface: ${var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_eip.wan_eip.public_ip}"}
  2. SSH to router: See command above
  3. Check DHCP leases: cat /var/lib/misc/dnsmasq.leases
  4. Test from Kali: ping 10.0.3.100
  
  💰 COST SAVINGS
  ════════════════════════════════════════════════════════════════
  ✅ Using AWS credits (not marketplace charges)
  ✅ Ubuntu 24.04 LTS (free AMI)
  ✅ Only paying for EC2 compute
  ✅ Dynamic AMI selection (always latest versions)
  
  📚 NEXT STEPS
  ════════════════════════════════════════════════════════════════
  - Access router and verify configuration
  - SSH to Kali/Ubuntu to test connectivity
  - Begin attack scenarios (JuiceShop)
  
  ════════════════════════════════════════════════════════════════
  EOT
}
