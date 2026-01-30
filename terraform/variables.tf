# =============================================================================
# ROOT VARIABLES
# =============================================================================
# Dessa variabler definieras här och skickas sedan till modulerna.
# 
# DRY PRINCIP:
# Vi definierar varje värde EN gång här, sedan refererar modulerna till dem.
# Om du vill ändra region behöver du bara ändra på ETT ställe.
# =============================================================================

# -----------------------------------------------------------------------------
# AWS KONFIGURATION
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS-region där alla resurser skapas"
  type        = string
  default     = "eu-north-1" # Stockholm
}

variable "project_name" {
  description = "Projektnamn för taggning av alla resurser"
  type        = string
  default     = "cloud-pulse"
}

# -----------------------------------------------------------------------------
# NÄTVERK (VPC)
# -----------------------------------------------------------------------------
#
# CIDR-NOTATION:
# Format: IP-ADRESS/PREFIX
#
# Prefixet anger hur många bitar som är "låsta":
#   /32 = 1 IP-adress
#   /24 = 256 adresser
#   /16 = 65,536 adresser
#   /0  = ALLA adresser
#
# PRIVATA IP-INTERVALL (RFC 1918):
#   - 10.0.0.0/8      ← Vi använder en del av detta
#   - 172.16.0.0/12
#   - 192.168.0.0/16  ← Samma som hemma-WiFi
#
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# SÄKERHET
# -----------------------------------------------------------------------------

variable "allowed_ssh_cidr_ipv4" {
  description = "IPv4 CIDR som tillåts SSH-åtkomst (t.ex. 84.23.156.78/32)"
  type        = string
  default     = "0.0.0.0/0" # Hela internet som fallback
}

variable "allowed_ssh_cidr_ipv6" {
  description = "IPv6 CIDR som tillåts SSH-åtkomst (t.ex. 2a09:bac2:5276:505::80:d5/128)"
  type        = string
  default     = "::/0" # Hela internet som fallback
}

variable "ssh_public_key_path" {
  description = "Sökväg till din publika SSH-nyckel"
  type        = string
  # Ingen default - måste sättas i terraform.tfvars
}

# -----------------------------------------------------------------------------
# COMPUTE
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instanstyp"
  type        = string
  default     = "t3.micro" # Free tier: 750h/månad i 12 månader
}
