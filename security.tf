resource "aws_security_group" "lab_sg" {
  name        = "lab-sg"
  description = "Allow all internal traffic and restricted external access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr] 
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "lab-security-group"
  })
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = { 
    Name = "default-deny-all"
    Note = "Default SG - intentionally locked down"
  }
}