data "azurerm_client_config" "current" {}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]
}

resource "azuread_service_principal" "msgraph" {
  client_id    = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing = true
}

locals {
  application_permissions = [
    "Directory.Read.All",
    "UserAuthenticationMethod.Read.All",
  ]
  delegated_permissions = [
    "Subscription.Read.All",
    "User.Read",
    "UserAuthenticationMethod.Read",
    "Application.Read.All",
    "Directory.Read.All",
    "Group.Read.All",
    "RoleManagement.Read.All",
    "RoleManagementPolicy.Read.Directory",
    "User.Read.All",
    "UserAuthenticationMethod.Read.All",
  ]
}

resource "streamsec_azure_tenant" "this" {
  display_name = var.display_name
}

resource "azuread_application_registration" "this" {
  display_name     = var.app_reg_display_name
  description      = var.app_reg_description
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_application_api_access" "this" {
  application_id = azuread_application_registration.this.id
  api_client_id  = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]

  role_ids = [
    for permission in local.application_permissions : data.azuread_service_principal.msgraph.app_role_ids[permission]
  ]

  scope_ids = [
    for permission in local.delegated_permissions : data.azuread_service_principal.msgraph.oauth2_permission_scope_ids[permission]
  ]
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application_registration.this.client_id
}

resource "azuread_app_role_assignment" "this" {
  for_each = {
    for role_id in azuread_application_api_access.this.role_ids :
    role_id => role_id
  }
  app_role_id         = each.value
  principal_object_id = azuread_service_principal.this.object_id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}

resource "azuread_service_principal_delegated_permission_grant" "this" {
  service_principal_object_id          = azuread_service_principal.this.object_id
  resource_service_principal_object_id = azuread_service_principal.msgraph.object_id
  claim_values                         = [for permission in local.delegated_permissions : permission]
}

# give reader permissions to the service principal on all subscriptions
resource "azurerm_role_assignment" "this" {
  for_each = {
    for subscription_id in var.subscriptions :
    subscription_id => "/subscriptions/${subscription_id}"
  }
  scope                = each.value
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.this.object_id
}

resource "time_rotating" "this" {
  rotation_days = var.rotation_days
}

resource "azuread_application_password" "this" {
  application_id = azuread_application_registration.this.id
  display_name   = var.app_reg_token_display_name
  rotate_when_changed = {
    rotation = time_rotating.this.id
  }
  depends_on = [azurerm_role_assignment.this]
}


resource "streamsec_azure_tenant_ack" "this" {
  id            = streamsec_azure_tenant.this.id
  client_id     = azuread_application_registration.this.client_id
  client_secret = azuread_application_password.this.value
  tenant_id     = data.azurerm_client_config.current.tenant_id
  subscriptions = var.subscriptions
  depends_on    = [azurerm_role_assignment.this]
}
