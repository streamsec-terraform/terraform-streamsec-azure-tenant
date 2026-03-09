################################################################################
# Storage Account Blob Diagnostic Policy (Custom)
#
# No built-in Azure policy exists for SA blob diagnostics to Event Hub.
# This creates a custom policy definition and assigns it.
# Enforces StorageRead, StorageWrite, StorageDelete logging to Event Hub.
################################################################################

locals {
  subscriptions = {
    for sub in var.subscriptions : sub => "/subscriptions/${sub}"
  }
}

resource "azurerm_policy_definition" "sa_blob_diag_eventhub" {
  name         = "ss-sa-blob-diag-eh-${var.region_key}"
  display_name = "Stream Security - Deploy diagnostic settings for Storage Account blob services to Event Hub (${var.region_key})"
  description  = "Deploys diagnostic settings for Storage Account blob services to stream StorageRead, StorageWrite, and StorageDelete logs to a regional Event Hub."
  policy_type  = "Custom"
  mode         = "All"

  metadata = jsonencode({ category = "Storage" })

  policy_rule = jsonencode(jsondecode(file("${path.module}/sa_blob_policy.json")).policyRule)
  parameters  = jsonencode(jsondecode(file("${path.module}/sa_blob_policy.json")).parameters)
}

resource "azurerm_subscription_policy_assignment" "sa_blob_diag" {
  for_each = local.subscriptions

  name                 = "ss-sa-diag-${var.region_key}"
  display_name         = "Stream Security - Storage Account blob diagnostics to Event Hub (${var.region_key})"
  subscription_id      = each.value
  policy_definition_id = azurerm_policy_definition.sa_blob_diag_eventhub.id
  location             = var.location

  parameters = jsonencode({
    eventHubRuleId = {
      value = var.eventhub_namespace_authorization_rule_id
    }
    eventHubLocation = {
      value = var.location
    }
    profileName = {
      value = "${var.diagnostic_setting_name}-sa-${var.region_key}"
    }
  })

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "sa_eventhub_sender" {
  for_each = local.subscriptions

  scope                = var.eventhub_namespace_id
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = azurerm_subscription_policy_assignment.sa_blob_diag[each.key].identity[0].principal_id
}

resource "azurerm_role_assignment" "sa_monitoring_contributor" {
  for_each = local.subscriptions

  scope                = each.value
  role_definition_name = "Monitoring Contributor"
  principal_id         = azurerm_subscription_policy_assignment.sa_blob_diag[each.key].identity[0].principal_id
}
