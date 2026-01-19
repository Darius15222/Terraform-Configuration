output "pfsense_public_ip" {
  value = aws_eip.wan_eip.public_ip
}

output "ssh_key_path" {
  value = "${path.module}/lab-key.pem"
}
