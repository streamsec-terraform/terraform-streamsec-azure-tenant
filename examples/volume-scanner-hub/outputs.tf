output "hub_principal_id" {
  description = "Principal ID of the hub scanner's managed identity."
  value       = module.hub_scanner.managed_identity_principal_id
}

output "granted_on" {
  description = "Where the hub has access."
  value       = module.hub_access.granted_on
}
