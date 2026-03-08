################################################################################
# Microsoft Built-in Policy Definitions
################################################################################

data "azurerm_policy_definition" "kv_diag_eventhub" {
  display_name = "Deploy - Configure diagnostic settings for Azure Key Vault to Event Hub"
}

data "azurerm_policy_definition" "sa_blob_diag_eventhub" {
  display_name = "Deploy - Configure Azure Storage account to have diagnostic settings for blob services to Event Hub"
}

locals {
  subscriptions = {
    for sub in var.subscriptions : sub => "/subscriptions/${sub}"
  }
}

################################################################################
# Key Vault Diagnostic Policy
#
# Enforces AuditEvent logging on all Key Vaults, streaming to Event Hub.
################################################################################

resource "azurerm_subscription_policy_assignment" "kv_diag" {
  for_each = local.subscriptions

  name                 = "ss-kv-diag-eh"
  display_name         = "Stream Security - Key Vault diagnostics to Event Hub"
  subscription_id      = each.value
  policy_definition_id = data.azurerm_policy_definition.kv_diag_eventhub.id
  location             = var.location

  parameters = jsonencode({
    eventHubAuthorizationRuleId = {
      value = var.eventhub_namespace_authorization_rule_id
    }
    eventHubName = {
      value = var.eventhub_name
    }
    diagnosticSettingName = {
      value = "${var.diagnostic_setting_name}-kv"
    }
  })

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "kv_eventhub_sender" {
  for_each = local.subscriptions

  scope                = each.value
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = azurerm_subscription_policy_assignment.kv_diag[each.key].identity[0].principal_id
}

resource "azurerm_role_assignment" "kv_monitoring_contributor" {
  for_each = local.subscriptions

  scope                = each.value
  role_definition_name = "Monitoring Contributor"
  principal_id         = azurerm_subscription_policy_assignment.kv_diag[each.key].identity[0].principal_id
}

################################################################################
# Storage Account Blob Diagnostic Policy
#
# Enforces StorageRead, StorageWrite, StorageDelete, Transaction logging on
# all Storage Account blob services, streaming to Event Hub.
################################################################################

resource "azurerm_subscription_policy_assignment" "sa_blob_diag" {
  for_each = local.subscriptions

  name                 = "ss-sa-diag-eh"
  display_name         = "Stream Security - Storage Account blob diagnostics to Event Hub"
  subscription_id      = each.value
  policy_definition_id = data.azurerm_policy_definition.sa_blob_diag_eventhub.id
  location             = var.location

  parameters = jsonencode({
    eventHubAuthorizationRuleId = {
      value = var.eventhub_namespace_authorization_rule_id
    }
    eventHubName = {
      value = var.eventhub_name
    }
    diagnosticSettingName = {
      value = "${var.diagnostic_setting_name}-sa"
    }
  })

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "sa_eventhub_sender" {
  for_each = local.subscriptions

  scope                = each.value
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = azurerm_subscription_policy_assignment.sa_blob_diag[each.key].identity[0].principal_id
}

resource "azurerm_role_assignment" "sa_monitoring_contributor" {
  for_each = local.subscriptions

  scope                = each.value
  role_definition_name = "Monitoring Contributor"
  principal_id         = azurerm_subscription_policy_assignment.sa_blob_diag[each.key].identity[0].principal_id
}
