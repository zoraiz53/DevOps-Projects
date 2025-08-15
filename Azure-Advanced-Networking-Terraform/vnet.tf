resource "azurerm_virtual_network" "name" {
  name = var.vnet_name
  address_space = [var.vnet_address_space]
  location = data.azurerm_resource_group.resource_grp.location
  resource_group_name = data.azurerm_resource_group.resource_grp.name
}