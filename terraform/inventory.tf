
# Build Ansible inventory from Terraform outputs.
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
