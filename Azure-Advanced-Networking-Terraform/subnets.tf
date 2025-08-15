resource "azurerm_subnet" "public_subnet" {
 name                  = var.public_subnet_name
  resource_group_name  = data.azurerm_resource_group.resource_grp.name
  virtual_network_name = azurerm_virtual_network.name.name
  address_prefixes     = [var.public_subnet_address_space]
}

resource "azurerm_subnet" "private_subnet" {
  name                  = var.private_subnet_name
  resource_group_name  = data.azurerm_resource_group.resource_grp.name
  virtual_network_name = azurerm_virtual_network.name.name
  address_prefixes     = [var.private_subnet_address_space]
}

