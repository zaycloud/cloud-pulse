# =============================================================================
# COMPUTE MODULE - OUTPUTS
# =============================================================================
#
# Dessa outputs ger information om den skapade servern.
# Används av rot-modulen för att visa användbar info efter "terraform apply".
#
# =============================================================================

output "instance_id" {
  description = "EC2 Instance ID (unikt identifierare i AWS)"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Publik IP-adress (för SSH och Grafana)"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "Privat IP-adress (inom VPC)"
  value       = aws_instance.this.private_ip
}

output "public_dns" {
  description = "Publikt DNS-namn"
  value       = aws_instance.this.public_dns
}

output "key_name" {
  description = "SSH Key Pair namn (referens i AWS)"
  value       = aws_key_pair.this.key_name
}

output "ami_id" {
  description = "AMI ID som användes (för felsökning)"
  value       = data.aws_ami.ubuntu.id
}

output "availability_zone" {
  description = "Availability Zone där instansen körs"
  value       = aws_instance.this.availability_zone
}
