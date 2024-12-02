resource "random_password" "password" {
  length  = 16
  special = true
  lower   = true
  upper   = true
  numeric = true
}

resource "azurerm_windows_virtual_machine" "VM" {
  for_each = toset(["VM1", "VM2"])
  name                = each.value 
  resource_group_name = module.networking.rg_name
  location            = module.networking.rg_location
  size                = "Standard_DS2_v2"
  admin_username      = "azureadmin"
  admin_password      = random_password.password.result

  network_interface_ids = [
    azurerm_network_interface.example[each.key].id,
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

resource "azurerm_network_interface" "example" {
  for_each = tomap({
    "VM1" ="nic-vm1"
    "VM2" ="nic-vm2"
  })
  name                = each.value
  location            = module.networking.rg_location
  resource_group_name = module.networking.rg_name

  ip_configuration {
    name                          = "${each.key}-ipconfig"
    subnet_id                     = module.networking.backend_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

