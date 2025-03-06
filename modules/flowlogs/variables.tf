################################################################################
# Flow Logs Variables
################################################################################

variable "network_traffic_container_name" {
  description = "The name of the Storage Account container to store the network traffic logs in."
  type        = string
  default     = "insights-logs-flowlogflowevent"
}

################################################################################
# Flow Logs Resource Group Variables
################################################################################

variable "create_resource_group" {
  description = "Whether to create a new resource group for the Stream Security Azure resources. if false, the resources will be created in the resource group specified by the `resource_group_name` variable."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "The name of the resource group to create the Stream Security Azure resources in."
  type        = string
  default     = "rg-stream-flowlogs"
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
# Flow Logs Application Insights Variables
################################################################################

variable "application_insights_name" {
  description = "The name of the Application Insights instance to create."
  type        = string
  default     = "appi-stream-flowlogs"
}

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

variable "application_insights_tags" {
  description = "The tags to apply to the Application Insights instance."
  type        = map(string)
  default     = {}
}

################################################################################
# Flow Logs Storage Account Variables
################################################################################
variable "storage_account_name" {
  description = "The name of the Storage Account where the network traffic logs will be stored."
  type        = string
}

variable "storage_account_resource_group_name" {
  description = "The name of the resource group where the Storage Account is located."
  type        = string
}

################################################################################
# Flow Logs Service Plan Variables
################################################################################

variable "service_plan_id" {
  description = "The ID of the Service Plan to use for the Function App. If not provided, a new Service Plan will be created."
  type        = string
  default     = null
}

variable "service_plan_name" {
  description = "The name of the Service Plan to create."
  type        = string
  default     = "asp-stream-flowlogs"
}

variable "service_plan_tags" {
  description = "The tags to apply to the Service Plan."
  type        = map(string)
  default     = {}
}

################################################################################
# Flow Logs Function Variables
################################################################################

variable "function_name" {
  description = "The name of the Function App to create."
  type        = string
  default     = "funcapp-stream-flowlogs"
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

variable "function_virtual_network_subnet_id" {
  description = "The ID of the subnet to connect the Function App to."
  type        = string
  default     = null
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
# Flow Logs General Variables
################################################################################

variable "tags" {
  description = "The tags to apply to the Stream Security Azure resources."
  type        = map(string)
  default     = {}
}
