resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "cyber-lab-vpc"
  })
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "cyber-lab-igw"
  })
}

# ============================================================
# SUBNETS
# ============================================================
resource "aws_subnet" "wan" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs["wan"]
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "subnet-wan"
    Tier = "Public"
  })
}

resource "aws_subnet" "kali_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidrs["kali"]
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(local.common_tags, {
    Name = "subnet-kali"
    Tier = "Private"
  })
}

resource "aws_subnet" "ubuntu_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidrs["ubuntu"]
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(local.common_tags, {
    Name = "subnet-ubuntu"
    Tier = "Private"
  })
}

# ============================================================
# NETWORK INTERFACES
# ============================================================
resource "aws_network_interface" "wan_nic" {
  subnet_id         = aws_subnet.wan.id
  security_groups   = [aws_security_group.pfsense_wan_sg.id]
  source_dest_check = false

  tags = merge(local.common_tags, {
    Name = "pfsense-wan-nic"
  })
}

resource "aws_network_interface" "lan_nic" {
  subnet_id         = aws_subnet.kali_subnet.id
  security_groups   = [aws_security_group.pfsense_internal_sg.id]
  source_dest_check = false
  private_ips       = [local.pfsense_lan_ip]

  tags = merge(local.common_tags, {
    Name = "pfsense-lan-nic"
  })
}

resource "aws_network_interface" "opt_nic" {
  subnet_id         = aws_subnet.ubuntu_subnet.id
  security_groups   = [aws_security_group.pfsense_internal_sg.id]
  source_dest_check = false
  private_ips       = [local.pfsense_opt_ip]

  tags = merge(local.common_tags, {
    Name = "pfsense-opt-nic"
  })
}

# ============================================================
# ELASTIC IP
# ============================================================
resource "aws_eip" "wan_eip" {
  domain            = "vpc"
  network_interface = aws_network_interface.wan_nic.id

  tags = merge(local.common_tags, {
    Name = "pfsense-wan-eip"
  })
}
