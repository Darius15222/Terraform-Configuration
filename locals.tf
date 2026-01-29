locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  pfsense_lan_ip = cidrhost(var.subnet_cidrs["kali"], 10)
  pfsense_opt_ip = cidrhost(var.subnet_cidrs["ubuntu"], 10)
  kali_ip        = cidrhost(var.subnet_cidrs["kali"], 100)
  ubuntu_ip      = cidrhost(var.subnet_cidrs["ubuntu"], 100)
}
