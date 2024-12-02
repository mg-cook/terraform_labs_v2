terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.18.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "lab6" {
  name     = "RG1"
  location = "West Europe"
}

resource "azurerm_virtual_network" "lab6" {
  name                = "test-vNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab6.location
  resource_group_name = azurerm_resource_group.lab6.name
}


resource "azurerm_subnet" "lab6" {
  name                 = "test-subnet"
  resource_group_name  = azurerm_resource_group.lab6.name
  virtual_network_name = azurerm_virtual_network.lab6.name
  address_prefixes      = ["10.0.1.0/24"]
}

