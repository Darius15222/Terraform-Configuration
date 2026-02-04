output "router_public_ip" {
  description = "Public IP address to access router"
  value       = aws_eip.wan_eip.public_ip
}

output "router_web_interface" {
  description = "URL to access router web interface"
  value       = "https://${aws_eip.wan_eip.public_ip}"
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
  • WAN: ${var.admin_cidr} → Router (SSH/HTTP only)
  • Internal: All VPC traffic allowed between instances
  • Ubuntu: Port 3000 (JuiceShop) explicitly allowed from Kali
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
  Web: https://${aws_eip.wan_eip.public_ip}
  
  After SSH, check status:
    router-status
  
  📋 WHAT'S CONFIGURED (Automatic from pfSense XML)
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
     - LAN/OPT: Full access
  
  ✅ NAT: Internet access via WAN
  
  ✅ Snort IDS: Monitoring WAN interface
  
  🔍 VERIFY SETUP
  ════════════════════════════════════════════════════════════════
  1. Router web interface: https://${aws_eip.wan_eip.public_ip}
  2. SSH to router: See command above
  3. Check DHCP leases: cat /var/lib/misc/dnsmasq.leases
  4. Test from Kali: ping 10.0.3.100
  
  💰 COST SAVINGS
  ════════════════════════════════════════════════════════════════
  ✅ Using AWS credits (not marketplace charges)
  ✅ Ubuntu 24.04 LTS (free AMI)
  ✅ Only paying for EC2 compute
  
  📚 NEXT STEPS
  ════════════════════════════════════════════════════════════════
  - Access router and verify configuration
  - SSH to Kali/Ubuntu to test connectivity
  - Begin attack scenarios (JuiceShop)
  
  ════════════════════════════════════════════════════════════════
  EOT
}
