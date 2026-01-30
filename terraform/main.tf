# =============================================================================
#                         CLOUD-PULSE - MAIN
# =============================================================================
#
# DRY PRINCIP (Don't Repeat Yourself):
# Istället för att skriva all infrastrukturkod här, anropar vi MODULER.
# Varje modul har ett specifikt ansvar och kan återanvändas.
#
# MODULER I DETTA PROJEKT:
#   1. networking - VPC, Subnet, Internet Gateway, Routes
#   2. security   - Security Groups (brandväggsregler)
#   3. compute    - Key Pair, EC2 Instance
#
# DATAFLÖDE MELLAN MODULER:
#
#   ┌──────────────┐
#   │  networking  │
#   │              │
#   │  vpc_id ─────┼──────────────────┐
#   │  vpc_cidr ───┼──────────────┐   │
#   │  subnet_id ──┼──────────┐   │   │
#   └──────────────┘          │   │   │
#                             │   │   │
#   ┌──────────────┐          │   │   │
#   │   security   │ ◄────────┼───┼───┘
#   │              │ ◄────────┼───┘
#   │  sg_id ──────┼──────┐   │
#   └──────────────┘      │   │
#                         │   │
#   ┌──────────────┐      │   │
#   │   compute    │ ◄────┼───┘
#   │              │ ◄────┘
#   │  public_ip ──┼──────────► OUTPUT
#   └──────────────┘
#
# TERRAFORM FÖRSTÅR BEROENDEN:
# Genom att referera till outputs (t.ex. module.networking.vpc_id)
# vet Terraform att networking måste skapas FÖRE security.
#
# =============================================================================


# -----------------------------------------------------------------------------
# MODUL: NETWORKING
# -----------------------------------------------------------------------------
#
# ANSVAR:
#   - VPC (isolerat nätverk)
#   - Internet Gateway (dörr till internet)
#   - Public Subnet (sektion för servrar)
#   - Route Table (trafikstyrning)
#
# SYNTAX FÖR MODUL-ANROP:
#   module "[namn]" {
#     source = "[sökväg]"
#     [variabel] = [värde]
#   }
#
# source = "./modules/networking"
#   Relativ sökväg till modul-mappen
#
# -----------------------------------------------------------------------------

module "networking" {
  source = "./modules/networking"

  # Skicka in värden från rot-variablerna
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
  project_name       = var.project_name
}


# -----------------------------------------------------------------------------
# MODUL: SECURITY
# -----------------------------------------------------------------------------
#
# ANSVAR:
#   - Security Group med brandväggsregler
#
# BEROENDE:
# Denna modul behöver vpc_id och vpc_cidr från networking.
# Terraform skapar automatiskt ett beroende och kör i rätt ordning.
#
# SYNTAX FÖR ATT REFERERA TILL MODUL-OUTPUT:
#   module.[modulnamn].[output_namn]
#
# -----------------------------------------------------------------------------

module "security" {
  source = "./modules/security"

  # Från networking-modulen (skapas först)
  vpc_id   = module.networking.vpc_id
  vpc_cidr = module.networking.vpc_cidr

  # Från rot-variablerna
  project_name = var.project_name

  # ---------------------------------------------------------------------------
  # DUAL STACK SSH-ÅTKOMST (IPv4 + IPv6)
  # ---------------------------------------------------------------------------
  # AWS Security Groups kräver SEPARATA attribut:
  #   - cidr_blocks      = endast IPv4
  #   - ipv6_cidr_blocks = endast IPv6
  #
  # Vi skickar in båda för att täcka alla ISP-typer.
  # ---------------------------------------------------------------------------
  allowed_ssh_cidr_ipv4 = var.allowed_ssh_cidr_ipv4
  allowed_ssh_cidr_ipv6 = var.allowed_ssh_cidr_ipv6
}


# -----------------------------------------------------------------------------
# MODUL: COMPUTE
# -----------------------------------------------------------------------------
#
# ANSVAR:
#   - Data source för Ubuntu AMI
#   - Key Pair för SSH
#   - EC2 Instance (servern)
#
# BEROENDEN:
#   - subnet_id från networking
#   - security_group_id från security
#
# Terraform förstår att networking och security måste skapas
# INNAN compute kan starta.
#
# -----------------------------------------------------------------------------

module "compute" {
  source = "./modules/compute"

  # Från networking-modulen
  subnet_id = module.networking.public_subnet_id

  # Från security-modulen (notera: lista med [])
  security_group_ids = [module.security.security_group_id]

  # Från rot-variablerna
  instance_type       = var.instance_type
  ssh_public_key_path = var.ssh_public_key_path
  project_name        = var.project_name
}
