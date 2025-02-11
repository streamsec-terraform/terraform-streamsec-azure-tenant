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
  tenant_id    = data.azurerm_client_config.current.tenant_id
}

data "azuread_application" "this" {
  count        = var.create_app_reg ? 0 : 1
  display_name = var.app_reg_display_name
}

resource "azuread_application_registration" "this" {
  count            = var.create_app_reg ? 1 : 0
  display_name     = var.app_reg_display_name
  description      = var.app_reg_description
  sign_in_audience = "AzureADMyOrg"
}

moved {
  from = azuread_application_registration.this
  to   = azuread_application_registration.this[0]
}

resource "azuread_application_api_access" "this" {
  count          = var.create_app_reg ? 1 : 0
  application_id = azuread_application_registration.this[0].id
  api_client_id  = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]

  role_ids = [
    for permission in local.application_permissions : data.azuread_service_principal.msgraph.app_role_ids[permission]
  ]

  scope_ids = [
    for permission in local.delegated_permissions : data.azuread_service_principal.msgraph.oauth2_permission_scope_ids[permission]
  ]
}

moved {
  from = azuread_application_api_access.this
  to   = azuread_application_api_access.this[0]
}

resource "azuread_service_principal" "this" {
  count     = var.create_app_reg ? 1 : 0
  client_id = azuread_application_registration.this[0].client_id
}

moved {
  from = azuread_service_principal.this
  to   = azuread_service_principal.this[0]
}

resource "azuread_app_role_assignment" "this" {
  for_each = {
    for role_id in try(azuread_application_api_access.this[0].role_ids, []) :
    role_id => role_id
  }
  app_role_id         = each.value
  principal_object_id = var.create_app_reg ? azuread_service_principal.this[0].object_id : data.azuread_application.this[0].object_id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}

moved {
  from = azuread_app_role_assignment.this
  to   = azuread_app_role_assignment.this[0]
}

resource "azuread_service_principal_delegated_permission_grant" "this" {
  count                                = var.create_app_reg ? 1 : 0
  service_principal_object_id          = azuread_service_principal.this[0].object_id
  resource_service_principal_object_id = azuread_service_principal.msgraph.object_id
  claim_values                         = [for permission in local.delegated_permissions : permission]
}

moved {
  from = azuread_service_principal_delegated_permission_grant.this
  to   = azuread_service_principal_delegated_permission_grant.this[0]
}

# give reader permissions to the service principal on all subscriptions
resource "azurerm_role_assignment" "this" {
  for_each = {
    for subscription_id in var.subscriptions :
    subscription_id => "/subscriptions/${subscription_id}"
  }
  scope                = each.value
  role_definition_name = "Reader"
  principal_id         = var.create_app_reg ? azuread_service_principal.this[0].object_id : data.azuread_application.this[0].object_id
}

resource "time_rotating" "this" {
  count         = var.create_app_reg ? 1 : 0
  rotation_days = var.rotation_days
}

moved {
  from = time_rotating.this
  to   = time_rotating.this[0]
}

resource "azuread_application_password" "this" {
  count          = var.create_app_reg ? 1 : 0
  application_id = azuread_application_registration.this[0].id
  display_name   = var.app_reg_token_display_name
  rotate_when_changed = {
    rotation = time_rotating.this[0].id
  }
  depends_on = [azurerm_role_assignment.this]
}

moved {
  from = azuread_application_password.this
  to   = azuread_application_password.this[0]
}

resource "streamsec_azure_tenant_ack" "this" {
  tenant_id     = data.azurerm_client_config.current.tenant_id
  client_id     = var.create_app_reg ? azuread_application_registration.this[0].client_id : data.azuread_application.this[0].client_id
  client_secret = var.create_app_reg ? azuread_application_password.this[0].value : var.app_reg_client_secret
  subscriptions = var.subscriptions
  depends_on    = [azuread_application_password.this[0]]
}
