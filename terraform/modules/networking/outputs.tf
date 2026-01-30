# =============================================================================
# NETWORKING MODULE - OUTPUTS
# =============================================================================
#
# VAD ÄR OUTPUTS?
# Värden som modulen "exporterar" till den som anropar den.
# Andra moduler kan sedan använda dessa värden.
#
# VARFÖR BEHÖVS DET?
# Moduler är isolerade. Security-modulen kan inte direkt se VPC:n.
# Men om vi exporterar vpc_id som output kan den användas:
#
#   module.networking.vpc_id  →  skickas till  →  module.security
#
# SYNTAX FÖR ATT ANVÄNDA:
#   module.[modulnamn].[output_namn]
#
# EXEMPEL:
#   vpc_id = module.networking.vpc_id
#
# =============================================================================

output "vpc_id" {
  description = "ID för den skapade VPC:n"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR-block för VPC:n (används av security group)"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_id" {
  description = "ID för det publika subnätet (används av compute)"
  value       = aws_subnet.public.id
}

output "public_subnet_cidr" {
  description = "CIDR för det publika subnätet"
  value       = aws_subnet.public.cidr_block
}

output "internet_gateway_id" {
  description = "ID för Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "public_route_table_id" {
  description = "ID för public route table"
  value       = aws_route_table.public.id
}
