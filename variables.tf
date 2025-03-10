################################################################################
# Stream Security Azure Tenant Variables
################################################################################

variable "display_name" {
  description = "The display name for the Azure tenant to be protected by Stream.Security."
  type        = string
}

variable "subscriptions" {
  description = "The list of Azure subscription IDs to be protected by Stream.Security."
  type        = list(string)
}

################################################################################
# Stream Security Application Registration Variables
################################################################################

variable "create_app_reg" {
  description = "Whether to create a new Azure AD application registration for Stream.Security."
  type        = bool
  default     = true
}

variable "app_reg_client_secret" {
  description = "The client secret for the Azure AD application registration. only required if `create_app_reg` is false."
  type        = string
  default     = null
}

variable "app_reg_display_name" {
  description = "The display name for the Azure AD application registration."
  type        = string
  default     = "Stream Security"
}

variable "app_reg_description" {
  description = "The description for the Azure AD application registration."
  type        = string
  default     = "Stream Security Application Registration"
}

variable "rotation_days" {
  description = "The number of days between password rotations."
  type        = number
  default     = 180
}

variable "app_reg_token_display_name" {
  description = "The display name for the Azure AD application registration password."
  type        = string
  default     = "Stream Security Token"
}

# variable "auto_grant_admin_consent" {
#   description = "Whether to automatically grant admin consent to the application permissions."
#   type        = bool
#   default     = true
# }
