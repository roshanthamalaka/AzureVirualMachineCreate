
resource "azurerm_resource_group" "stgaccRG" {
  name     = "stgacc"
  location = "West Europe"
}

variable "stgname" {
  type = list
  default= ["enesh","magepukamatadenna123","mahindarajapaksha"]
}

resource "azurerm_storage_account" "stgacc" {
  name                     = var.stgname[count.index]
  resource_group_name      = azurerm_resource_group.stgaccRG.name
  location                 = azurerm_resource_group.stgaccRG.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }

  count=3

}