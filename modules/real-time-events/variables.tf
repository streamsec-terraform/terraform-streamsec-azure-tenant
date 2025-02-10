################################################################################
# Real Time Events Variables
################################################################################

variable "subscriptions" {
  description = "The list of Azure subscription IDs enable Real Time Events for."
  type        = list(string)

}

################################################################################
# Real Time Events Resource Group Variables
################################################################################

variable "create_resource_group" {
  description = "Whether to create a new resource group for the Stream Security Azure resources. if false, the resources will be created in the resource group specified by the `resource_group_name` variable."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "The name of the resource group to create the Stream Security Azure resources in."
  type        = string
  default     = "rg-streamsec-rte"
}

variable "location" {
  description = "The location to create the Stream Security Azure resources in."
  type        = string
  default     = "East US"
}

variable "resource_group_tags" {
  description = "The tags to apply to the resource group."
  type        = map(string)
  default     = {}
}

################################################################################
# Real Time Events Event Hub Namespace Variables
################################################################################
variable "eventhub_namespace_name" {
  description = "The name of the Event Hub namespace to create."
  type        = string
  default     = "eventhubns-streamsec-rte"
}

variable "eventhub_namespace_sku" {
  description = "The SKU for the Event Hub namespace."
  type        = string
  default     = "Standard"
}

variable "eventhub_namespace_authorization_rule_name" {
  description = "The name of the Event Hub Namespace authorization rule to create."
  type        = string
  default     = "eventhubns-ar-streamsec-rte"
}

variable "eventhub_namespace_tags" {
  description = "The tags to apply to the Event Hub namespace."
  type        = map(string)
  default     = {}
}

################################################################################
# Real Time Events Event Hub Variables
################################################################################

variable "eventhub_name" {
  description = "The name of the Event Hub to create."
  type        = string
  default     = "eventhub-streamsec-rte"
}

variable "eventhub_partition_count" {
  description = "The number of partitions for the Event Hub."
  type        = number
  default     = 4
}

variable "eventhub_message_retention" {
  description = "The number of days to retain messages in the Event Hub."
  type        = number
  default     = 1
}

variable "eventhub_authorization_rule_name" {
  description = "The name of the Event Hub authorization rule to create."
  type        = string
  default     = "eventhub-ar-streamsec-rte"
}

################################################################################
# Real Time Events Application Insights Variables
################################################################################

variable "create_application_insights" {
  description = "Whether to create a new Application Insights instance for the Stream Security Azure resources."
  type        = bool
  default     = true
}

variable "existing_application_insights_name" {
  description = "The name of the existing Application Insights instance to use in case `create_application_insights` is set to false."
  type        = string
  default     = null
}

variable "existing_application_insights_resource_group_name" {
  description = "The name of the resource group to create/import the Application Insights instance"
  type        = string
  default     = null
}

variable "application_insights_name" {
  description = "The name of the Application Insights instance to create."
  type        = string
  default     = "appi-streamsec-rte"
}

variable "application_insights_tags" {
  description = "The tags to apply to the Application Insights instance."
  type        = map(string)
  default     = {}
}

################################################################################
# Real Time Events Storage Account Variables
################################################################################

variable "create_storage_account" {
  description = "Whether to create a new Storage Account for the Stream Security Azure resources. if false, the resources will be created in the Storage Account specified by the `existing_storage_account_name` variable."
  type        = bool
  default     = true
}

variable "existing_storage_account_name" {
  description = "The name of the Storage Account to use in case `create_storage_account` is set to false."
  type        = string
  default     = null
}

variable "existing_storage_account_resource_group_name" {
  description = "The name of the resource group the existing Storage Account is in in case `create_storage_account` is set to false."
  type        = string
  default     = null
}

variable "storage_account_name_prefix" {
  description = "The name of the Storage Account to prefix"
  type        = string
  default     = "storstreamsecrte"
  validation {
    condition     = can(regex("^[a-z0-9]*$", var.storage_account_name_prefix))
    error_message = "Only lowercase letters and numbers are allowed."
  }
}

variable "storage_account_min_tls_version" {
  description = "The minimum TLS version for the Storage Account."
  type        = string
  default     = "TLS1_2"
}

variable "storage_account_tier" {
  description = "The tier for the Storage Account."
  type        = string
  default     = "Standard"
}

variable "storage_account_blob_delete_retention_days" {
  description = "The number of days to retain deleted blobs in the Storage Account."
  type        = number
  default     = 7
}

variable "storage_account_allow_nested_items_to_be_public" {
  description = "Whether to allow nested items to be public in the Storage Account."
  type        = bool
  default     = false
}

variable "storage_account_shared_access_key_enabled" {
  description = "Whether to enable shared access keys for the Storage Account."
  type        = bool
  default     = false
}

variable "storage_account_replication_type" {
  description = "The replication type for the Storage Account."
  type        = string
  default     = "LRS"
}

variable "storage_account_tags" {
  description = "The tags to apply to the Storage Account."
  type        = map(string)
  default     = {}
}

################################################################################
# Real Time Events Service Plan Variables
################################################################################

variable "service_plan_name" {
  description = "The name of the Service Plan to create."
  type        = string
  default     = "asp-streamsec-rte"
}

variable "service_plan_tags" {
  description = "The tags to apply to the Service Plan."
  type        = map(string)
  default     = {}
}

################################################################################
# Real Time Events Function Variables
################################################################################

variable "function_name" {
  description = "The name of the Function App to create."
  type        = string
  default     = "funcapp-streamsec-rte"
}

variable "function_bucket_name" {
  description = "The name of the bucket to store the Function App code."
  type        = string
  default     = "prod-lightlytics-azure-functions"
}

variable "function_zip_filename" {
  description = "The name of the zip file to store the Function App code."
  type        = string
  default     = "LightlyticsEventhubtrigger.zip"
}

variable "function_ftps_state" {
  description = "The FTPS state for the Function App."
  type        = string
  default     = "FtpsOnly"
}

variable "function_http2_enabled" {
  description = "Whether to enable HTTP2 for the Function App."
  type        = bool
  default     = true
}

variable "function_public_access_enabled" {
  description = "Whether to enable public access to the Function App."
  type        = bool
  default     = false
}
variable "function_https_only" {
  description = "Whether to only allow HTTPS access to the Function App."
  type        = bool
  default     = true
}

variable "function_certificate_mode" {
  description = "The certificate mode for the Function App."
  type        = string
  default     = "Required"
}

variable "function_certificate_enabled" {
  description = "Whether to enable the Function App certificate."
  type        = bool
  default     = true
}

variable "function_tags" {
  description = "The tags to apply to the Function App."
  type        = map(string)
  default     = {}
}

################################################################################
# Real Time Events Diagnostic Settings Variables
################################################################################

variable "diagnostic_setting_name" {
  description = "The name of the Diagnostic Setting to create."
  type        = string
  default     = "ds-streamsec-rte"
}

################################################################################
# Real Time Events General Variables
################################################################################

variable "tags" {
  description = "The tags to apply to the Stream Security Azure resources."
  type        = map(string)
  default     = {}
}
