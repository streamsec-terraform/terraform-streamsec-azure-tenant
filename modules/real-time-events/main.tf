data "azurerm_client_config" "current" {}
data "streamsec_host" "this" {}
data "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

data "streamsec_azure_tenant" "this" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name
  location = var.location

  tags = merge(var.tags, var.resource_group_tags)
}

locals {
  resource_group = var.create_resource_group ? azurerm_resource_group.this[0] : data.azurerm_resource_group.this[0]
}

################################################################################
# Event Hub
################################################################################
resource "azurerm_eventhub_namespace" "this" {
  name                = var.eventhub_namespace_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  sku                 = var.eventhub_namespace_sku
  tags                = merge(var.tags, var.eventhub_namespace_tags)
}

resource "azurerm_eventhub" "this" {
  name                = var.eventhub_name
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = local.resource_group.name
  partition_count     = var.eventhub_partition_count
  message_retention   = var.eventhub_message_retention
}
resource "azurerm_eventhub_namespace_authorization_rule" "this" {
  name                = var.eventhub_namespace_authorization_rule_name
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = local.resource_group.name
  listen              = true
  send                = true
}

resource "azurerm_eventhub_authorization_rule" "this" {
  name                = var.eventhub_authorization_rule_name
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = local.resource_group.name
  eventhub_name       = azurerm_eventhub.this.name
  listen              = true
}

################################################################################
# Application Insights
################################################################################
resource "azurerm_application_insights" "this" {
  name                = var.application_insights_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  application_type    = "web"
  tags                = merge(var.tags, var.application_insights_tags)
}

################################################################################
# Function App
################################################################################

resource "random_string" "this" {
  length  = 6
  special = false
  lower   = true
  numeric = true
  upper   = false
}

resource "azurerm_storage_account" "this" {
  name                     = "${var.storage_account_name_prefix}${random_string.this.result}"
  location                 = local.resource_group.location
  resource_group_name      = local.resource_group.name
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  tags                     = merge(var.tags, var.storage_account_tags)
}

resource "azurerm_service_plan" "this" {
  name                = var.service_plan_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = merge(var.tags, var.service_plan_tags)
}

resource "azurerm_linux_function_app" "this" {
  name                       = var.function_name
  location                   = local.resource_group.location
  resource_group_name        = local.resource_group.name
  service_plan_id            = azurerm_service_plan.this.id
  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key
  app_settings = {
    API_TOKEN                      = data.streamsec_azure_tenant.this.account_token
    API_URL                        = data.streamsec_host.this.host
    EventHubConnectionString       = "Endpoint=sb://${azurerm_eventhub_namespace.this.name}.servicebus.windows.net/;SharedAccessKeyName=${azurerm_eventhub_namespace_authorization_rule.this.name};SharedAccessKey=${azurerm_eventhub_namespace_authorization_rule.this.primary_key}"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.this.instrumentation_key
    WEBSITE_RUN_FROM_PACKAGE       = "https://${var.function_bucket_name}.s3.amazonaws.com/${var.function_zip_filename}"
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
    ENABLE_ORYX_BUILD              = "true"
  }

  site_config {
    application_stack {
      python_version = "3.10"
    }
  }

  tags = merge(var.tags, var.function_tags)
}

################################################################################
# Diagnostic Settings
################################################################################
resource "azurerm_monitor_aad_diagnostic_setting" "example" {
  name                           = var.diagnostic_setting_name
  eventhub_name                  = azurerm_eventhub.this.name
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.this.id
  enabled_log {
    category = "AuditLogs"
    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = {
    for subscription_id in var.subscriptions :
    subscription_id => "/subscriptions/${subscription_id}"
  }

  name                           = var.diagnostic_setting_name
  target_resource_id             = each.value
  eventhub_name                  = azurerm_eventhub.this.name
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.this.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Autoscale"
  }
}
