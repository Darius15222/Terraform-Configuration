# ============================================================
# ROUTER WAN SECURITY GROUP
# ============================================================
# Controls access to Ubuntu Router from the internet
# - SSH (22): Admin access from specified IP
# - HTTP (80): Lets Encrypt certificate validation (when domain configured)
# - HTTPS (443): Web interface access from specified IP
resource "aws_security_group" "pfsense_wan_sg" {
  name        = "router-wan-sg"
  description = "Security group for Router WAN interface - external access"
  vpc_id      = aws_vpc.main.id

  # SSH access from admin IP only
  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # HTTP for Lets Encrypt certificate validation (only if domain configured)
  # [FIX] Removed apostrophe from "Let's" to fix AWS validation error
  dynamic "ingress" {
    for_each = var.domain_name != "" ? [1] : []
    content {
      description = "HTTP for Lets Encrypt certificate validation"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # HTTPS access to web interface from admin IP only
  ingress {
    description = "HTTPS from admin IP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # Allow all outbound traffic (router needs internet access)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "router-wan-sg"
    Role = "Router WAN Interface"
  })
}

# ============================================================
# ROUTER INTERNAL SECURITY GROUP
# ============================================================
# Controls access to Router LAN and OPT interfaces
# - Allows all traffic from within the VPC
resource "aws_security_group" "pfsense_internal_sg" {
  name        = "router-internal-sg"
  description = "Security group for Router LAN/OPT interfaces - internal traffic"
  vpc_id      = aws_vpc.main.id

  # Allow all traffic from VPC (LAN and OPT subnets)
  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "router-internal-sg"
    Role = "Router Internal Interfaces"
  })
}

# ============================================================
# KALI LINUX SECURITY GROUP
# ============================================================
# Controls access to Kali Linux instance
# - Only accepts traffic from VPC (via Router)
# - Needs outbound access for updates and tool downloads
resource "aws_security_group" "kali_sg" {
  name        = "kali-sg"
  description = "Security group for Kali Linux instance"
  vpc_id      = aws_vpc.main.id

  # Allow all traffic from VPC (primarily from Router LAN interface)
  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound (needs to reach internet via Router)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "kali-sg"
    Role = "Pentesting Workstation"
  })
}

# ============================================================
# UBUNTU SERVER SECURITY GROUP
# ============================================================
# Controls access to Ubuntu server (vulnerable target)
# - JuiceShop on port 3000 accessible from Kali subnet
# - SSH accessible from VPC for management
# - ICMP for connectivity testing
resource "aws_security_group" "ubuntu_sg" {
  name        = "ubuntu-sg"
  description = "Security group for Ubuntu vulnerable server"
  vpc_id      = aws_vpc.main.id

  # Allow JuiceShop access from Kali subnet
  ingress {
    description = "JuiceShop from Kali subnet"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.subnet_cidrs["kali"]]
  }

  # Allow SSH from VPC for management
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow ICMP (ping) from VPC for connectivity testing
  ingress {
    description = "ICMP from VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound (needs internet via Router for Docker pulls)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "ubuntu-sg"
    Role = "Vulnerable Target"
  })
}

# ============================================================
# DEFAULT SECURITY GROUP (LOCKED DOWN)
# ============================================================
# AWS creates a default SG for every VPC
# Lock it down to prevent accidental use
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # No ingress rules
  # No egress rules

  tags = merge(local.common_tags, {
    Name = "default-deny-all"
    Note = "Default SG - intentionally locked down"
  })
}