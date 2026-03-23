################################################################################
# Key Vault Diagnostic Policy (Custom)
#
# Custom policy to enforce AuditEvent logging on all Key Vaults,
# streaming to a regional Event Hub.
################################################################################

locals {
  subscriptions = {
    for sub in var.subscriptions : sub => "/subscriptions/${sub}"
  }
}

resource "azurerm_policy_definition" "kv_diag_eventhub" {
  name         = "ss-kv-diag-eh-${var.region_key}"
  display_name = "Stream Security - Deploy diagnostic settings for Key Vault to Event Hub (${var.region_key})"
  description  = "Deploys diagnostic settings for Key Vault to stream AuditEvent and AzurePolicyEvaluationDetails logs to a regional Event Hub."
  policy_type  = "Custom"
  mode         = "All"

  metadata = jsonencode({ category = "Key Vault" })

  policy_rule = jsonencode(jsondecode(file("${path.module}/kv_policy.json")).policyRule)
  parameters  = jsonencode(jsondecode(file("${path.module}/kv_policy.json")).parameters)
}

resource "azurerm_subscription_policy_assignment" "kv_diag" {
  for_each = local.subscriptions

  name                 = "ss-kv-diag-${var.region_key}"
  display_name         = "Stream Security - Key Vault diagnostics to Event Hub (${var.region_key})"
  subscription_id      = each.value
  policy_definition_id = azurerm_policy_definition.kv_diag_eventhub.id
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
      value = "${var.diagnostic_setting_name}-kv-${var.region_key}"
    }
  })

  identity {
    type         = "UserAssigned"
    identity_ids = [var.policy_identity_id]
  }
}

resource "azurerm_subscription_policy_remediation" "kv_diag" {
  for_each = local.subscriptions

  name                    = "remediate-kv-diag-${var.region_key}"
  subscription_id         = each.value
  policy_assignment_id    = azurerm_subscription_policy_assignment.kv_diag[each.key].id
  resource_discovery_mode = "ReEvaluateCompliance"
}
