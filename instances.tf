resource "aws_instance" "router" {
  ami           = var.router_ami_ids[var.aws_region]
  instance_type = var.instance_types["router"]
  key_name      = aws_key_pair.generated_key.key_name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted = true
  }

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

  user_data = templatefile("${path.module}/router-userdata.sh", {
    admin_cidr = var.admin_cidr
  })
  
  user_data_replace_on_change = true
  
  tags = merge(local.common_tags, {
    Name = "ubuntu-router"
    Role = "Gateway/Firewall"
  })
}

resource "aws_instance" "kali" {
  ami                    = var.kali_ami_ids[var.aws_region]
  instance_type          = var.instance_types["kali"]
  key_name               = aws_key_pair.generated_key.key_name
  subnet_id              = aws_subnet.kali_subnet.id
  vpc_security_group_ids = [aws_security_group.kali_sg.id]
  private_ip             = local.kali_ip

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted = true
  }

  user_data = file("${path.module}/kali-userdata.sh")

  depends_on = [
    aws_instance.router,
    aws_eip.wan_eip
  ]

  tags = merge(local.common_tags, {
    Name = "kali-linux"
    Role = "Pentesting Workstation"
  })
}

resource "aws_instance" "ubuntu" {
  ami                    = var.ubuntu_ami_ids[var.aws_region]
  instance_type          = var.instance_types["ubuntu"]
  key_name               = aws_key_pair.generated_key.key_name
  subnet_id              = aws_subnet.ubuntu_subnet.id
  vpc_security_group_ids = [aws_security_group.ubuntu_sg.id]
  private_ip             = local.ubuntu_ip

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted = true
  }

  user_data = file("${path.module}/ubuntu-userdata.sh")

  depends_on = [
    aws_instance.router,
    aws_eip.wan_eip
  ]

  tags = merge(local.common_tags, {
    Name = "ubuntu-minimal-server"
    Role = "Vulnerable Target"
  })
}
