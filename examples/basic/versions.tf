terraform {
  # Must not be lower than any module this example calls: modules/volume-scanner requires >= 1.3.
  required_version = ">= 1.3"

  required_providers {
    streamsec = {
      source  = "streamsec-terraform/streamsec"
      version = ">= 1.15.0" # modules/volume-scanner
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}
