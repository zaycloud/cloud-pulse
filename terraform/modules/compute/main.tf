
# Common tags for compute resources.
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

# Get the latest Ubuntu 22.04 image.
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

# Upload your local SSH public key to AWS.
resource "aws_key_pair" "this" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.ssh_public_key_path)

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-key"
  })
}

# Create the EC2 server.
resource "aws_instance" "this" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id

  # Use IMDSv2 for metadata access.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Keep the root disk encrypted.
  root_block_device {
    volume_size           = var.volume_size
    volume_type           = var.volume_type
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-server"
  })

  # Do not replace server when AMI updates.
  lifecycle {
    ignore_changes = [ami]
  }
}
