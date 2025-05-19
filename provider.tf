provider "azurerm" {
  resource_provider_registrations = "none" # "none" to avoid azurerm provider registration errors
  # resource_provider_registrations = ["Microsoft.Network", "Microsoft.Storage"] # Example
  features {}
}

data "azurerm_client_config" "default" {}

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}