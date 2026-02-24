
# Values printed after `terraform apply`.
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR-block"
  value       = module.networking.vpc_cidr
}

output "subnet_id" {
  description = "Public Subnet ID"
  value       = module.networking.public_subnet_id
}

output "security_group_id" {
  description = "Security Group ID"
  value       = module.security.security_group_id
}

output "instance_id" {
  description = "EC2 Instance ID"
  value       = module.compute.instance_id
}

output "server_public_ip" {
  description = "Serverns publika IP-adress"
  value       = module.compute.public_ip
}

output "server_private_ip" {
  description = "Serverns privata IP-adress (inom VPC)"
  value       = module.compute.private_ip
}

output "ami_used" {
  description = "AMI ID som användes"
  value       = module.compute.ami_id
}

output "ssh_command" {
  description = "Kommando för att SSH:a in till servern"
  value       = "ssh -i ~/.ssh/cloud_pulse_key ubuntu@${module.compute.public_ip}"
}

output "grafana_url" {
  description = "URL till Grafana dashboard (tillgänglig efter Ansible-setup)"
  value       = "http://${module.compute.public_ip}:3000"
}

output "node_exporter_url" {
  description = "URL till Node Exporter metrics (endast från VPC)"
  value       = "http://${module.compute.private_ip}:9100/metrics"
}
