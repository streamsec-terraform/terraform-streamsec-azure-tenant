output "account_id" {
  description = "Stream Security id of the Azure tenant, not the Azure tenant id: the account_id of modules/volume-scanner"
  value       = streamsec_azure_tenant.this.id

  # Stream Security serves the tenant's scanner settings only once it is acknowledged.
  depends_on = [streamsec_azure_tenant_ack.this]
}
