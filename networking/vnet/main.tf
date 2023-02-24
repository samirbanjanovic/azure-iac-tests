resource "azurerm_virtual_network" "name" {
  name = var.vnet_name
  location = var.location
  
}