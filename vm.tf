variable "vnet_name" {
  default = "buildvnet"
}

variable "subnetname" {
  default = "public_subnet" 
}

variable "publicipname" {
  default = "bulidagentIP"
}

variable "vmname" {
  default= "buildagent"
}
#Create Virtual Network 
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "public" {
  name                 = var.subnetname
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}


#Create Public IP address 

resource "azurerm_public_ip" "pubip" {
  name                = var.publicipname
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Dynamic"
  
}

#Create A Security Group 
resource "azurerm_network_security_group" "nsg" {
  name                = "BuildAgentASG"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}





#Create Network Interface and associate Public IP 
resource "azurerm_network_interface" "buildagent" {
  name                = var.vmname
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = var.vmname
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pubip.id
  }
}

#Association Security Group with the Network Interface 
resource "azurerm_network_interface_security_group_association" "ngsassoc" {
  network_interface_id      = azurerm_network_interface.buildagent.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#Create Windows VM 
resource "azurerm_virtual_machine" "main" {
  name                  = var.vmname
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.buildagent.id]
  vm_size               = "Standard_B1s"

   delete_os_disk_on_termination = true

 

#USe Az vm image list to identify correct parameter more  visit https://learn.microsoft.com/en-us/cli/azure/vm/image?source=recommendations&view=azure-cli-latest
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "roshan"
    admin_password = "Thamalaka@123"
  }

  #Disbale IF Linux
  /*os_profile_windows_config {
    enable_automatic_upgrades = false
  }*/
 

 os_profile_linux_config {
   disable_password_authentication = false
 }
  tags = {
    environment = "staging"
  }
}