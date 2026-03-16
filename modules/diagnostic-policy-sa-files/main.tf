################################################################################
# Storage Account File Services Diagnostic Policy (Custom)
#
# No built-in Azure policy exists for SA file diagnostics to Event Hub.
# This creates a custom policy definition and assigns it.
# Enforces StorageRead, StorageWrite, StorageDelete logging to Event Hub.
################################################################################

locals {
  subscriptions = {
    for sub in var.subscriptions : sub => "/subscriptions/${sub}"
  }
}

resource "azurerm_policy_definition" "sa_file_diag_eventhub" {
  name         = "ss-sa-file-diag-eh-${var.region_key}"
  display_name = "Stream Security - Deploy diagnostic settings for Storage Account file services to Event Hub (${var.region_key})"
  description  = "Deploys diagnostic settings for Storage Account file services to stream StorageRead, StorageWrite, and StorageDelete logs to a regional Event Hub."
  policy_type  = "Custom"
  mode         = "All"

  metadata = jsonencode({ category = "Storage" })

  policy_rule = jsonencode(jsondecode(file("${path.module}/sa_file_policy.json")).policyRule)
  parameters  = jsonencode(jsondecode(file("${path.module}/sa_file_policy.json")).parameters)
}

resource "azurerm_subscription_policy_assignment" "sa_file_diag" {
  for_each = local.subscriptions

  name                 = "ss-sa-file-${var.region_key}"
  display_name         = "Stream Security - Storage Account file diagnostics to Event Hub (${var.region_key})"
  subscription_id      = each.value
  policy_definition_id = azurerm_policy_definition.sa_file_diag_eventhub.id
  location             = var.location

  parameters = jsonencode({
    eventHubRuleId = {
      value = var.eventhub_namespace_authorization_rule_id
    }
    eventHubName = {
      value = var.eventhub_name
    }
    eventHubLocation = {
      value = var.location
    }
    profileName = {
      value = "${var.diagnostic_setting_name}-sa-files-${var.region_key}"
    }
  })

  identity {
    type         = "UserAssigned"
    identity_ids = [var.policy_identity_id]
  }
}

resource "azurerm_subscription_policy_remediation" "sa_file_diag" {
  for_each = local.subscriptions

  name                    = "remediate-sa-file-${var.region_key}"
  subscription_id         = each.value
  policy_assignment_id    = azurerm_subscription_policy_assignment.sa_file_diag[each.key].id
  resource_discovery_mode = "ReEvaluateCompliance"
}
