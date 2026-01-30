# =============================================================================
# COMPUTE MODULE - VARIABLER
# =============================================================================
#
# Denna modul behöver:
#   - subnet_id: Var ska EC2 placeras? (från networking)
#   - security_group_ids: Vilka brandväggsregler? (från security)
#   - ssh_public_key_path: Din SSH-nyckel för inloggning
#
# =============================================================================

variable "subnet_id" {
  description = "Subnet ID där EC2-instansen ska placeras"
  type        = string
}

variable "security_group_ids" {
  description = "Lista med Security Group IDs att koppla till instansen"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instanstyp (t.ex. t3.micro, t3.small)"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key_path" {
  description = "Absolut sökväg till din publika SSH-nyckel (.pub)"
  type        = string
}

variable "project_name" {
  description = "Projektnamn för taggning"
  type        = string
}

variable "volume_size" {
  description = "Storlek på root-disk i GB"
  type        = number
  default     = 8
}

variable "volume_type" {
  description = "Typ av EBS-volym (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "tags" {
  description = "Extra taggar att lägga till"
  type        = map(string)
  default     = {}
}
