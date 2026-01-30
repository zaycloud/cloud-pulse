# =============================================================================
# COMPUTE MODULE
# =============================================================================
#
# ANSVAR:
# Denna modul skapar beräkningsresurser:
#   - Data source för senaste Ubuntu AMI
#   - Key Pair för SSH-autentisering
#   - EC2 Instance (den virtuella servern)
#
# KOSTNAD:
#   - t3.micro: GRATIS i free tier (750 timmar/månad, 12 månader)
#   - EBS 8GB gp3: GRATIS i free tier (30 GB/månad)
#   - Publik IPv4: ~$3.65/månad ($0.005/timme) - NY KOSTNAD sedan 2024
#
# =============================================================================


# -----------------------------------------------------------------------------
# LOCALS
# -----------------------------------------------------------------------------

locals {
  common_tags = merge(
    {
      Project   = var.project_name
      Module    = "compute"
      ManagedBy = "terraform"
    },
    var.tags
  )
}


# -----------------------------------------------------------------------------
# DATA SOURCE: UBUNTU AMI
# -----------------------------------------------------------------------------
#
# VAD ÄR EN AMI (Amazon Machine Image)?
# En "mall" eller "snapshot" för att starta servrar.
# Innehåller:
#   1. Operativsystem (Ubuntu 22.04)
#   2. Förinstallerad mjukvara
#   3. Boot-konfiguration
#
# PROBLEMET MED HÅRDKODADE AMI-ID:
# Varje AMI har ett unikt ID: ami-0abcdef1234567890
# Men dessa ID:n ÄNDRAS varje gång Ubuntu släpper en säkerhetsuppdatering!
# 
# Om du hårdkodar: ami = "ami-0abcdef1234567890"
# Kommer din kod sluta fungera inom några månader.
#
# LÖSNINGEN - DATA SOURCE:
# "data" block SKAPAR ingenting. De SÖKER efter information.
# Vi ber AWS: "Hitta senaste Ubuntu 22.04 från Canonical"
#
# SKILLNAD resource vs data:
#   resource = SKAPAR något nytt i molnet
#   data     = LÄSER/SÖKER efter befintlig information
#
# FILTER-FÖRKLARING:
#
# owners = ["099720109477"]
#   - Canonicals officiella AWS-konto-ID
#   - KRITISKT för säkerhet!
#   - Utan detta filter kan vem som helst skapa en "Ubuntu" AMI med malware
#   - Verifiera: https://ubuntu.com/server/docs/cloud-images/amazon-ec2
#
# name = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
#   - ubuntu/images/hvm-ssd/ = Sökväg i AWS AMI-katalog
#   - ubuntu-jammy = Kodnamn för Ubuntu 22.04 LTS ("Jammy Jellyfish")
#   - 22.04 = Versionsnummer
#   - amd64 = 64-bitars x86-processor
#   - server = Server-edition (ingen GUI, mindre storlek)
#   - * = Wildcard (matchar datum: -20240115)
#
# virtualization-type = "hvm"
#   - HVM = Hardware Virtual Machine
#   - Modern virtualiseringsteknik med bäst prestanda
#   - Alternativet (PV = Paravirtual) är föråldrat
#
# -----------------------------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# -----------------------------------------------------------------------------
# KEY PAIR
# -----------------------------------------------------------------------------
#
# VAD ÄR ETT KEY PAIR?
# Ett asymmetriskt nyckelpar för SSH-autentisering:
#   - Publik nyckel (.pub) = "Låset" - laddas upp till AWS
#   - Privat nyckel        = "Nyckeln" - stannar på din dator
#
# SSH-INLOGGNINGSFLÖDE:
#   1. Du kör: ssh -i ~/.ssh/cloud_pulse_key ubuntu@SERVER_IP
#   2. Servern skickar en "utmaning" (slumpmässig krypterad data)
#   3. Din PRIVATA nyckel signerar utmaningen
#   4. Servern verifierar signaturen med PUBLIKA nyckeln
#   5. Match = Du är inne!
#
# VARFÖR ÄR DETTA SÄKERT?
# Din privata nyckel lämnar ALDRIG din dator.
# Vi laddar bara upp "låset" (publika nyckeln) till AWS.
# Även om någon stjäl den publika nyckeln kan de inte logga in.
#
# file() FUNKTION:
# Läser innehållet i en fil från disk vid körning.
# Terraform skickar INNEHÅLLET (inte sökvägen) till AWS.
#
# KOSTNAD: GRATIS
#
# -----------------------------------------------------------------------------

resource "aws_key_pair" "this" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.ssh_public_key_path)

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-key"
  })
}


# -----------------------------------------------------------------------------
# EC2 INSTANCE
# -----------------------------------------------------------------------------
#
# VAD ÄR EN EC2 INSTANCE?
# En virtuell server som kör i AWS datacenter.
# Du hyr datorkraft istället för att köpa fysisk hårdvara.
#
# INSTANCE TYPE FORMAT: [familj][generation].[storlek]
#
# FAMILJER:
#   t = "Burstable" - kan låna extra CPU kortvarigt
#   m = "General purpose" - balanserad CPU/RAM
#   c = "Compute optimized" - mycket CPU
#   r = "Memory optimized" - mycket RAM
#
# t3.micro SPECIFIKATIONER:
#   - 2 vCPU (virtuella CPU-kärnor)
#   - 1 GB RAM
#   - Baseline: 10% CPU (kan "bursta" till 100% kortvarigt)
#   - Nätverk: Up to 5 Gbps
#
# "BURSTABLE" FÖRKLARING:
# t3-instanser samlar "CPU credits" när de är inaktiva.
# När du behöver mer kraft (t.ex. apt update) används credits.
# Perfekt för varierande belastning som vår demo.
#
# ROOT BLOCK DEVICE:
# Serverns "hårddisk" (egentligen SSD i molnet).
#
# volume_type = "gp3":
#   - gp3 = General Purpose SSD, generation 3
#   - 3000 IOPS baseline (gratis)
#   - 125 MB/s throughput (gratis)
#   - Billigare än gp2 med bättre prestanda
#
# encrypted = true:
#   - Disken krypteras med AWS-hanterad nyckel
#   - Best practice även för demo
#   - Ingen extra kostnad
#
# KOSTNAD:
#   - EC2 t3.micro: GRATIS (free tier, 750h/månad i 12 månader)
#   - EBS 8GB gp3: GRATIS (free tier, 30GB/månad)
#   - Publik IPv4: ~$3.65/månad (ny kostnad sedan feb 2024)
#
# -----------------------------------------------------------------------------

resource "aws_instance" "this" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id

  # ---------------------------------------------------------------------------
  # METADATA OPTIONS (IMDSv2)
  # ---------------------------------------------------------------------------
  # IMDSv2 (Instance Metadata Service Version 2) är säkrare än v1:
  #   - Kräver session-token för att hämta metadata
  #   - Skyddar mot SSRF-attacker (Server-Side Request Forgery)
  #   - Best practice enligt AWS och CIS Benchmark
  #
  # http_tokens = "required" tvingar IMDSv2
  # http_endpoint = "enabled" aktiverar metadata-tjänsten
  # http_put_response_hop_limit = 1 begränsar token-användning till instansen
  # ---------------------------------------------------------------------------
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Tvingar IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_size           = var.volume_size
    volume_type           = var.volume_type
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-server"
  })

  # ---------------------------------------------------------------------------
  # LIFECYCLE
  # ---------------------------------------------------------------------------
  # ignore_changes för ami:
  #   Om en ny AMI släpps vill vi INTE att Terraform ersätter servern.
  #   Det skulle radera all data och konfiguration!
  #   Uppdatera AMI manuellt och kontrollerat istället.
  # ---------------------------------------------------------------------------
  lifecycle {
    ignore_changes = [ami]
  }
}
