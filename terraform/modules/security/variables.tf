
# Security module inputs.
variable "vpc_id" {
  description = "VPC ID där security group ska skapas"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR för interna regler (Node Exporter, Prometheus)"
  type        = string
}

variable "project_name" {
  description = "Projektnamn för taggning"
  type        = string
}

variable "allowed_ssh_cidr_ipv4" {
  description = "IPv4 CIDR som tillåts SSH-åtkomst (din IP/32 för säkerhet)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_ssh_cidr_ipv6" {
  description = "IPv6 CIDR som tillåts SSH-åtkomst (din IP/128 för säkerhet)"
  type        = string
  default     = "::/0"
}

variable "tags" {
  description = "Extra taggar att lägga till"
  type        = map(string)
  default     = {}
}
