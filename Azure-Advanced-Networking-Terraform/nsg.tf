resource "azurerm_network_security_group" "public_nsg" {
  name               = var.nsg_for_public_subnet_name
  resource_group_name = data.azurerm_resource_group.resource_grp.name
  location = data.azurerm_resource_group.resource_grp.location
  security_rule {
    name                       = "AllowInternetOutBound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["1-65535"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPandHTTPSInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSHmyIPInbound"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22"]
    source_address_prefix      = "<Your-Public-IP-Address>/32" # Replace with your public IP address
    destination_address_prefix = "*"
  }
}


resource "azurerm_network_security_group" "private_nsg" {
  name               = var.nsg_for_private_subnet_name
  resource_group_name = data.azurerm_resource_group.resource_grp.name
  location = data.azurerm_resource_group.resource_grp.location

  security_rule {
    name                       = "AllowPublicSubnetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["1-65535"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix =  "*"
  }

  security_rule {
    name                       = "DisallowAllInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["1-65535"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 300
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["1-65535"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "associating_public_nsg_to_public_subnet" {
  subnet_id                 = azurerm_subnet.public_subnet.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "associating_private_nsg_to_private_subnet" {
  subnet_id = azurerm_subnet.private_subnet.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}