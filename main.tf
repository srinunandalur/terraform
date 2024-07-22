# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.98.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "db20cc1d-15a9-4351-a768-7f694cd943b7"
  tenant_id       = "57f1df8a-017e-4f3d-99d0-669ea4a88294"
  client_id       = "8d41642f-07db-45c8-8207-c5635ed33d4d"

  features {}
}

resource "azurerm_resource_group" "rg3" {
  name     = "srinuprivateendpoint-rg"
  location = "West US 2"
}

resource "azurerm_virtual_network" "rg3" {
  name                = "cdss-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg3.location
  resource_group_name = azurerm_resource_group.rg3.name
}

resource "azurerm_subnet" "storage" {
  name                                           = "cdss-storagesubnet"
  resource_group_name                            = azurerm_resource_group.rg3.name
  virtual_network_name                           = azurerm_virtual_network.rg3.name
  address_prefix                                 = "10.0.1.0/24"
  enforce_private_link_endpoint_network_policies = true
  // enforce_private_link_service_network_policies = false
  // service_endpoints                              = ["Microsoft.Storage"]
}  

resource "random_integer" "sa_num" {
  min = 10000
  max = 99999
}

resource "azurerm_storage_account" "rg3" {
  name                     = "cdssstorage"
  resource_group_name       = azurerm_resource_group.rg3.name
  location                  = azurerm_resource_group.rg3.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
}

resource "azurerm_storage_container" "rg3" {
  name                  = "cdssacc"
  storage_account_name  = azurerm_storage_account.rg3.name
  container_access_type = "private"
}

resource "azurerm_private_endpoint" "rg3" {
  name                = "cdssprivate"
  location            = azurerm_resource_group.rg3.location
  resource_group_name = azurerm_resource_group.rg3.name
  subnet_id           = azurerm_subnet.storage.id

  private_service_connection {
    name                           = "cdssconnec"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.rg3.id
    subresource_names              = ["blob"]
  }

}