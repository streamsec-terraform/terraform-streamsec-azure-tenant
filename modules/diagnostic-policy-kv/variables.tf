variable "subscriptions" {
  description = "The list of Azure subscription IDs to assign the diagnostic policy to."
  type        = list(string)
}

variable "location" {
  description = "The Azure region for the policy assignment's managed identity."
  type        = string
}

variable "eventhub_namespace_id" {
  description = "The Event Hub namespace ID. Used to scope EventHub Data Sender role for cross-subscription scenarios."
  type        = string
}

variable "eventhub_namespace_authorization_rule_id" {
  description = "The Event Hub namespace authorization rule ID for diagnostic settings."
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
