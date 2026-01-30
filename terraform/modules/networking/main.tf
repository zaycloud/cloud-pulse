# =============================================================================
# NETWORKING MODULE
# =============================================================================
#
# ANSVAR:
# Denna modul skapar ett komplett nätverk i AWS:
#   - VPC (Virtual Private Cloud) - Ditt isolerade nätverk
#   - Internet Gateway - Dörren till internet
#   - Public Subnet - Sektion för publika resurser
#   - Route Table - Trafikstyrning (GPS för paket)
#
# ANVÄNDNING:
#   module "network" {
#     source             = "./modules/networking"
#     vpc_cidr           = "10.0.0.0/16"
#     public_subnet_cidr = "10.0.1.0/24"
#     availability_zone  = "eu-north-1a"
#     project_name       = "my-project"
#   }
#
# KOSTNAD: GRATIS (alla nätverksresurser)
#
# =============================================================================


# -----------------------------------------------------------------------------
# LOCALS
# -----------------------------------------------------------------------------
# Locals är "interna variabler" som bara finns inom modulen.
# Används för att:
#   - Kombinera värden
#   - Undvika upprepning
#   - Hålla koden DRY
#
# merge() kombinerar två maps. Om samma nyckel finns tar den senare över.
# -----------------------------------------------------------------------------

locals {
  common_tags = merge(
    {
      Project   = var.project_name
      Module    = "networking"
      ManagedBy = "terraform"
    },
    var.tags
  )
}


# -----------------------------------------------------------------------------
# VPC (Virtual Private Cloud)
# -----------------------------------------------------------------------------
#
# VAD ÄR EN VPC?
# Ett isolerat, privat nätverk i AWS molnet.
# Allt du bygger (servrar, databaser, etc.) placeras i en VPC.
#
# VARFÖR EGEN VPC?
#   1. ISOLATION - Separerat från andra projekt
#   2. KONTROLL - Du bestämmer IP-intervall och routing
#   3. SÄKERHET - Du kontrollerar vad som får prata med vad
#
# CIDR 10.0.0.0/16 ger:
#   - 65,536 möjliga IP-adresser
#   - Adresser: 10.0.0.0 - 10.0.255.255
#
# enable_dns_hostnames:
#   - EC2-instanser får DNS-namn (ec2-x-x-x-x.region.compute.amazonaws.com)
#
# enable_dns_support:
#   - Aktiverar AWS DNS-server i VPC:n
#   - Instanser kan slå upp domännamn (google.com → IP)
#
# -----------------------------------------------------------------------------

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}


# -----------------------------------------------------------------------------
# DEFAULT SECURITY GROUP (Säkerhetslås)
# -----------------------------------------------------------------------------
#
# VARFÖR BEHÖVS DETTA?
# AWS skapar automatiskt en "default" security group i varje VPC.
# Om du inte explicit hanterar den, kan den ha osäkra standardregler.
#
# BEST PRACTICE (CIS Benchmark):
# Lås default security group så att ingen trafik tillåts.
# Alla resurser ska använda explicita, namngivna security groups istället.
#
# -----------------------------------------------------------------------------

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id

  # Inga ingress- eller egress-regler = all trafik blockeras
  # Detta tvingar användning av explicita security groups

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-default-sg-LOCKED"
  })
}


# -----------------------------------------------------------------------------
# INTERNET GATEWAY
# -----------------------------------------------------------------------------
#
# VAD ÄR DET?
# "Dörren" mellan din VPC och internet.
#
# UTAN INTERNET GATEWAY:
#   ❌ Servrar kan INTE nå internet (apt update misslyckas)
#   ❌ Internet kan INTE nå dina servrar
#   ❌ Docker kan inte ladda ner images
#
# MED INTERNET GATEWAY:
#   ✅ Resurser med PUBLIK IP kan kommunicera med internet
#   ✅ Du kan SSH:a in till dina servrar
#   ✅ Grafana blir nåbar på port 3000
#
# VIKTIGT:
# Internet Gateway öppnar MÖJLIGHETEN för trafik.
# Security Groups bestämmer vad som faktiskt TILLÅTS.
#
# KOSTNAD: GRATIS
#
# -----------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw"
  })
}


# -----------------------------------------------------------------------------
# PUBLIC SUBNET
# -----------------------------------------------------------------------------
#
# VAD ÄR ETT SUBNET?
# En "sektion" av din VPC. Du delar upp nätverket i mindre delar.
#
# VARFÖR DELA UPP?
#   1. SEPARATION - Webservrar i ett, databaser i ett annat
#   2. SÄKERHET - Olika regler för olika subnets
#   3. REDUNDANS - Sprida över Availability Zones
#
# PUBLIC vs PRIVATE SUBNET:
# ┌─────────────────────────┬──────────────────────────────────┐
# │ PUBLIC SUBNET           │ PRIVATE SUBNET                   │
# ├─────────────────────────┼──────────────────────────────────┤
# │ Route till IGW          │ Ingen route till IGW             │
# │ Får publik IP           │ Endast privat IP                 │
# │ Nåbar från internet     │ INTE nåbar från internet         │
# │ För: Webservrar         │ För: Databaser                   │
# │ Kostnad: GRATIS         │ Behöver NAT Gateway ($32+/mån)   │
# └─────────────────────────┴──────────────────────────────────┘
#
# VI VÄLJER PUBLIC SUBNET eftersom:
#   - Grafana måste vara nåbar (port 3000)
#   - SSH måste fungera (port 22)
#   - Det är GRATIS
#
# map_public_ip_on_launch = true:
#   Alla EC2-instanser som startas här får AUTOMATISKT publik IP.
#
# CIDR 10.0.1.0/24 ger 256 adresser:
#   - 10.0.1.0   = Nätverksadress (reserverad)
#   - 10.0.1.1   = VPC Router (reserverad av AWS)
#   - 10.0.1.2   = DNS Server (reserverad av AWS)
#   - 10.0.1.3   = Reserverad för framtida användning
#   - 10.0.1.4-254 = ANVÄNDBARA (251 stycken)
#   - 10.0.1.255 = Broadcast (reserverad)
#
# KOSTNAD: GRATIS
#
# -----------------------------------------------------------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-subnet"
    Type = "public"
  })
}


# -----------------------------------------------------------------------------
# ROUTE TABLE
# -----------------------------------------------------------------------------
#
# VAD ÄR DET?
# En "GPS" för nätverkstrafik. Berättar vart datapaket ska skickas.
#
# HUR DET FUNGERAR:
# När en server skickar data, kollar AWS i route table:
#   "Vart ska paketet till IP x.x.x.x?"
#
# AWS matchar destinationen mot routes, mest specifik först:
#   1. 10.0.0.0/16 → local (VPC-intern trafik, skapas automatiskt)
#   2. 0.0.0.0/0   → Internet Gateway (allt annat)
#
# EXEMPEL:
#   Destination: 10.0.1.50  → Matchar 10.0.0.0/16 → Stannar i VPC
#   Destination: 8.8.8.8    → Matchar 0.0.0.0/0   → Går till internet
#
# 0.0.0.0/0 FÖRKLARING:
#   - Kallas "default route" eller "catch-all"
#   - /0 = inga bitar låsta = matchar ALLA IP-adresser
#   - Används som "fallback" när ingen annan route matchar
#
# KOSTNAD: GRATIS
#
# -----------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}


# -----------------------------------------------------------------------------
# ROUTE TABLE ASSOCIATION
# -----------------------------------------------------------------------------
#
# VAD ÄR DET?
# Kopplar en Route Table till ett Subnet.
#
# VARFÖR BEHÖVS DET?
# En route table gör INGENTING själv. Den måste associeras med ett subnet.
# 
# Utan denna koppling använder subnätet VPC:ns "main route table",
# som INTE har en route till Internet Gateway = ingen internet-åtkomst.
#
# KOSTNAD: GRATIS
#
# -----------------------------------------------------------------------------

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
