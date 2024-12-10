terraform {

  required_version = ">=0.15"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.11.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id

}

resource "azurerm_resource_group" "resgrp" {
  name     = var.rg_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.resgrp.name
  location            = azurerm_resource_group.resgrp.location
  address_space       = [var.vnet_network]
}

resource "azurerm_subnet" "frontend" {
  name                 = var.subnet_fe_name
  resource_group_name  = azurerm_resource_group.resgrp.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_fe_network]
}

resource "azurerm_subnet" "backend" {
  name                 = var.subnet_be_name
  resource_group_name  = azurerm_resource_group.resgrp.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_be_network]
}

resource "azurerm_public_ip" "pubip" {
  name                = var.public_ip_name
  resource_group_name = azurerm_resource_group.resgrp.name
  location            = azurerm_resource_group.resgrp.location
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_application_gateway" "appgtw" {
  name                = "myAppGateway"
  resource_group_name = azurerm_resource_group.resgrp.name
  location            = azurerm_resource_group.resgrp.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = "qalabFrontendPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "qalabAGIPConfig"
    public_ip_address_id = azurerm_public_ip.pubip.id
  }

  backend_address_pool {
    name = "qalabBackendPool"
  }

  backend_http_settings {
    name                  = "qalabHTTPsetting"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "qalabListener"
    frontend_ip_configuration_name = "qalabAGIPConfig"
    frontend_port_name             = "qalabFrontendPort"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "qalabRoutingRule"
    rule_type                  = "Basic"
    http_listener_name         = "qalabListener"
    backend_address_pool_name  = "qalabBackendPool"
    backend_http_settings_name = "qalabHTTPsetting"
    priority = 10
  }
}

resource "azurerm_network_interface" "nic" {
  for_each = tomap({
    "VM1" ="nic-vm1"
    "VM2" ="nic-vm2"
  })
  name                = each.value
  location            = "westeurope" 
  resource_group_name = azurerm_resource_group.resgrp.name

  ip_configuration {
    name                          = "${each.key}-ipconfig"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic-assoc" {
  for_each = azurerm_network_interface.nic
  network_interface_id    = each.value.id
  ip_configuration_name   = "${each.key}-ipconfig"
  backend_address_pool_id = one(azurerm_application_gateway.appgtw.backend_address_pool).id  
}


resource "random_password" "password" {
  length = 16
  special = true
  lower = true
  upper = true
  numeric = true
}

resource "azurerm_windows_virtual_machine" "VM" {
  for_each = toset(["VM1", "VM2"])
  name                = each.value 
  resource_group_name = azurerm_resource_group.resgrp.name
  location            = azurerm_resource_group.resgrp.location
  size                = "Standard_DS2_v2"
  admin_username      = "azureadmin"
  admin_password      = random_password.password.result

  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "vm-extensions" {
  for_each = toset(["VM1", "VM2"])
  name                 = "${each.value}-ext"
  virtual_machine_id   = azurerm_windows_virtual_machine.VM[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS

}


output "appgw_public_ip_address" {
  description = "The public IP address of Application Gateway."
  value       = azurerm_public_ip.pubip.ip_address
}


