output "granted_on" {
  description = "Where the hubs have access: scope is management_group or subscriptions, and ids the management group ID or the subscription IDs."
  value = {
    scope = var.grant_on.management_group_id != null ? "management_group" : "subscriptions"
    ids   = sort(keys(local.scopes))
  }
}

output "role_definition_ids" {
  description = "Resource IDs of the custom role granted to the hubs, one per management group or subscription, keyed by its ID."
  value       = { for key, role in azurerm_role_definition.target : key => role.role_definition_resource_id }
}
