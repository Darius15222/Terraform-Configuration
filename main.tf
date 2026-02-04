# ============================================================
# MAIN TERRAFORM CONFIGURATION - Ubuntu Router Version
# ============================================================
# This configuration deploys a cybersecurity lab with:
#
# - Ubuntu Router (replaces pfSense - uses AWS credits!)
# - Kali Linux (penetration testing)
# - Ubuntu Server (vulnerable applications)
#
# FILES:
# - providers.tf     : Terraform and AWS provider configuration
# - variables.tf     : Input variables (Ubuntu AMI)
# - locals.tf        : Computed values and common tags
# - data.tf          : Data sources (AMIs, availability zones)
# - networking.tf    : VPC, subnets, network interfaces, EIP
# - security.tf      : Security groups
# - routing.tf       : Route tables and associations
# - keys.tf          : SSH key generation
# - instances.tf     : EC2 instances (router, Kali, Ubuntu)
# - outputs.tf       : Output values
#
# User data scripts (automatic configuration):
# - router-userdata.sh  : Configures Ubuntu as router (DHCP, DNS, NAT, Firewall, Snort)
# - kali-userdata.sh    : Deploys CyberChef
# - ubuntu-userdata.sh  : Deploys JuiceShop
# ============================================================

# Note: This file exists for documentation purposes.
# All actual resources are defined in their respective files.
