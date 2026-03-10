################################################################################
# Key Vault Diagnostic Policy
#
# Uses built-in Azure policy to enforce AuditEvent logging on all Key Vaults,
# streaming to a regional Event Hub.
################################################################################

data "azurerm_policy_definition" "kv_diag_eventhub" {
  display_name = "Deploy Diagnostic Settings for Key Vault to Event Hub"
}

locals {
  subscriptions = {
    for sub in var.subscriptions : sub => "/subscriptions/${sub}"
  }
}

resource "azurerm_subscription_policy_assignment" "kv_diag" {
  for_each = local.subscriptions

  name                 = "ss-kv-diag-${var.region_key}"
  display_name         = "Stream Security - Key Vault diagnostics to Event Hub (${var.region_key})"
  subscription_id      = each.value
  policy_definition_id = data.azurerm_policy_definition.kv_diag_eventhub.id
  location             = var.location

  parameters = jsonencode({
    eventHubRuleId = {
      value = var.eventhub_namespace_authorization_rule_id
    }
    profileName = {
      value = "${var.diagnostic_setting_name}-kv-${var.region_key}"
    }
  })

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "kv_eventhub_sender" {
  for_each = local.subscriptions

  scope                = var.eventhub_namespace_id
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = azurerm_subscription_policy_assignment.kv_diag[each.key].identity[0].principal_id
}

resource "azurerm_role_assignment" "kv_monitoring_contributor" {
  for_each = local.subscriptions

  scope                = each.value
  role_definition_name = "Monitoring Contributor"
  principal_id         = azurerm_subscription_policy_assignment.kv_diag[each.key].identity[0].principal_id
}
