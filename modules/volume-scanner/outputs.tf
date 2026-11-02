output "resource_group_name" {
  description = "Resource group holding the scanner's resources"
  value       = azurerm_resource_group.this.name
}

output "orchestrator_job_name" {
  description = "Name of the Container Apps job that runs on the schedule and starts the workers"
  value       = azurerm_container_app_job.orchestrator.name
}

output "orchestrator_job_id" {
  description = "Resource id of the orchestrator job, for starting a scan by hand"
  value       = azurerm_container_app_job.orchestrator.id
}

output "worker_job_name" {
  description = "Name of the Container Apps job the orchestrator starts once per shard of VMs and once for the workloads"
  value       = azurerm_container_app_job.worker.name
}

output "managed_identity_principal_id" {
  description = "Principal id of the scanner's user-assigned managed identity, which holds the subscription-scoped roles"
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "managed_identity_client_id" {
  description = "Client id of the scanner's user-assigned managed identity"
  value       = azurerm_user_assigned_identity.this.client_id
}

output "subnet_id" {
  description = "Subnet the scanner runs in: the one this module created, or existing_subnet_id"
  value       = local.subnet_id
}

output "nat_gateway_public_ip" {
  description = "Static egress IP of the scanner's NAT gateway, for allowlisting. Null with network_mode = \"use_existing\", since egress is then through a network this module does not own."
  value       = local.create_network ? azurerm_public_ip.nat[0].ip_address : null
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace receiving the scanner's container logs"
  value       = azurerm_log_analytics_workspace.this.id
}
