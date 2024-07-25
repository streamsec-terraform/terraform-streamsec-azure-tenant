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
