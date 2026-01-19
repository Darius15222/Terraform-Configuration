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
