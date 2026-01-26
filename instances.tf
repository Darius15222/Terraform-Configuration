# ============================================================
# PFSENSE FIREWALL INSTANCE
# ============================================================
# pfSense acts as the gateway/router for the lab environment
# - WAN interface: Public internet access
# - LAN interface: Routes Kali Linux subnet traffic
# - OPT interface: Routes Ubuntu server subnet traffic
resource "aws_instance" "pfsense" {
  ami           = var.pfsense_ami_ids[var.aws_region]
  instance_type = var.instance_types["pfsense"]
  key_name      = aws_key_pair.generated_key.key_name

  # Security: Enforce IMDSv2 to prevent SSRF attacks
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  # Security: Encrypt root volume
  root_block_device {
    encrypted = true
  }

  # Network: Attach three interfaces (WAN, LAN, OPT)
  network_interface {
    network_interface_id = aws_network_interface.wan_nic.id
    device_index         = 0
  }
  network_interface {
    network_interface_id = aws_network_interface.lan_nic.id
    device_index         = 1
  }
  network_interface {
    network_interface_id = aws_network_interface.opt_nic.id
    device_index         = 2
  }

  # Bootstrap: Configuration script (empty for now)
  user_data = file("${path.module}/pfsense-userdata.sh")
  
  tags = merge(local.common_tags, {
    Name = "pfsense-firewall"
    Role = "Gateway/Firewall"
  })
}

# ============================================================
# KALI LINUX INSTANCE
# ============================================================
# Kali Linux provides penetration testing tools
# - Located in private subnet behind pfSense
# - All traffic routes through pfSense LAN interface
resource "aws_instance" "kali" {
  ami                    = var.kali_ami_ids[var.aws_region]
  instance_type          = var.instance_types["kali"]
  key_name               = aws_key_pair.generated_key.key_name
  subnet_id              = aws_subnet.kali_subnet.id
  vpc_security_group_ids = [aws_security_group.kali_sg.id]
  private_ip             = local.kali_ip

  # Security: Enforce IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Security: Encrypt root volume
  root_block_device {
    encrypted = true
  }

  # Bootstrap: Configuration script (empty for now)
  user_data = file("${path.module}/kali-userdata.sh")

  # Ensure pfSense is ready before launching Kali
  depends_on = [
    aws_instance.pfsense,
    aws_eip.wan_eip
  ]

  tags = merge(local.common_tags, {
    Name = "kali-linux"
    Role = "Pentesting Workstation"
  })
}

# ============================================================
# UBUNTU SERVER INSTANCE (VULNERABLE TARGET)
# ============================================================
# Ubuntu server will host intentionally vulnerable applications
# - DVWA (Damn Vulnerable Web Application) - planned
# - OWASP WebGoat - planned
# - MySQL, FTP, NGINX services - planned
# - Located in private subnet behind pfSense
resource "aws_instance" "ubuntu" {
  ami                    = var.ubuntu_ami_ids[var.aws_region]
  instance_type          = var.instance_types["ubuntu"]
  key_name               = aws_key_pair.generated_key.key_name
  subnet_id              = aws_subnet.ubuntu_subnet.id
  vpc_security_group_ids = [aws_security_group.ubuntu_sg.id]
  private_ip             = local.ubuntu_ip

  # Security: Enforce IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Security: Encrypt root volume
  root_block_device {
    encrypted = true
  }

  # Bootstrap: Configuration script (empty for now)
  user_data = file("${path.module}/ubuntu-userdata.sh")

  # Ensure pfSense is ready before launching Ubuntu
  depends_on = [
    aws_instance.pfsense,
    aws_eip.wan_eip
  ]

  tags = merge(local.common_tags, {
    Name = "ubuntu-minimal-server"
    Role = "Vulnerable Target"
  })
}
