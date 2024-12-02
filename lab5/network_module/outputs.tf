output "rg_name" {
  value = azurerm_resource_group.rg.name
}

output "rg_location" {
  value = azurerm_resource_group.rg.location
}


output "frontend_subnet_id" {
  value = azurerm_subnet.frontend.id
}

output "backend_subnet_id" {
  value = azurerm_subnet.backend.id
}

output "public_ip_address" {
  value = azurerm_public_ip.pip.ip_address
}

output "public_ip_address_id" {
  value = azurerm_public_ip.pip.id
}