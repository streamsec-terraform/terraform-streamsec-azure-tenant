terraform {
  # grant_on's optional() attributes need Terraform 1.3
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.17"
    }
  }
}
