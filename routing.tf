# ============================================================
# WAN ROUTE TABLE (Internet Gateway)
# ============================================================
# This route table is attached to the WAN subnet where pfSense's
# WAN interface resides. It routes all traffic directly to the
# Internet Gateway, giving pfSense public internet access.
resource "aws_route_table" "wan_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"  # All traffic
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

# ============================================================
# KALI ROUTE TABLE (via pfSense LAN interface)
# ============================================================
# This route table forces ALL traffic from the Kali subnet to go
# through pfSense's LAN interface. This allows pfSense to:
# - Inspect all Kali traffic
# - Apply firewall rules
# - Provide NAT for internet access
# - Log connections (if configured)
resource "aws_route_table" "kali_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"  # Default route (all traffic)
    network_interface_id = aws_network_interface.lan_nic.id  # pfSense LAN
  }

  tags = merge(local.common_tags, {
    Name = "kali-route-table"
  })
}

resource "aws_route_table_association" "kali_assoc" {
  subnet_id      = aws_subnet.kali_subnet.id
  route_table_id = aws_route_table.kali_rt.id
}

# ============================================================
# UBUNTU ROUTE TABLE (via pfSense OPT interface)
# ============================================================
# Similar to Kali, this forces all Ubuntu traffic through pfSense's
# OPT interface. This creates network segmentation:
# - Kali and Ubuntu are in different subnets
# - pfSense controls traffic flow between them
# - You can create firewall rules to isolate or allow traffic
resource "aws_route_table" "ubuntu_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"  # Default route (all traffic)
    network_interface_id = aws_network_interface.opt_nic.id  # pfSense OPT
  }

  tags = merge(local.common_tags, {
    Name = "ubuntu-route-table"
  })
}

resource "aws_route_table_association" "ubuntu_assoc" {
  subnet_id      = aws_subnet.ubuntu_subnet.id
  route_table_id = aws_route_table.ubuntu_rt.id
}