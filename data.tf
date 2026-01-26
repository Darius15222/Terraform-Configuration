# ============================================================
# AVAILABILITY ZONES
# ============================================================
data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================================
# AMI MANAGEMENT
# ============================================================
# AMI IDs are pinned in variables.tf for reproducible deployments.
# 
# To update AMI IDs:
# - Windows: See WINDOWS_AMI_GUIDE.md
# - Linux/Mac: See AMI_MANAGEMENT_GUIDE.md
#
# Current AMI versions (eu-central-1):
# - pfSense Plus: 25.11-RELEASE (ami-046d2a13e1a6f8a53)
# - Kali Linux: 2025.4.0 (ami-00643799044d656b7)
# - Ubuntu 24.04: 2026-01-22 (ami-0dc7b24ad83b362b9)
# Last updated: 2025-01-26