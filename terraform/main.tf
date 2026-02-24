
# Connect the three Terraform modules.
module "networking" {
  source = "./modules/networking"

  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
  project_name       = var.project_name
}

# Security module uses VPC values from networking.
module "security" {
  source = "./modules/security"

  vpc_id   = module.networking.vpc_id
  vpc_cidr = module.networking.vpc_cidr

  project_name = var.project_name

  allowed_ssh_cidr_ipv4 = var.allowed_ssh_cidr_ipv4
  allowed_ssh_cidr_ipv6 = var.allowed_ssh_cidr_ipv6
}

# Compute module uses subnet and security group outputs.
module "compute" {
  source = "./modules/compute"

  subnet_id = module.networking.public_subnet_id

  security_group_ids = [module.security.security_group_id]

  instance_type       = var.instance_type
  ssh_public_key_path = var.ssh_public_key_path
  project_name        = var.project_name
}
