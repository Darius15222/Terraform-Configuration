# ============================================================
# REGION & AVAILABILITY ZONE CONFIGURATION
# ============================================================
variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

# ============================================================
# AMI CONFIGURATION
# ============================================================
variable "pfsense_ami_ids" {
  description = "pfSense AMI IDs per region (Updated: 2025-01-26)"
  type        = map(string)
  default = {
    eu-central-1 = "ami-046d2a13e1a6f8a53"  # pfSense Plus 25.11-RELEASE
  }
}

variable "kali_ami_ids" {
  description = "Kali Linux AMI IDs per region (Updated: 2025-01-26)"
  type        = map(string)
  default = {
    eu-central-1 = "ami-00643799044d656b7"  # Kali Linux 2025.4.0
  }
}

variable "ubuntu_ami_ids" {
  description = "Ubuntu 24.04 AMI IDs per region (Updated: 2025-01-26)"
  type        = map(string)
  default = {
    eu-central-1 = "ami-0dc7b24ad83b362b9"  # Ubuntu 24.04 Minimal (2026-01-22)
  }
}

# ============================================================
# SECURITY CONFIGURATION
# ============================================================
variable "admin_cidr" {
  description = "IP address allowed to SSH/HTTPS into the setup (e.g., 1.2.3.4/32). Use your current public IP."
  type        = string
  # No default - forces user to set this explicitly for security
  
  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be a valid CIDR block (e.g., 1.2.3.4/32)."
  }
}

# ============================================================
# NETWORK CONFIGURATION
# ============================================================
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "subnet_cidrs" {
  description = "CIDR blocks for each subnet"
  type        = map(string)
  default = {
    wan    = "10.0.1.0/24"
    kali   = "10.0.2.0/24"
    ubuntu = "10.0.3.0/24"
  }
  
  validation {
    condition = alltrue([
      for cidr in values(var.subnet_cidrs) : can(cidrhost(cidr, 0))
    ])
    error_message = "All subnet CIDRs must be valid CIDR blocks."
  }
}

# ============================================================
# INSTANCE CONFIGURATION
# ============================================================
variable "instance_types" {
  description = "EC2 instance types for each system"
  type        = map(string)
  default = {
    pfsense = "t3.small"
    kali    = "t3.small"
    ubuntu  = "t3.micro"
  }
}

variable "key_name" {
  description = "Name for the SSH key pair"
  type        = string
  default     = "pfsense-lab-key"
}

# ============================================================
# TAGGING CONFIGURATION
# ============================================================
variable "project_name" {
  description = "Name of the project for tagging"
  type        = string
  default     = "CyberLab"
}

variable "environment" {
  description = "Environment name (Dev, Test, Prod)"
  type        = string
  default     = "Dev"
}
