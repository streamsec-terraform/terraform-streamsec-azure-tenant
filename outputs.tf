output "account_id" {
  description = "The Stream Security ID of the Azure tenant, used as `account_id` by modules/volume-scanner."
  value       = streamsec_azure_tenant.this.id

  depends_on = [streamsec_azure_tenant_ack.this]
}
