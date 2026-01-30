# =============================================================================
# TERRAFORM BLOCK
# =============================================================================
#
# SYFTE:
# Definierar vilka "plugins" (providers) Terraform behöver.
# En provider översätter Terraform-kod till API-anrop mot molntjänsten.
#
# NÄR DU KÖR "terraform init":
#   1. Terraform läser detta block
#   2. Laddar ner AWS-providern från registry.terraform.io
#   3. Sparar den i mappen .terraform/
#
# VERSION SYNTAX:
#   "~> 5.0" betyder "version 5.x, men INTE 6.x"
#   Detta skyddar dig från brytande ändringar i nya major-versioner
#
# =============================================================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# PROVIDER CONFIGURATION
# =============================================================================
#
# REGION FÖRKLARING:
# AWS har datacenter över hela världen, varje med ett unikt namn:
#   - us-east-1    = Virginia, USA (äldst, mest tjänster)
#   - eu-west-1    = Irland
#   - eu-north-1   = Stockholm, Sverige (lägst latens för dig)
#
# Vi använder en variabel för flexibilitet.
#
# =============================================================================

provider "aws" {
  region = var.aws_region
}
