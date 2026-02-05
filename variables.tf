variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "admin_cidr" {
  description = "Admin IP CIDR"
  type        = string
  default     = "1.2.3.4/32"
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

variable "router_ami_ids" {
  type = map(string)
  default = {
    eu-central-1 = "ami-0084a47cc718c111a"
  }
}

variable "kali_ami_ids" {
  type = map(string)
  default = {
    eu-central-1 = "ami-00643799044d656b7"
  }
}

variable "ubuntu_ami_ids" {
  type = map(string)
  default = {
    eu-central-1 = "ami-0dc7b24ad83b362b9"
  }
}