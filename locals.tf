# ============================================================
# COMMON TAGS
# ============================================================
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# COMPUTED IP ADDRESSES
# ============================================================
# IP Address Convention:
# - .1-.4: Reserved by AWS (network, VPC router, DNS, future use)
# - .5-.9: Reserved for infrastructure
# - .10: Gateway/firewall devices (pfSense interfaces)
# - .100+: Host machines (Kali, Ubuntu, etc.)
# - .255: Broadcast (reserved by AWS)
locals {
  # PfSense interface IPs (using .10 for gateway convention)
  pfsense_lan_ip = cidrhost(var.subnet_cidrs["kali"], 10)
  pfsense_opt_ip = cidrhost(var.subnet_cidrs["ubuntu"], 10)

  # Instance IPs (using .100+ for hosts)
  kali_ip   = cidrhost(var.subnet_cidrs["kali"], 100)
  ubuntu_ip = cidrhost(var.subnet_cidrs["ubuntu"], 100)
}
