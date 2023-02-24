terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "random_pet" "default" {
  length = 1
}


module "rg" {
  source   = "./modules/rg"
  name     = random_pet.default.id
  location = "eastus"
}

module "vnet" {
  source              = "./modules/vnet"
  name                = "test-net"
  resource_group_name = module.rg.name
  location            = module.rg.location
  address_space       = ["10.0.0.0/24"]

  subnets = [
    {
      name         = "subnet-1"
      address_cidr = "10.0.0.0/29"
    },
    {
      name         = "subnet-2"
      address_cidr = "10.0.0.8/29"
    }
  ]

}
