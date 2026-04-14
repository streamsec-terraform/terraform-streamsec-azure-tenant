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
  display_name  = var.display_name # This name will appear in the Stream Security platform to identify this tenant
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
# enforced automatically via the diagnostic-policy-kv and diagnostic-policy-sa
# modules below, or configured manually per:
# https://docs.streamsec.io/docs/integrations-cloud-azure-diag
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
# Diagnostic Policy Identity — one UAMI per region, shared across all policies
################################################################################

locals {
  any_policy_enabled = var.enable_kv_data_plane_logging || var.enable_sa_data_plane_logging || var.enable_sa_files_data_plane_logging
}

resource "azurerm_user_assigned_identity" "policy" {
  count = local.any_policy_enabled ? 1 : 0

  name                = "id-streamsec-policy"
  location            = var.regions[var.primary_region].location
  resource_group_name = module.real_time[var.primary_region].resource_group_name
}

resource "azurerm_role_assignment" "policy_monitoring_contributor" {
  for_each = local.any_policy_enabled ? {
    for sub in var.subscriptions : sub => sub
  } : {}

  scope                = "/subscriptions/${each.value}"
  role_definition_name = "Monitoring Contributor"
  principal_id         = azurerm_user_assigned_identity.policy[0].principal_id
}

resource "azurerm_role_assignment" "policy_eventhub_contributor" {
  for_each = local.any_policy_enabled ? var.regions : {}

  scope                = module.real_time[each.key].eventhub_namespace_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.policy[0].principal_id
}

################################################################################
# Key Vault Diagnostic Policy (per region)
#
# Custom Azure policy to enforce AuditEvent logging on all Key Vaults,
# streaming to the regional Event Hub.
################################################################################

module "diagnostic_policy_kv" {
  source   = "../../modules/diagnostic-policy-kv"
  for_each = var.enable_kv_data_plane_logging ? var.regions : {}

  subscriptions                            = var.subscriptions
  location                                 = each.value.location
  region_key                               = each.key
  eventhub_namespace_authorization_rule_id = module.real_time[each.key].eventhub_namespace_authorization_rule_id
  eventhub_name                            = module.real_time[each.key].eventhub_name
  policy_identity_id                       = azurerm_user_assigned_identity.policy[0].id

  depends_on = [module.real_time, azurerm_role_assignment.policy_monitoring_contributor, azurerm_role_assignment.policy_eventhub_contributor]
}

################################################################################
# Storage Account Blob Diagnostic Policy (per region)
#
# Uses custom Azure policy to enforce StorageRead, StorageWrite, StorageDelete
# logging on all Storage Account blob services, streaming to the regional
# Event Hub.
################################################################################

module "diagnostic_policy_sa" {
  source   = "../../modules/diagnostic-policy-sa"
  for_each = var.enable_sa_data_plane_logging ? var.regions : {}

  subscriptions                            = var.subscriptions
  location                                 = each.value.location
  region_key                               = each.key
  eventhub_namespace_authorization_rule_id = module.real_time[each.key].eventhub_namespace_authorization_rule_id
  eventhub_name                            = module.real_time[each.key].eventhub_name
  policy_identity_id                       = azurerm_user_assigned_identity.policy[0].id

  depends_on = [module.real_time, azurerm_role_assignment.policy_monitoring_contributor, azurerm_role_assignment.policy_eventhub_contributor]
}

################################################################################
# Storage Account File Services Diagnostic Policy (per region)
#
# Uses custom Azure policy to enforce StorageRead, StorageWrite, StorageDelete
# logging on all Storage Account file services, streaming to the regional
# Event Hub.
################################################################################

module "diagnostic_policy_sa_files" {
  source   = "../../modules/diagnostic-policy-sa-files"
  for_each = var.enable_sa_files_data_plane_logging ? var.regions : {}

  subscriptions                            = var.subscriptions
  location                                 = each.value.location
  region_key                               = each.key
  eventhub_namespace_authorization_rule_id = module.real_time[each.key].eventhub_namespace_authorization_rule_id
  eventhub_name                            = module.real_time[each.key].eventhub_name
  policy_identity_id                       = azurerm_user_assigned_identity.policy[0].id

  depends_on = [module.real_time, azurerm_role_assignment.policy_monitoring_contributor, azurerm_role_assignment.policy_eventhub_contributor]
}
