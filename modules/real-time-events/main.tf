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
  resource_group                        = var.create_resource_group ? azurerm_resource_group.this[0] : data.azurerm_resource_group.this[0]
  eventhub_namespace                    = var.create_eventhub_namespace ? azurerm_eventhub_namespace.this[0] : data.azurerm_eventhub_namespace.this[0]
  eventhub                              = var.create_eventhub ? azurerm_eventhub.this[0] : data.azurerm_eventhub.this[0]
  eventhub_namespace_authorization_rule = var.create_eventhub_namespace ? azurerm_eventhub_namespace_authorization_rule.this[0] : data.azurerm_eventhub_namespace_authorization_rule.this[0]
  eventhub_authorization_rule           = var.create_eventhub ? azurerm_eventhub_authorization_rule.this[0] : data.azurerm_eventhub_authorization_rule.this[0]
}

################################################################################
# Event Hub
################################################################################

data "azurerm_eventhub_namespace" "this" {
  count               = var.create_eventhub_namespace ? 0 : 1
  name                = var.eventhub_namespace_name
  resource_group_name = var.eventhub_namespace_resource_group_name
}
resource "azurerm_eventhub_namespace" "this" {
  count               = var.create_eventhub_namespace ? 1 : 0
  name                = var.eventhub_namespace_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  sku                 = var.eventhub_namespace_sku
  tags                = merge(var.tags, var.eventhub_namespace_tags)
}

moved {
  from = azurerm_eventhub_namespace.this
  to   = azurerm_eventhub_namespace.this[0]
}

data "azurerm_eventhub" "this" {
  count               = var.create_eventhub ? 0 : 1
  name                = var.eventhub_name
  namespace_name      = var.eventhub_namespace_name
  resource_group_name = var.eventhub_namespace_resource_group_name
}

resource "azurerm_eventhub" "this" {
  count             = var.create_eventhub ? 1 : 0
  name              = var.eventhub_name
  namespace_id      = local.eventhub_namespace.id
  partition_count   = var.eventhub_partition_count
  message_retention = var.eventhub_message_retention
}

moved {
  from = azurerm_eventhub.this
  to   = azurerm_eventhub.this[0]
}

resource "azurerm_eventhub_consumer_group" "this" {
  count               = var.eventhub_consumer_group == "$Default" ? 0 : 1
  name                = var.eventhub_consumer_group
  namespace_name      = local.eventhub_namespace.name
  eventhub_name       = local.eventhub.name
  resource_group_name = var.create_eventhub ? local.resource_group.name : data.azurerm_eventhub.this[0].resource_group_name
}

data "azurerm_eventhub_namespace_authorization_rule" "this" {
  count               = var.create_eventhub_namespace ? 0 : 1
  name                = var.eventhub_namespace_authorization_rule_name
  namespace_name      = var.eventhub_namespace_name
  resource_group_name = var.eventhub_namespace_resource_group_name
}

resource "azurerm_eventhub_namespace_authorization_rule" "this" {
  count               = var.create_eventhub_namespace ? 1 : 0
  name                = var.eventhub_namespace_authorization_rule_name
  namespace_name      = local.eventhub_namespace.name
  resource_group_name = local.resource_group.name
  listen              = true
  send                = true
}

moved {
  from = azurerm_eventhub_namespace_authorization_rule.this
  to   = azurerm_eventhub_namespace_authorization_rule.this[0]
}

data "azurerm_eventhub_authorization_rule" "this" {
  count               = var.create_eventhub ? 0 : 1
  name                = var.eventhub_authorization_rule_name
  namespace_name      = var.eventhub_namespace_name
  eventhub_name       = var.eventhub_name
  resource_group_name = var.eventhub_namespace_resource_group_name
}

resource "azurerm_eventhub_authorization_rule" "this" {
  count               = var.create_eventhub ? 1 : 0
  name                = var.eventhub_authorization_rule_name
  namespace_name      = local.eventhub_namespace.name
  resource_group_name = local.resource_group.name
  eventhub_name       = local.eventhub.name
  listen              = true
}

moved {
  from = azurerm_eventhub_authorization_rule.this
  to   = azurerm_eventhub_authorization_rule.this[0]
}

################################################################################
# Application Insights
################################################################################

data "azurerm_application_insights" "this" {
  count               = var.create_application_insights ? 0 : 1
  name                = var.existing_application_insights_name
  resource_group_name = var.existing_application_insights_resource_group_name
}

resource "azurerm_application_insights" "this" {
  count               = var.create_application_insights ? 1 : 0
  name                = var.application_insights_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  application_type    = "web"
  tags                = merge(var.tags, var.application_insights_tags)
}

moved {
  from = azurerm_application_insights.this
  to   = azurerm_application_insights.this[0]
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

data "azurerm_storage_account" "this" {
  count               = var.create_storage_account ? 0 : 1
  name                = var.existing_storage_account_name
  resource_group_name = var.existing_storage_account_resource_group_name
}

resource "azurerm_storage_account" "this" {
  count                           = var.create_storage_account ? 1 : 0
  name                            = "${var.storage_account_name_prefix}${random_string.this.result}"
  location                        = local.resource_group.location
  resource_group_name             = local.resource_group.name
  account_tier                    = var.storage_account_tier
  account_replication_type        = var.storage_account_replication_type
  min_tls_version                 = var.storage_account_min_tls_version
  allow_nested_items_to_be_public = var.storage_account_allow_nested_items_to_be_public
  shared_access_key_enabled       = var.storage_account_shared_access_key_enabled

  blob_properties {
    delete_retention_policy {
      days = var.storage_account_blob_delete_retention_days
    }
  }

  tags = merge(var.tags, var.storage_account_tags)
}

moved {
  from = azurerm_storage_account.this
  to   = azurerm_storage_account.this[0]
}

resource "azurerm_service_plan" "this" {
  name                = var.service_plan_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = merge(var.tags, var.service_plan_tags)
}

resource "azurerm_linux_function_app" "this" {
  name                          = var.function_name
  location                      = local.resource_group.location
  resource_group_name           = local.resource_group.name
  service_plan_id               = azurerm_service_plan.this.id
  storage_account_name          = var.create_storage_account ? azurerm_storage_account.this[0].name : data.azurerm_storage_account.this[0].name
  storage_account_access_key    = var.create_storage_account ? azurerm_storage_account.this[0].primary_access_key : data.azurerm_storage_account.this[0].primary_access_key
  public_network_access_enabled = var.function_public_access_enabled
  https_only                    = var.function_https_only
  client_certificate_mode       = var.function_certificate_mode
  client_certificate_enabled    = var.function_certificate_enabled

  app_settings = {
    API_TOKEN                = data.streamsec_azure_tenant.this.account_token
    API_URL                  = data.streamsec_host.this.host
    EventHubConnectionString = "Endpoint=sb://${local.eventhub_namespace.name}.servicebus.windows.net/;SharedAccessKeyName=${local.eventhub_authorization_rule.name};SharedAccessKey=${local.eventhub_authorization_rule.primary_key};EntityPath=${local.eventhub.name}"
    WEBSITE_RUN_FROM_PACKAGE = "https://${var.function_bucket_name}.s3.amazonaws.com/${var.function_zip_filename}"
    EVENTHUB_CONSUMER_GROUP  = var.eventhub_consumer_group
  }

  site_config {
    http2_enabled = var.function_http2_enabled
    ftps_state    = var.function_ftps_state
    application_stack {
      python_version = "3.10"
    }
    application_insights_key = var.create_application_insights ? azurerm_application_insights.this[0].instrumentation_key : data.azurerm_application_insights.this[0].instrumentation_key
  }

  tags = merge(var.tags, var.function_tags)

  lifecycle {
    ignore_changes = [
      tags["hidden-link: /app-insights-instrumentation-key"],
      tags["hidden-link: /app-insights-resource-id"],
      tags["hidden-link: /app-insights-conn-string"]
    ]
  }
  depends_on = [local.eventhub]
}

################################################################################
# Diagnostic Settings
################################################################################
resource "azurerm_monitor_aad_diagnostic_setting" "this" {
  count                          = var.create_aad_diagnostic_setting ? 1 : 0
  name                           = var.diagnostic_setting_name
  eventhub_name                  = local.eventhub.name
  eventhub_authorization_rule_id = local.eventhub_namespace_authorization_rule.id
  enabled_log {
    category = "AuditLogs"
  }
}

moved {
  from = azurerm_monitor_aad_diagnostic_setting.example
  to   = azurerm_monitor_aad_diagnostic_setting.this[0]
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = {
    for subscription_id in(var.create_subscription_diagnostic_setting ? var.subscriptions : []) :
    subscription_id => "/subscriptions/${subscription_id}"
  }

  name                           = var.diagnostic_setting_name
  target_resource_id             = each.value
  eventhub_name                  = local.eventhub.name
  eventhub_authorization_rule_id = local.eventhub_namespace_authorization_rule.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Autoscale"
  }
}
