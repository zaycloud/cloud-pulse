
# Inputs used by all modules.
variable "aws_region" {
  description = "AWS-region där alla resurser skapas"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Projektnamn för taggning av alla resurser"
  type        = string
  default     = "cloud-pulse"
}

# Network settings.
variable "vpc_cidr" {
  description = "CIDR-block för VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR-block för public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability Zone för subnätet"
  type        = string
  default     = "eu-north-1a"
}

# Access and server settings.
variable "allowed_ssh_cidr_ipv4" {
  description = "IPv4 CIDR som tillåts SSH-åtkomst (t.ex. 84.23.156.78/32)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_ssh_cidr_ipv6" {
  description = "IPv6 CIDR som tillåts SSH-åtkomst (t.ex. 2a09:bac2:5276:505::80:d5/128)"
  type        = string
  default     = "::/0"
}

variable "ssh_public_key_path" {
  description = "Sökväg till din publika SSH-nyckel"
  type        = string
}

variable "instance_type" {
  description = "EC2 instanstyp"
  type        = string
  default     = "t3.micro"
}
