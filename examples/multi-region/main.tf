provider "azurerm" {
  features {}
}

provider "streamsec" {
  host         = "xxxxx.streamsec.io"
  username     = "xxxxx@example.com"
  password     = "xxxxxxxxxxxx"
  workspace_id = "xxxxxxxxxxxx"
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  lower   = true
  numeric = true
  upper   = false
}

################################################################################
# Tenant (global - deployed once)
#
# Registers the Azure AD tenant with Stream Security and creates the
# service principal with reader permissions on the specified subscriptions.
################################################################################

module "tenant" {
  source        = "../../"
  display_name  = "test"
  subscriptions = var.subscriptions
}

################################################################################
# Real Time Events (per region)
#
# Each region gets its own Event Hub and Function App.
# The primary region collects control plane logs (AAD + subscription activity)
# in addition to data plane logs. Secondary regions collect data plane only.
#
# Resource-level diagnostic settings (Key Vault, Storage Account) can be
# enforced automatically by setting enable_data_plane_logging = true, or
# configured manually per: https://docs.streamsec.io/docs/integrations-cloud-azure-diag
################################################################################

module "real_time" {
  source   = "../../modules/real-time-events"
  for_each = var.regions

  subscriptions = var.subscriptions
  location      = each.value.location

  # Resource names per region
  resource_group_name       = "rg-streamsec-rte-${each.key}"
  application_insights_name = "appi-streamsec-rte-${each.key}"
  service_plan_name         = "asp-streamsec-rte-${each.key}"
  function_name             = "funcapp-streamsec-rte-${each.key}-${random_string.suffix.result}"
  diagnostic_setting_name   = "ds-streamsec-rte-${each.key}"

  # Event Hub: use existing or create new
  create_eventhub_namespace                  = each.value.existing_eventhub == null
  create_eventhub                            = each.value.existing_eventhub == null
  eventhub_namespace_name                    = each.value.existing_eventhub != null ? each.value.existing_eventhub.eventhub_namespace_name : "eventhubns-streamsec-rte-${each.key}-${random_string.suffix.result}"
  eventhub_name                              = each.value.existing_eventhub != null ? each.value.existing_eventhub.eventhub_name : "eventhub-streamsec-rte-${each.key}-${random_string.suffix.result}"
  eventhub_namespace_authorization_rule_name = each.value.existing_eventhub != null ? each.value.existing_eventhub.eventhub_namespace_authorization_rule_name : "eventhubns-ar-streamsec-rte-${each.key}"
  eventhub_namespace_resource_group_name     = each.value.existing_eventhub != null ? each.value.existing_eventhub.eventhub_namespace_resource_group_name : null
  eventhub_authorization_rule_name           = "eventhub-ar-streamsec-rte-${each.key}"

  # Control plane logs only in primary region
  create_aad_diagnostic_setting          = each.key == var.primary_region
  create_subscription_diagnostic_setting = each.key == var.primary_region

  depends_on = [module.tenant]
}

################################################################################
# Flow Logs (per region)
#
# Flow logs are written to region-local storage accounts by Azure. Each
# region with NSG flow logs needs its own Function App to read from the
# local storage account.
################################################################################

module "flowlogs" {
  source   = "../../modules/flowlogs"
  for_each = var.flowlog_storage_accounts

  storage_account_name                = each.value.storage_account_name
  storage_account_resource_group_name = each.value.storage_account_resource_group_name
  location                            = var.regions[each.key].location

  # Unique resource names per region
  resource_group_name       = "rg-stream-flowlogs-${each.key}"
  application_insights_name = "appi-stream-flowlogs-${each.key}"
  service_plan_name         = "asp-stream-flowlogs-${each.key}"
  function_name             = "funcapp-stream-flowlogs-${each.key}-${random_string.suffix.result}"

  depends_on = [module.tenant]
}

################################################################################
# Diagnostic Policy (per region)
#
# When enabled, assigns Azure built-in policies to enforce data-plane
# diagnostic settings (Key Vault AuditEvent, Storage Account blob logs) on
# all resources, streaming to the regional Event Hub.
################################################################################

module "diagnostic_policy" {
  source   = "../../modules/diagnostic-policy"
  for_each = var.enable_data_plane_logging ? var.regions : {}

  subscriptions                            = var.subscriptions
  location                                 = each.value.location
  eventhub_namespace_authorization_rule_id = module.real_time[each.key].eventhub_namespace_authorization_rule_id
  eventhub_name                            = module.real_time[each.key].eventhub_name

  depends_on = [module.real_time]
}
