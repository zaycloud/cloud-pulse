
# Networking module outputs.
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
