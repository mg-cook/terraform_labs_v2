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
}

resource "azurerm_resource_group" "resgrp" {
  name     = "RG4"
  location = "westeurope"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "myVNet"
  resource_group_name = "RG4"
  location            = "westeurope"
  address_space       = ["10.21.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "myAGSubnet"
  resource_group_name  = "RG4"
  virtual_network_name = "myVNet"
  address_prefixes     = ["10.21.0.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "myBackendSubnet"
  resource_group_name  = "RG4"
  virtual_network_name = "myVNet"
  address_prefixes     = ["10.21.1.0/24"]
}

resource "azurerm_public_ip" "pubip" {
  name                = "myAGPublicIPAddress"
  resource_group_name = "RG4"
  location            = "westeurope"
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_application_gateway" "appgtw" {
  name                = "myAppGateway"
  resource_group_name = "RG4"
  location            = "westeurope"

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

resource "azurerm_network_interface" "nic1" {
  name                = "nic-1"
  location            = "westeurope"
  resource_group_name = "RG4"

  ip_configuration {
    name                          = "nic-ipconfig-1"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "nic2" {
  name                = "nic-2"
  location            = "westeurope"
  resource_group_name = "RG4"

  ip_configuration {
    name                          = "nic-ipconfig-2"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic-assc1" {
  network_interface_id    = azurerm_network_interface.nic1.id
  ip_configuration_name   = "nic-ipconfig-1"
  backend_address_pool_id = tolist(azurerm_application_gateway.appgtw.backend_address_pool).0.id
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic-assc2" {
  network_interface_id    = azurerm_network_interface.nic2.id
  ip_configuration_name   = "nic-ipconfig-2"
  backend_address_pool_id = tolist(azurerm_application_gateway.appgtw.backend_address_pool).0.id
}

resource "random_password" "password" {
  length = 16
  special = true
  lower = true
  upper = true
  numeric = true
}

resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "VM1"
  resource_group_name = "RG4"
  location            = "westeurope"
  size                = "Standard_DS2_v2"
  admin_username      = "azureadmin"
  admin_password      = random_password.password.result

  network_interface_ids = [
    azurerm_network_interface.nic1.id,
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

resource "azurerm_windows_virtual_machine" "vm2" {
  name                = "VM2"
  resource_group_name = "RG4"
  location            = "westeurope"
  size                = "Standard_DS2_v2"
  admin_username      = "azureadmin"
  admin_password      = random_password.password.result

  network_interface_ids = [
    azurerm_network_interface.nic2.id,
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


resource "azurerm_virtual_machine_extension" "vm-extensions1" {
  name                 = "vm1-ext"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm1.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS
}

resource "azurerm_virtual_machine_extension" "vm-extensions2" {
  name                 = "vm2-ext"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm2.id
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


