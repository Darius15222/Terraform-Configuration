output "pfsense_public_ip" {
  description = "Public IP address to access pfSense web interface"
  value       = aws_eip.wan_eip.public_ip
}

output "ssh_key_path" {
  description = "Path to the SSH private key file"
  value       = local_file.ssh_key.filename
}

output "pfsense_web_interface" {
  description = "URL to access pfSense web interface"
  value       = "https://${aws_eip.wan_eip.public_ip}"
}

output "kali_private_ip" {
  description = "Private IP address of Kali Linux instance"
  value       = aws_instance.kali.private_ip
}

output "ubuntu_private_ip" {
  description = "Private IP address of Ubuntu server instance"
  value       = aws_instance.ubuntu.private_ip
}

output "ssh_command_kali" {
  description = "SSH command to connect to Kali (via pfSense as jump host)"
  value       = "ssh -i ${local_file.ssh_key.filename} -J admin@${aws_eip.wan_eip.public_ip} kali@${aws_instance.kali.private_ip}"
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
                  │   pfSense Firewall        │
                  │   WAN: ${var.subnet_cidrs["wan"]}     │
                  │   Access: HTTPS/SSH       │
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
  │   Role: Pentesting   │      │   Role: Target       │
  └──────────────────────┘      └──────────────────────┘
  
  ═══════════════════════════════════════════════════════════════
  Security Groups:
  • WAN: ${var.admin_cidr} → pfSense (SSH/HTTPS only)
  • Internal: All VPC traffic allowed between instances
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
    pfsense_wan_ip    = aws_eip.wan_eip.public_ip
    pfsense_lan_ip    = local.pfsense_lan_ip
    pfsense_opt_ip    = local.pfsense_opt_ip
    kali_ip           = local.kali_ip
    ubuntu_ip         = local.ubuntu_ip
    project           = var.project_name
    environment       = var.environment
  }
}

output "access_instructions" {
  description = "Quick access guide"
  value = <<-EOT
  
  ╔════════════════════════════════════════════════════════════════╗
  ║                      ACCESS INSTRUCTIONS                        ║
  ╚════════════════════════════════════════════════════════════════╝
  
  1. pfSense Web Interface:
     URL: https://${aws_eip.wan_eip.public_ip}
     Default credentials: admin / pfsense
     ⚠️  CHANGE PASSWORD IMMEDIATELY!
  
  2. SSH to pfSense:
     ssh -i ${local_file.ssh_key.filename} admin@${aws_eip.wan_eip.public_ip}
  
  3. SSH to Kali (via pfSense jump host):
     ssh -i ${local_file.ssh_key.filename} -J admin@${aws_eip.wan_eip.public_ip} kali@${local.kali_ip}
  
  4. SSH to Ubuntu (via pfSense jump host):
     ssh -i ${local_file.ssh_key.filename} -J admin@${aws_eip.wan_eip.public_ip} ubuntu@${local.ubuntu_ip}
  
  ═══════════════════════════════════════════════════════════════
  💡 Tip: Configure pfSense firewall rules to control traffic
         between Kali and Ubuntu subnets
  ═══════════════════════════════════════════════════════════════
  EOT
}
