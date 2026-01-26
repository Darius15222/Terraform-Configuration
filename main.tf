# ============================================================
# MAIN TERRAFORM CONFIGURATION
# ============================================================
# This configuration is split into purpose-based files for better
# organization and maintainability:
#
# - providers.tf     : Terraform and AWS provider configuration
# - variables.tf     : Input variables and validation
# - locals.tf        : Computed values and common tags
# - data.tf          : Data sources (AMIs, availability zones)
# - networking.tf    : VPC, subnets, network interfaces, EIP
# - security.tf      : Security groups
# - routing.tf       : Route tables and associations
# - keys.tf          : SSH key generation
# - instances.tf     : EC2 instances (pfSense, Kali, Ubuntu)
# - outputs.tf       : Output values
#
# User data scripts (empty until automation phase):
# - pfsense-userdata.sh
# - kali-userdata.sh
# - ubuntu-userdata.sh
# ============================================================
