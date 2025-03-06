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

data "azurerm_storage_account" "this" {
  name                = var.storage_account_name
  resource_group_name = var.storage_account_resource_group_name
}

resource "azurerm_service_plan" "this" {
  count               = var.service_plan_id ? 1 : 0
  name                = var.service_plan_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = merge(var.tags, var.service_plan_tags)
}

moved {
  from = azurerm_service_plan.this
  to   = azurerm_service_plan.this[0]
}

resource "azurerm_linux_function_app" "this" {
  name                          = var.function_name
  location                      = local.resource_group.location
  resource_group_name           = local.resource_group.name
  service_plan_id               = var.service_plan_id ? var.service_plan_id : azurerm_service_plan.this[0].id
  storage_account_name          = data.azurerm_storage_account.this.name
  storage_account_access_key    = data.azurerm_storage_account.this.primary_access_key
  public_network_access_enabled = var.function_public_access_enabled
  https_only                    = var.function_https_only
  client_certificate_mode       = var.function_certificate_mode
  client_certificate_enabled    = var.function_certificate_enabled
  virtual_network_subnet_id     = var.function_virtual_network_subnet_id
  app_settings = {
    API_TOKEN                 = data.streamsec_azure_tenant.this.account_token
    API_URL                   = data.streamsec_host.this.url
    WEBSITE_RUN_FROM_PACKAGE  = "https://github.com/lightlytics/azure-log-collectors/releases/download/1.0.0/azure-log-collectors.zip"
    NETWORK_TRAFFIC_CONTAINER = var.network_traffic_container_name
  }

  site_config {
    http2_enabled = var.function_http2_enabled
    ftps_state    = var.function_ftps_state
    application_stack {
      node_version = "20"
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
}
