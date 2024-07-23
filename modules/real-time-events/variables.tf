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




variable "tags" {
  description = "The tags to apply to the Stream Security Azure resources."
  type        = map(string)
  default     = {}
}