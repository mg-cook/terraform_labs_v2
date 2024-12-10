## Task 1
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.18.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "RG3" {
  name     = "RG3"
  location = "West Europe"
}

resource "azurerm_virtual_network" "lab3_vnet" {
  name                = "lab3-vnet"
  location            = azurerm_resource_group.RG3.location
  resource_group_name = azurerm_resource_group.RG3.name
  address_space       = ["10.1.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]
}

resource "azurerm_subnet" "lab3_subnet" {
  name                 = "lab3-subnet"
  resource_group_name  = azurerm_resource_group.RG3.name
  virtual_network_name = azurerm_virtual_network.lab3_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}


## Task 2

resource "azurerm_route_table" "lab3_route_table" {
  name                          = "lab3-route-table"
  location                      = azurerm_resource_group.RG3.location
  resource_group_name           = azurerm_resource_group.RG3.name
  disable_bgp_route_propagation = false

  route {
    name           = "routelocal"
    address_prefix = "10.1.0.0/16"
    next_hop_type  = "VnetLocal"
  }
  route {
    name           = "routeinternet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "example" {
  subnet_id      = azurerm_subnet.lab3_subnet.id
  route_table_id = azurerm_route_table.lab3_route_table.id
}

## Task 3

resource "azurerm_network_security_group" "lab3_securitygroup" {
  name                = "lab3-SecurityGroup"
  location            = azurerm_resource_group.RG3.location
  resource_group_name = azurerm_resource_group.RG3.name

  security_rule {
    name                       = "WebAdminNSG"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.lab3_subnet.id
  network_security_group_id = azurerm_network_security_group.lab3_securitygroup.id
}

## Task 4
resource "azurerm_network_interface" "lab3_nic" {
  name                = "lab3-nic"
  location            = azurerm_resource_group.RG3.location
  resource_group_name = azurerm_resource_group.RG3.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab3_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "lab3_vm" {
  name                = "VM3"
  resource_group_name = azurerm_resource_group.RG3.name
  location            = azurerm_resource_group.RG3.location
  size                = "Standard_Ds2_v2"
  admin_username      = "TPadminuser"
  admin_password      = "TPP@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.lab3_nic.id,
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  tags = {
    Lab_edit = "SecondChange"
  }
}