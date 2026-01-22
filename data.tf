# ============================================================
# AVAILABILITY ZONES
# ============================================================
data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================================
# AMI LOOKUPS
# ============================================================
data "aws_ami" "pfsense" {
  most_recent = true
  owners      = ["aws-marketplace"]
  filter {
    name   = "name"
    values = ["pfSense-plus-ec2-*-amd64*"]
  }
}

data "aws_ami" "kali" {
  most_recent = true
  owners      = ["aws-marketplace"]
  filter {
    name   = "name"
    values = ["kali-last-snapshot-amd64-*"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/hvm-ssd*/ubuntu-noble-24.04-amd64-minimal-*"]
  }
}
