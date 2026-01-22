# ============================================================
# REGION & AVAILABILITY ZONE CONFIGURATION
# ============================================================
variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

# ============================================================
# SECURITY CONFIGURATION
# ============================================================
variable "admin_cidr" {
  description = "IP address allowed to SSH/HTTPS into the setup (e.g., 1.2.3.4/32). Use your current public IP."
  type        = string
  # No default - forces user to set this explicitly for security
}

# ============================================================
# NETWORK CONFIGURATION
# ============================================================
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for each subnet"
  type        = map(string)
  default = {
    wan    = "10.0.1.0/24"
    kali   = "10.0.2.0/24"
    ubuntu = "10.0.3.0/24"
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
