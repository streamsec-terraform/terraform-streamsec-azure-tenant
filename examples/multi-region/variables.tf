variable "display_name" {
  description = "The display name for this Azure tenant as it will appear in the Stream Security platform."
  type        = string
}

variable "subscriptions" {
  description = "The list of Azure subscription IDs to enable Stream Security for."
  type        = list(string)
}

variable "regions" {
  description = "Map of regions to deploy to. The key is a short identifier (e.g., 'france'), the value contains the Azure region and optionally an existing Event Hub to use instead of creating a new one."
  type = map(object({
    location = string
    existing_eventhub = optional(object({
      eventhub_namespace_name                    = string
      eventhub_namespace_resource_group_name     = string
      eventhub_name                              = string
      eventhub_namespace_authorization_rule_name = string
    }), null)
  }))
}

variable "primary_region" {
  description = "The key from the regions map that should be the primary region. The primary region collects tenant-level (AAD) and subscription-level activity logs in addition to data plane logs."
  type        = string
}

variable "flowlog_storage_accounts" {
  description = "Map of region key to flow log storage account configuration. Only include regions where NSG flow logs are enabled. Keys must match the regions map."
  type = map(object({
    storage_account_name                = string
    storage_account_resource_group_name = string
  }))
  default = {}
}

variable "enable_kv_data_plane_logging" {
  description = "Enable Azure Policy to enforce Key Vault AuditEvent diagnostic settings on all Key Vaults, streaming to the regional Event Hub."
  type        = bool
  default     = false
}

variable "enable_sa_data_plane_logging" {
  description = "Enable Azure Policy to enforce Storage Account blob diagnostic settings (StorageRead, StorageWrite, StorageDelete) on all Storage Accounts, streaming to the regional Event Hub."
  type        = bool
  default     = false
}
