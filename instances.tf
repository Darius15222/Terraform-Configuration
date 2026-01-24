resource "aws_instance" "pfsense" {
  ami           = data.aws_ami.pfsense.id
  instance_type = var.instance_types["pfsense"]
  key_name      = aws_key_pair.generated_key.key_name

  ebs_optimized = true

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
  
  tags = { Name = "pfsense-firewall" }
}

resource "aws_instance" "kali" {
  ami                    = data.aws_ami.kali.id
  instance_type          = var.instance_types["kali"]
  key_name               = aws_key_pair.generated_key.key_name
  subnet_id              = aws_subnet.kali_subnet.id
  vpc_security_group_ids = [aws_security_group.lab_sg.id]
  private_ip             = local.kali_ip

  ebs_optimized = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted = true
  }

  tags = { Name = "kali-linux" }
}

resource "aws_instance" "ubuntu" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_types["ubuntu"]
  key_name               = aws_key_pair.generated_key.key_name
  subnet_id              = aws_subnet.ubuntu_subnet.id
  vpc_security_group_ids = [aws_security_group.lab_sg.id]
  private_ip             = local.ubuntu_ip

  ebs_optimized = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted = true
  }

  tags = { Name = "ubuntu-minimal-server" }
}