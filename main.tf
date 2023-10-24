
variable vmnames {
        default = ["swarm1","swarm2"]

}

#Use of Data Sources for exisisting resources
data "azurerm_resource_group" "rg" {
  name = "DCA_Exam_Practise"
}

provider "azurerm" {
  features {
    
  }
}

data "azurerm_subnet" "pubsub" {
  name                 = "public1"
  virtual_network_name = "dca_vnet"
  resource_group_name  = "DCA_Exam_Practise"
}


data "azurerm_storage_account" "strgacc" {
  name                = "dcabdstrgacc"
  resource_group_name = data.azurerm_resource_group.rg.name
}



resource "azurerm_network_interface" "main" {
  name                = "${var.vmnames[count.index]}-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = var.vmnames[count.index]
    subnet_id                     = data.azurerm_subnet.pubsub.id
    private_ip_address_allocation = "Dynamic"
  }

    count=2 
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.vmnames[count.index]}-vm"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.main[count.index].id]
  vm_size               = "Standard_B1s"

  #Enable Boot Diagnostics
  boot_diagnostics {
    enabled = true
    storage_uri = data.azurerm_storage_account.strgacc.primary_blob_endpoint
  }

  # Uncomment this line to delete the data disks automatically when deleting the VM
   delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.vmnames[count.index]}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.vmnames[count.index]
    admin_username = "roshan"
    admin_password = "Thamalaka@1234"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "staging"
  }
  count=2
}