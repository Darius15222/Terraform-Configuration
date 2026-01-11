terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1" # Frankfurt
}

# ---------------------------------------------------------
# 1. IMAGE SEARCH
# ---------------------------------------------------------
data "aws_ami" "pfsense" {
  most_recent = true
  owners      = ["aws-marketplace"]
  filter {
    name   = "name"
    values = ["pfSense-plus-ec2-*-amd64*"]
  }
}

data "aws_ami" "kali" {
  most_recent = true
  owners      = ["aws-marketplace"] 
  filter {
    name   = "name"
    values = ["kali-last-snapshot-amd64-*"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/hvm-ssd*/ubuntu-noble-24.04-amd64-minimal-*"]
  }
}

# ---------------------------------------------------------
# 2. SSH KEYS
# ---------------------------------------------------------
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "pfsense-lab-key"
  public_key = tls_private_key.my_key.public_key_openssh
}

resource "local_file" "ssh_key" {
  content         = tls_private_key.my_key.private_key_pem
  filename        = "${path.module}/lab-key.pem"
  file_permission = "0400"
}

# ---------------------------------------------------------
# 3. NETWORKING
# ---------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "cyber-lab-vpc" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "wan" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = { Name = "subnet-wan" }
}

resource "aws_subnet" "kali_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1a"
  tags = { Name = "subnet-kali" }
}

resource "aws_subnet" "ubuntu_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-central-1a"
  tags = { Name = "subnet-ubuntu" }
}

# ---------------------------------------------------------
# 4. SECURITY GROUP
# ---------------------------------------------------------
resource "aws_security_group" "lab_sg" {
  name        = "lab-sg"
  description = "Allow all internal traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------
# 5. INSTANCES
# ---------------------------------------------------------
resource "aws_instance" "pfsense" {
  ami           = data.aws_ami.pfsense.id
  instance_type = "t3.small"
  key_name      = aws_key_pair.generated_key.key_name
  
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
  tags = { Name = "pfsense-firewall" }
}

resource "aws_instance" "kali" {
  ami           = data.aws_ami.kali.id
  instance_type = "t3.small" 
  key_name      = aws_key_pair.generated_key.key_name
  subnet_id     = aws_subnet.kali_subnet.id
  vpc_security_group_ids = [aws_security_group.lab_sg.id]
  private_ip    = "10.0.2.100"
  tags = { Name = "kali-linux" }
}

resource "aws_instance" "ubuntu" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.generated_key.key_name
  subnet_id     = aws_subnet.ubuntu_subnet.id
  vpc_security_group_ids = [aws_security_group.lab_sg.id]
  private_ip    = "10.0.3.100"
  tags = { Name = "ubuntu-minimal-server" }
}

# ---------------------------------------------------------
# 6. NETWORK INTERFACES (FIXED IPs)
# ---------------------------------------------------------
resource "aws_network_interface" "wan_nic" {
  subnet_id       = aws_subnet.wan.id
  security_groups = [aws_security_group.lab_sg.id]
  source_dest_check = false
}

# FIXED: Changed from 10.0.2.1 to 10.0.2.10 (AWS reserves .1)
resource "aws_network_interface" "lan_nic" {
  subnet_id       = aws_subnet.kali_subnet.id
  security_groups = [aws_security_group.lab_sg.id]
  source_dest_check = false
  private_ips     = ["10.0.2.10"] 
}

# FIXED: Changed from 10.0.3.1 to 10.0.3.10 (AWS reserves .1)
resource "aws_network_interface" "opt_nic" {
  subnet_id       = aws_subnet.ubuntu_subnet.id
  security_groups = [aws_security_group.lab_sg.id]
  source_dest_check = false
  private_ips     = ["10.0.3.10"] 
}

resource "aws_eip" "wan_eip" {
  domain            = "vpc"
  network_interface = aws_network_interface.wan_nic.id
}

# ---------------------------------------------------------
# 7. ROUTING
# ---------------------------------------------------------
resource "aws_route_table" "wan_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}
resource "aws_route_table_association" "wan_assoc" {
  subnet_id = aws_subnet.wan.id
  route_table_id = aws_route_table.wan_rt.id
}

resource "aws_route_table" "kali_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_network_interface.lan_nic.id
  }
}
resource "aws_route_table_association" "kali_assoc" {
  subnet_id = aws_subnet.kali_subnet.id
  route_table_id = aws_route_table.kali_rt.id
}

resource "aws_route_table" "ubuntu_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_network_interface.opt_nic.id
  }
}
resource "aws_route_table_association" "ubuntu_assoc" {
  subnet_id = aws_subnet.ubuntu_subnet.id
  route_table_id = aws_route_table.ubuntu_rt.id
}

output "pfsense_public_ip" {
  value = aws_eip.wan_eip.public_ip
}

output "ssh_key_path" {
  value = "${path.module}/lab-key.pem"
}