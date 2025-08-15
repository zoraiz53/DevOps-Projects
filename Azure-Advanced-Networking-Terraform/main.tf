terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Specify a version constraint
    }
  }

  backend "azurerm" {
    resource_group_name  = "Project-ResourceGrp"
    storage_account_name = "storageaccount965"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true

  }
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "resource_grp" {
  name = var.resource_group_name
}
