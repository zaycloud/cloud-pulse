
# Common tags for security resources.
locals {
  common_tags = merge(
    {
      Project   = var.project_name
      Module    = "security"
      ManagedBy = "terraform"
    },
    var.tags
  )
}

# Create security group rules.
resource "aws_security_group" "main" {
  name        = "${var.project_name}-sg"
  description = "Security group for ${var.project_name} - SSH, Grafana, Prometheus stack"
  vpc_id      = var.vpc_id

  # Allow SSH (IPv4 and IPv6).
  ingress {
    description      = "SSH access for remote management (IPv4 + IPv6)"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.allowed_ssh_cidr_ipv4]
    ipv6_cidr_blocks = [var.allowed_ssh_cidr_ipv6]
  }

  # Open web ports.
  ingress {
    description = "Grafana web dashboard"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP on port 8080 Grafana web dashboard"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Public HTTP web traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Public HTTP web traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Node Exporter metrics - VPC internal only"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Prometheus - VPC internal only"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outgoing traffic.
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}
