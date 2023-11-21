terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.11.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}


# Resource group
resource "azurerm_resource_group" "rg" {
  name     = "myResourceGroup"
  location = "germanywestcentral"
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = "myCluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "myDNS"
  kubernetes_version  = "1.27.3"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_B2as_v2"
  }

  service_principal {
    client_id     = var.appId
    client_secret = var.password
  }

  role_based_access_control_enabled = true
}
