output "name" {
  value = var.name
}

output "resource_group_name" {
  value = data.azurerm_resource_group.chef_resource_group.name
}

output "location" {
  value = data.azurerm_resource_group.chef_resource_group.location
}

output "public_ipv4_address" {
  value = data.azurerm_public_ip.default.ip_address
}

output "private_ipv4_address" {
  value = azurerm_network_interface.default.private_ip_address
}

output "private_ipv4_domain" {
  value = azurerm_network_interface.default.internal_domain_name_suffix
}

output "private_ipv4_fqdn" {
  value = "${var.name}.${azurerm_network_interface.default.internal_domain_name_suffix}"
}

output "ssh_username" {
  value = "azure"
}
