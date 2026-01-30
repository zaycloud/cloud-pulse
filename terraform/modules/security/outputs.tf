# =============================================================================
# SECURITY MODULE - OUTPUTS
# =============================================================================
#
# Dessa outputs används av compute-modulen för att koppla
# security group till EC2-instansen.
#
# =============================================================================

output "security_group_id" {
  description = "ID för security group (används av EC2)"
  value       = aws_security_group.main.id
}

output "security_group_name" {
  description = "Namn på security group"
  value       = aws_security_group.main.name
}

output "security_group_arn" {
  description = "ARN för security group"
  value       = aws_security_group.main.arn
}
