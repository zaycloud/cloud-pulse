# =============================================================================
# SECURITY MODULE
# =============================================================================
#
# ANSVAR:
# Denna modul skapar säkerhetsresurser:
#   - Security Group med brandväggsregler för Cloud-Pulse
#
# SÄKERHETSPRINCIPER I DENNA MODUL:
#   - SSH (22): Begränsas via variabel (default: hela internet för demo)
#   - Grafana (3000): Öppen för demo-visning
#   - Node Exporter (9100): ENDAST VPC-intern trafik (säkerhetslåst)
#   - Prometheus (9090): ENDAST VPC-intern trafik (säkerhetslåst)
#
# KOSTNAD: GRATIS
#
# =============================================================================


# -----------------------------------------------------------------------------
# LOCALS
# -----------------------------------------------------------------------------

locals {
  common_tags = merge(
    {
      Project   = var.project_name
      Module    = "security"
      ManagedBy = "terraform"
    },
    var.tags
  )
}


# -----------------------------------------------------------------------------
# SECURITY GROUP
# -----------------------------------------------------------------------------
#
# VAD ÄR EN SECURITY GROUP?
# En virtuell brandvägg på instans-nivå.
# Kontrollerar vilken nätverkstrafik som tillåts IN och UT.
#
# INGRESS = Inkommande trafik (någon → din server)
# EGRESS  = Utgående trafik (din server → något)
#
# STATEFUL BETEENDE:
# Security Groups är "stateful" vilket betyder:
#   - Om INKOMMANDE trafik tillåts på port 22
#   - Så tillåts SVARET automatiskt ut (utan explicit egress-regel)
#
# CIDR-BLOCK I REGLER:
#   "0.0.0.0/0"      = Hela internet (alla IP-adresser)
#   "10.0.0.0/16"    = Endast VPC-intern trafik
#   "84.23.45.67/32" = Endast en specifik IP
#
# SÄKERHETSFÖRBÄTTRING:
# Port 9100 (Node Exporter) och 9090 (Prometheus) är LÅSTA till VPC:n.
# 
# VARFÖR?
# Node Exporter exponerar känslig systeminformation:
#   - CPU-användning
#   - Minnesanvändning
#   - Disk-information
#   - Nätverksstatistik
#   - Körande processer
#
# Om en hackare ser denna data kan de:
#   - Kartlägga din server
#   - Hitta svagheter
#   - Planera attacker
#
# Genom att låsa till var.vpc_cidr (t.ex. 10.0.0.0/16) kan ENDAST
# resurser INOM din VPC nå dessa portar.
#
# -----------------------------------------------------------------------------

resource "aws_security_group" "main" {
  name        = "${var.project_name}-sg"
  description = "Security group for ${var.project_name} - SSH, Grafana, Prometheus stack"
  vpc_id      = var.vpc_id

  # ---------------------------------------------------------------------------
  # INGRESS: SSH (Port 22) - DUAL STACK (IPv4 + IPv6)
  # ---------------------------------------------------------------------------
  # SYFTE: Fjärrstyrning av servern
  # ANVÄNDS AV: Ansible, manuell felsökning, dig
  #
  # DUAL STACK FÖRKLARING:
  # AWS Security Groups har SEPARATA attribut för IPv4 och IPv6:
  #   - cidr_blocks      = IPv4 (t.ex. "84.23.156.78/32")
  #   - ipv6_cidr_blocks = IPv6 (t.ex. "2a09:bac2:5276:505::80:d5/128")
  #
  # Du kan INTE blanda dem! En IPv6 i cidr_blocks ger fel.
  #
  # VARFÖR BÅDA?
  # Många ISPs (särskilt i Sverige) ger nu främst IPv6-adresser.
  # För att säkerställa åtkomst oavsett vilken IP-typ du har,
  # konfigurerar vi båda.
  # ---------------------------------------------------------------------------
  ingress {
    description      = "SSH access for remote management (IPv4 + IPv6)"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.allowed_ssh_cidr_ipv4] # IPv4-adresser
    ipv6_cidr_blocks = [var.allowed_ssh_cidr_ipv6] # IPv6-adresser
  }

  # ---------------------------------------------------------------------------
  # INGRESS: Grafana (Port 3000)
  # ---------------------------------------------------------------------------
  # SYFTE: Webbgränssnitt för visualisering
  # ANVÄNDS AV: Din webbläsare
  #
  # Öppen för alla (0.0.0.0/0) så du kan:
  #   - Visa demon från vilken dator som helst
  #   - Dela länken med andra
  #
  # I produktion: Lägg bakom load balancer med HTTPS
  # ---------------------------------------------------------------------------
  ingress {
    description = "Grafana web dashboard"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP on port 8080 Grafana web dashboard"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    description = "Public HTTP web traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Public HTTP web traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---------------------------------------------------------------------------
  # INGRESS: Node Exporter (Port 9100) - SÄKERHETSLÅST!
  # ---------------------------------------------------------------------------
  # SYFTE: Exponerar server-metrics
  # ANVÄNDS AV: Prometheus (internt)
  #
  # EXPONERAR:
  #   - node_cpu_seconds_total
  #   - node_memory_MemAvailable_bytes
  #   - node_disk_read_bytes_total
  #   - node_network_receive_bytes_total
  #   - ... och 100+ andra metrics
  #
  # VARFÖR LÅST?
  # Denna data hjälper hackare kartlägga din server.
  # Prometheus körs på SAMMA server, så den når via localhost.
  # Men vi öppnar för hela VPC:n (var.vpc_cidr) för framtida skalning.
  # ---------------------------------------------------------------------------
  ingress {
    description = "Node Exporter metrics - VPC internal only"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # ---------------------------------------------------------------------------
  # INGRESS: Prometheus (Port 9090) - SÄKERHETSLÅST!
  # ---------------------------------------------------------------------------
  # SYFTE: Metrics-databas och query-gränssnitt
  # ANVÄNDS AV: Grafana (internt), eventuell admin-åtkomst
  #
  # Prometheus har ett webb-UI på port 9090 där du kan:
  #   - Köra PromQL-queries
  #   - Se targets och deras status
  #   - Visa konfiguration
  #
  # Låst till VPC för säkerhet. Grafana når det internt.
  # ---------------------------------------------------------------------------
  ingress {
    description = "Prometheus - VPC internal only"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # ---------------------------------------------------------------------------
  # EGRESS: All utgående trafik
  # ---------------------------------------------------------------------------
  # SYFTE: Låta servern kontakta internet
  #
  # BEHÖVS FÖR:
  #   - apt update/upgrade (systemuppdateringar)
  #   - docker pull (ladda ner container images)
  #   - DNS-upplösning (hitta IP för domännamn)
  #   - NTP (tidssynkronisering)
  #
  # from_port = 0, to_port = 0:
  #   Betyder "alla portar" (0-65535)
  #
  # protocol = "-1":
  #   Betyder "alla protokoll" (TCP, UDP, ICMP, etc.)
  #
  # I produktion: Kan begränsas till specifika destinationer
  # ---------------------------------------------------------------------------
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sg"
  })

  # ---------------------------------------------------------------------------
  # LIFECYCLE
  # ---------------------------------------------------------------------------
  # create_before_destroy = true:
  #   Vid ändringar, skapa nya först innan gamla tas bort.
  #   Förhindrar driftstopp om EC2 refererar till denna SG.
  # ---------------------------------------------------------------------------
  lifecycle {
    create_before_destroy = true
  }
}
