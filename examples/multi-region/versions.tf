terraform {
  required_version = ">= 1.0"

  required_providers {
    streamsec = {
      source  = "streamsec-terraform/streamsec"
      version = ">= 1.13.2"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.53.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.11"
    }
  }
}
