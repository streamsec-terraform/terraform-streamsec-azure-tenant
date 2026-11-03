terraform {
  required_version = ">= 1.3"

  required_providers {
    streamsec = {
      source  = "streamsec-terraform/streamsec"
      version = ">= 1.15.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.17"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.0"
    }
  }
}
