variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "admin_cidr" {
  description = "Admin IP CIDR (REQUIRED - get from https://checkip.amazonaws.com)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  type = map(string)
  default = {
    wan    = "10.0.1.0/24"
    kali   = "10.0.2.0/24"
    ubuntu = "10.0.3.0/24"
  }
}

variable "instance_types" {
  type = map(string)
  default = {
    router = "t3.small"
    kali   = "t3.small"
    ubuntu = "t3.micro"
  }
}

variable "key_name" {
  type    = string
  default = "pfsense-lab-key"
}

variable "project_name" {
  type    = string
  default = "CyberLab"
}

variable "environment" {
  type    = string
  default = "Dev"
}

# ============================================================
# SSL CERTIFICATE CONFIGURATION
# ============================================================

variable "domain_name" {
  description = "Domain name for SSL certificate (e.g., cyberlab-sibiu.duckdns.org). Leave empty to use self-signed certificate."
  type        = string
  default     = ""
}

variable "ssl_email" {
  description = "Email for Let's Encrypt SSL certificate notifications"
  type        = string
  default     = ""
}