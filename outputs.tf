output "pfsense_public_ip" {
  description = "Public IP address to access pfSense web interface"
  value       = aws_eip.wan_eip.public_ip
}

output "ssh_key_path" {
  description = "Path to the SSH private key file"
  value       = local_file.ssh_key.filename
}

output "pfsense_web_interface" {
  description = "URL to access pfSense web interface"
  value       = "https://${aws_eip.wan_eip.public_ip}"
}

output "kali_private_ip" {
  description = "Private IP address of Kali Linux instance"
  value       = aws_instance.kali.private_ip
}

output "ubuntu_private_ip" {
  description = "Private IP address of Ubuntu server instance"
  value       = aws_instance.ubuntu.private_ip
}

output "ssh_command_kali" {
  description = "SSH command to connect to Kali (via pfSense as jump host)"
  value       = "ssh -i ${local_file.ssh_key.filename} -J admin@${aws_eip.wan_eip.public_ip} kali@${aws_instance.kali.private_ip}"
}

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    region            = var.aws_region
    vpc_cidr          = var.vpc_cidr
    availability_zone = data.aws_availability_zones.available.names[0]
    pfsense_wan_ip    = aws_eip.wan_eip.public_ip
    project           = var.project_name
    environment       = var.environment
  }
}
