module "workstation" {
  source = "../../modules/arm_instance"

  arm_tenant_id           = var.arm_tenant_id
  arm_subscription_id     = var.arm_subscription_id
  arm_location            = var.arm_location
  arm_resource_group_name = var.arm_resource_group_name
  arm_department          = var.arm_department
  arm_contact             = var.arm_contact
  arm_ssh_key_file        = var.arm_ssh_key_file
  arm_instance_type       = var.arm_instance_type
  platform                = var.workstation_platform
  build_prefix            = var.build_prefix
  name                    = "workstation-${replace(var.workstation_platform, ".", "")}-${var.scenario}-${replace(var.node_platform, ".", "")}"
}

module "node" {
  source = "../../modules/arm_instance"

  arm_tenant_id           = var.arm_tenant_id
  arm_subscription_id     = var.arm_subscription_id
  arm_location            = var.arm_location
  arm_resource_group_name = var.arm_resource_group_name
  arm_department          = var.arm_department
  arm_contact             = var.arm_contact
  arm_ssh_key_file        = var.arm_ssh_key_file
  arm_instance_type       = var.arm_instance_type
  platform                = var.node_platform
  build_prefix            = var.build_prefix
  name                    = "node-${replace(var.workstation_platform, ".", "")}-${var.scenario}-${replace(var.node_platform, ".", "")}"
}

resource "null_resource" "workstation_config" {
  # provide some connection info
  connection {
    type = "ssh"
    user = module.workstation.ssh_username
    host = module.workstation.public_ipv4_address
  }

  # install chef-infra
  provisioner "remote-exec" {
    inline = [
      "set -evx",
      "echo -e '\nBEGIN INSTALL CHEF INFRA\n'",
      "curl -vo /tmp/${replace(var.workstation_client_version_url, "/^.*\\//", "")} ${var.workstation_client_version_url}",
      "sudo ${replace(var.workstation_client_version_url, "rpm", "") != var.workstation_client_version_url ? "rpm -U" : "dpkg -iEG"} /tmp/${replace(var.workstation_client_version_url, "/^.*\\//", "")}",
      "scp -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' azure@chefserver:janedoe.pem /home/${module.workstation.ssh_username}",
      "knife configure --server-url 'https://chefserver.${module.workstation.private_ipv4_domain}/organizations/4thcoffee' --user janedoe --key /home/${module.workstation.ssh_username}/janedoe.pem --yes",
      "knife ssl fetch",
      "knife ssl check",
      "echo -e '\nEND INSTALL CHEF INFRA\n'",
    ]
  }
}

resource "null_resource" "workstation_test" {
  depends_on = [null_resource.workstation_config]

  connection {
    type = "ssh"
    user = module.workstation.ssh_username
    host = module.workstation.public_ipv4_address
  }

  # bootstrap node
  provisioner "remote-exec" {
    inline = [
      "set -evx",
      "echo -e '\nBEGIN BOOTSTRAP NODE\n'",
      "CHEF_LICENSE='accept' knife bootstrap ${module.node.private_ipv4_fqdn} --connection-user ${module.node.ssh_username} --sudo --node-name ${module.node.name} --bootstrap-install-command 'curl -vo /tmp/${replace(var.node_client_version_url, "/^.*\\//", "")} ${var.node_client_version_url}; ${replace(var.node_client_version_url, "rpm", "") != var.node_client_version_url ? "rpm -U" : "dpkg -iEG"} /tmp/${replace(var.node_client_version_url, "/^.*\\//", "")}' --yes",
      "echo -e '\nEND BOOTSTRAP NODE\n'",
    ]
  }

  # verify bootstrapped node
  provisioner "remote-exec" {
    inline = [
      "set -evx",
      "echo -e '\nVERIFY BOOTSTRAP NODE\n'",
      "knife node show ${module.node.name} --format json --long",
      "knife ssh 'name:${module.node.name}' uptime --ssh-user ${module.node.ssh_username}",
      "knife search node '*${module.node.name}*'",
      "knife node delete ${module.node.name} --yes",
      "knife client delete ${module.node.name} --yes",
      "echo -e '\nVERIFY BOOTSTRAP NODE\n'",
    ]
  }
}

resource "null_resource" "node_test" {
  depends_on = [null_resource.workstation_test]

  connection {
    type = "ssh"
    user = module.node.ssh_username
    host = module.node.public_ipv4_address
  }

  # verify node commands
  provisioner "remote-exec" {
    inline = [
      "set -evx",
      "echo -e '\nVERIFY NODE COMMANDS\n'",
      "ohai",
      "echo -e '\nVERIFY NODE COMMANDS\n'",
    ]
  }
}
