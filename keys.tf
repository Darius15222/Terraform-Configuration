resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.my_key.public_key_openssh

  tags = merge(local.common_tags, {
    Name = var.key_name
  })
}

resource "local_file" "ssh_key" {
  content         = tls_private_key.my_key.private_key_pem
  filename        = "${path.module}/lab-key.pem"
  file_permission = "0400"
}
