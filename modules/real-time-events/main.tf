data "azurerm_client_config" "current" {}

data "streamsec_azure_tenant" "this" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}

data "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 0 : 1
  name = var.resource_group_name
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name
  location = var.location
}

locals {
    resource_group = var.create_resource_group ? azurerm_resource_group.this[0] : data.azurerm_resource_group.this[0]
}

resource "azurerm_eventhub_namespace" "this" {
  name                = var.eventhub_namespace_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  sku                 = var.eventhub_namespace_sku
  tags                = merge(var.tags, var.eventhub_namespace_tags)
}

resource "azurerm_application_insights" "this" {
  name                = var.application_insights_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  application_type    = "web"
  tags                = merge(var.tags, var.application_insights_tags)
}