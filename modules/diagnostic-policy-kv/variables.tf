variable "subscriptions" {
  description = "The list of Azure subscription IDs to assign the diagnostic policy to."
  type        = list(string)
}

variable "location" {
  description = "The Azure region for the policy assignment's managed identity."
  type        = string
}

variable "eventhub_namespace_authorization_rule_id" {
  description = "The Event Hub namespace authorization rule ID for diagnostic settings."
  type        = string
}

variable "eventhub_name" {
  description = "The name of the Event Hub to send diagnostic logs to."
  type        = string
}

variable "policy_identity_id" {
  description = "The ID of the User Assigned Managed Identity for the policy assignment."
  type        = string
}

variable "region_key" {
  description = "Short region identifier used to make policy assignment names unique per region."
  type        = string
}

variable "diagnostic_setting_name" {
  description = "The name prefix for diagnostic settings created by the policy."
  type        = string
  default     = "streamsec-diag"
}
