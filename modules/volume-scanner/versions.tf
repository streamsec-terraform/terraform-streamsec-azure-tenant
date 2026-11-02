terraform {
  required_version = ">= 1.3" # startswith()

  required_providers {
    streamsec = {
      source  = "streamsec-terraform/streamsec"
      version = ">= 1.15.0" # streamsec_azure_volume_scanner and its acknowledgement
    }
    azurerm = {
      source = "hashicorp/azurerm"
      # logs_destination on the Container Apps environment: added in 4.17, required from 5.0.
      version = ">= 4.17"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.0"
    }
  }
}
