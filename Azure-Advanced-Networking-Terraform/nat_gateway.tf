resource "azurerm_public_ip" "public_ip" {
  name = "${var.nat_gateway_name}-public-ip"
  location = data.azurerm_resource_group.resource_grp.location
  resource_group_name = data.azurerm_resource_group.resource_grp.name
  allocation_method = "Static"
  sku = "Standard"
  zones = ["1"]
}

resource "azurerm_nat_gateway" "nat_gateway" {
  name = var.nat_gateway_name
  location = data.azurerm_resource_group.resource_grp.location
  resource_group_name = data.azurerm_resource_group.resource_grp.name
  sku_name = "Standard"
  zones = ["1"]
}

resource "azurerm_nat_gateway_public_ip_association" "azurerm_nat_association" {
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.public_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "subnet_nat_gateway_association" {
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
  subnet_id = azurerm_subnet.private_subnet.id
}