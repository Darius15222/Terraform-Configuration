resource "aws_route_table" "wan_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = merge(local.common_tags, {
    Name = "wan-route-table"
  })
}

resource "aws_route_table_association" "wan_assoc" {
  subnet_id      = aws_subnet.wan.id
  route_table_id = aws_route_table.wan_rt.id
}

resource "aws_route_table" "kali_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_network_interface.lan_nic.id
  }
  tags = merge(local.common_tags, {
    Name = "kali-route-table"
  })
}

resource "aws_route_table_association" "kali_assoc" {
  subnet_id      = aws_subnet.kali_subnet.id
  route_table_id = aws_route_table.kali_rt.id
}

resource "aws_route_table" "ubuntu_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_network_interface.opt_nic.id
  }
  tags = merge(local.common_tags, {
    Name = "ubuntu-route-table"
  })
}

resource "aws_route_table_association" "ubuntu_assoc" {
  subnet_id      = aws_subnet.ubuntu_subnet.id
  route_table_id = aws_route_table.ubuntu_rt.id
}
