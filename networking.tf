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

resource "aws_network_interface" "wan_nic" {
  subnet_id         = aws_subnet.wan.id
  security_groups   = [aws_security_group.lab_sg.id]
  source_dest_check = false
}

resource "aws_network_interface" "lan_nic" {
  subnet_id         = aws_subnet.kali_subnet.id
  security_groups   = [aws_security_group.lab_sg.id]
  source_dest_check = false
  private_ips       = ["10.0.2.10"]
}

resource "aws_network_interface" "opt_nic" {
  subnet_id         = aws_subnet.ubuntu_subnet.id
  security_groups   = [aws_security_group.lab_sg.id]
  source_dest_check = false
  private_ips       = ["10.0.3.10"]
}

resource "aws_eip" "wan_eip" {
  domain            = "vpc"
  network_interface = aws_network_interface.wan_nic.id
}
