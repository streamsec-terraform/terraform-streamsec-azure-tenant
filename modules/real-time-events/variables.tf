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
  default     = "stream-security"
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
  default     = "stream-security"
}

variable "eventhub_namespace_sku" {
  description = "The SKU for the Event Hub namespace."
  type        = string
  default     = "Standard"
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
  default     = "stream-security"
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

################################################################################
# Real Time Events Event Hub Authorization Rule Variables
################################################################################

variable "eventhub_authorization_rule_name" {
  description = "The name of the Event Hub authorization rule to create."
  type        = string
  default     = "stream-security"
}

################################################################################
# Real Time Events Application Insights Variables
################################################################################

variable "application_insights_name" {
  description = "The name of the Application Insights instance to create."
  type        = string
  default     = "stream-security"
}

variable "application_insights_tags" {
  description = "The tags to apply to the Application Insights instance."
  type        = map(string)
  default     = {}
}

################################################################################
# Real Time Events Storage Account Variables
################################################################################

variable "storage_account_name_prefix" {
  description = "The name of the Storage Account to prefix"
  type        = string
  default     = "streamsecurity"
  validation {
    condition     = can(regex("^[a-z0-9]*$", var.storage_account_name_prefix))
    error_message = "Only lowercase letters and numbers are allowed."
  }
}

variable "storage_account_tier" {
  description = "The tier for the Storage Account."
  type        = string
  default     = "Standard"
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
  default     = "stream-security"
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
  default     = "stream-security"
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
  default     = "stream-security"
}

################################################################################
# Real Time Events General Variables
################################################################################

variable "tags" {
  description = "The tags to apply to the Stream Security Azure resources."
  type        = map(string)
  default     = {}
}
