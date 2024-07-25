# terraform-streamsec-azure-tenant
Terraform module for azure tenant

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >= 2.53.1 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 2.0 |
| <a name="requirement_streamsec"></a> [streamsec](#requirement\_streamsec) | >= 1.7 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.11 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | >= 2.53.1 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 2.0 |
| <a name="provider_streamsec"></a> [streamsec](#provider\_streamsec) | >= 1.7 |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.11 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_app_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment) | resource |
| [azuread_application_api_access.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_api_access) | resource |
| [azuread_application_password.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password) | resource |
| [azuread_application_registration.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_registration) | resource |
| [azuread_service_principal.msgraph](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azuread_service_principal.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azuread_service_principal_delegated_permission_grant.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal_delegated_permission_grant) | resource |
| [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [streamsec_azure_tenant.this](https://registry.terraform.io/providers/streamsec-terraform/streamsec/latest/docs/resources/azure_tenant) | resource |
| [streamsec_azure_tenant_ack.this](https://registry.terraform.io/providers/streamsec-terraform/streamsec/latest/docs/resources/azure_tenant_ack) | resource |
| [time_rotating.this](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/rotating) | resource |
| [azuread_application_published_app_ids.well_known](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/application_published_app_ids) | data source |
| [azuread_service_principal.msgraph](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_reg_description"></a> [app\_reg\_description](#input\_app\_reg\_description) | The description for the Azure AD application registration. | `string` | `"Stream Security Application Registration"` | no |
| <a name="input_app_reg_display_name"></a> [app\_reg\_display\_name](#input\_app\_reg\_display\_name) | The display name for the Azure AD application registration. | `string` | `"Stream Security"` | no |
| <a name="input_app_reg_token_display_name"></a> [app\_reg\_token\_display\_name](#input\_app\_reg\_token\_display\_name) | The display name for the Azure AD application registration password. | `string` | `"Stream Security Token"` | no |
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | The display name for the Azure tenant to be protected by Stream.Security. | `string` | n/a | yes |
| <a name="input_rotation_days"></a> [rotation\_days](#input\_rotation\_days) | The number of days between password rotations. | `number` | `180` | no |
| <a name="input_subscriptions"></a> [subscriptions](#input\_subscriptions) | The list of Azure subscription IDs to be protected by Stream.Security. | `list(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
