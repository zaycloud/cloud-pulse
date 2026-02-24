
# Networking module inputs.
variable "vpc_cidr" {
  description = "CIDR-block för VPC (t.ex. 10.0.0.0/16)"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr måste vara ett giltigt CIDR-block."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR-block för public subnet (måste vara inom VPC CIDR)"
  type        = string

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "public_subnet_cidr måste vara ett giltigt CIDR-block."
  }
}

variable "availability_zone" {
  description = "Availability Zone för subnätet (t.ex. eu-north-1a)"
  type        = string
}

variable "project_name" {
  description = "Projektnamn för taggning av resurser"
  type        = string
}

variable "tags" {
  description = "Extra taggar att lägga till på alla resurser"
  type        = map(string)
  default     = {}
}
