terraform {
  required_version = ">= 1.0"

  required_providers {
    # streamsec = {
    #   source  = "streamsec-terraform/streamsec"
    #   version = ">= 1.7"
    # }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.53.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.11"
    }
  }
}
