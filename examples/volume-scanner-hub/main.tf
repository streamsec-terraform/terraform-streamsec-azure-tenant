###############################################################################
# A volume scanner hub and one subscription it scans
#
# The hub subscription runs the scanner (modules/volume-scanner) and also scans
# the other subscription, with the access modules/volume-scanner-hub-access
# grants its managed identity there. Both subscriptions must be in the tenant's
# Stream Security integration, by the root module or the console.
###############################################################################

# The hub subscription, where the scanner runs.
provider "azurerm" {
  alias           = "hub"
  subscription_id = var.hub_subscription_id
  features {}
}

# Role definitions and assignments name their scope, so this provider's
# subscription only sets where the API calls are authenticated.
provider "azurerm" {
  subscription_id = var.scanned_subscription_id
  features {}
}

# Reads STREAMSEC_HOST, STREAMSEC_WORKSPACE_ID and STREAMSEC_API_TOKEN from the
# environment.
provider "streamsec" {}

data "streamsec_azure_tenant" "this" {
  tenant_id = var.tenant_id
}

module "hub_scanner" {
  source      = "../../modules/volume-scanner"
  account_id  = data.streamsec_azure_tenant.this.id
  customer_id = var.workspace_id
  location    = var.location

  providers = {
    azurerm = azurerm.hub
  }
}

# Then choose the subscription in the Stream Security console, under the hub's
# "Subscriptions this scanner scans".
module "hub_access" {
  source = "../../modules/volume-scanner-hub-access"

  hub_principal_ids = {
    (var.hub_subscription_id) = module.hub_scanner.managed_identity_principal_id
  }

  grant_on = {
    subscription_ids = [var.scanned_subscription_id]
  }
}
