################################################################################
# Real Time Events Outputs
################################################################################

output "resource_group_name" {
  description = "The name of the resource group."
  value       = local.resource_group.name
}

output "resource_group_location" {
  description = "The location of the resource group."
  value       = local.resource_group.location
}

output "eventhub_namespace_name" {
  description = "The name of the Event Hub namespace."
  value       = local.eventhub_namespace.name
}

output "eventhub_namespace_id" {
  description = "The ID of the Event Hub namespace."
  value       = local.eventhub_namespace.id
}

output "eventhub_name" {
  description = "The name of the Event Hub."
  value       = local.eventhub.name
}

output "eventhub_namespace_authorization_rule_id" {
  description = "The ID of the Event Hub namespace authorization rule."
  value       = local.eventhub_namespace_authorization_rule.id
}

output "function_app_name" {
  description = "The name of the Function App."
  value       = azurerm_linux_function_app.this.name
}
