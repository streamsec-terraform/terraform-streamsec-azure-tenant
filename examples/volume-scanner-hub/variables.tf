variable "tenant_id" {
  description = "The Azure tenant ID, connected to Stream Security."
  type        = string
}

variable "workspace_id" {
  description = "The Stream Security workspace ID."
  type        = string
}

variable "hub_subscription_id" {
  description = "The subscription whose scanner also scans the other one."
  type        = string
}

variable "scanned_subscription_id" {
  description = "The subscription the hub scans."
  type        = string
}

variable "location" {
  description = "The location of the hub's scanner resources."
  type        = string
  default     = "eastus"
}
