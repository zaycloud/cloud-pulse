
# Terraform and provider versions.
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS region settings.
provider "aws" {
  region = var.aws_region
}
