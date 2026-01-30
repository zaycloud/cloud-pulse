# =============================================================================
# AUTO-GENERATED INVENTORY
# =============================================================================
#
# Detta skapar automatiskt Ansible's inventory.ini-fil.
# Terraform tar den nya IP-adressen och skriver ner den i en fil.
#
# Resultat: Du slipper uppdatera inventory.ini manuellt!
#
# =============================================================================

resource "local_file" "ansible_inventory" {
  content = <<-EOT
    [webservers]
    cloud-pulse-server ansible_host=${module.compute.public_ip} ansible_user=ubuntu

    [all:vars]
    ansible_python_interpreter=/usr/bin/python3
    ansible_ssh_private_key_file=${replace(var.ssh_public_key_path, ".pub", "")}
  EOT

  filename = "../ansible/inventory.ini"
}
