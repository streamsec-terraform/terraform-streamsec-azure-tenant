<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 2.0 |
| <a name="requirement_streamsec"></a> [streamsec](#requirement\_streamsec) | >= 1.8 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 2.0 |
| <a name="provider_streamsec"></a> [streamsec](#provider\_streamsec) | >= 1.8 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_application_insights.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_linux_function_app.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_service_plan.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_application_insights.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/application_insights) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account) | data source |
| [streamsec_azure_tenant.this](https://registry.terraform.io/providers/streamsec-terraform/streamsec/latest/docs/data-sources/azure_tenant) | data source |
| [streamsec_host.this](https://registry.terraform.io/providers/streamsec-terraform/streamsec/latest/docs/data-sources/host) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_insights_name"></a> [application\_insights\_name](#input\_application\_insights\_name) | The name of the Application Insights instance to create. | `string` | `"appi-stream-flowlogs"` | no |
| <a name="input_application_insights_tags"></a> [application\_insights\_tags](#input\_application\_insights\_tags) | The tags to apply to the Application Insights instance. | `map(string)` | `{}` | no |
| <a name="input_create_application_insights"></a> [create\_application\_insights](#input\_create\_application\_insights) | Whether to create a new Application Insights instance for the Stream Security Azure resources. | `bool` | `true` | no |
| <a name="input_create_resource_group"></a> [create\_resource\_group](#input\_create\_resource\_group) | Whether to create a new resource group for the Stream Security Azure resources. if false, the resources will be created in the resource group specified by the `resource_group_name` variable. | `bool` | `true` | no |
| <a name="input_existing_application_insights_name"></a> [existing\_application\_insights\_name](#input\_existing\_application\_insights\_name) | The name of the existing Application Insights instance to use in case `create_application_insights` is set to false. | `string` | `null` | no |
| <a name="input_existing_application_insights_resource_group_name"></a> [existing\_application\_insights\_resource\_group\_name](#input\_existing\_application\_insights\_resource\_group\_name) | The name of the resource group to create/import the Application Insights instance | `string` | `null` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | The name of the Function App to create. | `string` | `"funcapp-stream-flowlogs"` | no |
| <a name="input_function_tags"></a> [function\_tags](#input\_function\_tags) | The tags to apply to the Function App. | `map(string)` | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | The location to create the Stream Security Azure resources in. | `string` | `"East US"` | no |
| <a name="input_network_traffic_container_name"></a> [network\_traffic\_container\_name](#input\_network\_traffic\_container\_name) | The name of the Storage Account container to store the network traffic logs in. | `string` | `"insights-logs-flowlogflowevent"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group to create the Stream Security Azure resources in. | `string` | `"rg-stream-flowlogs"` | no |
| <a name="input_resource_group_tags"></a> [resource\_group\_tags](#input\_resource\_group\_tags) | The tags to apply to the resource group. | `map(string)` | `{}` | no |
| <a name="input_service_plan_name"></a> [service\_plan\_name](#input\_service\_plan\_name) | The name of the Service Plan to create. | `string` | `"asp-stream-flowlogs"` | no |
| <a name="input_service_plan_tags"></a> [service\_plan\_tags](#input\_service\_plan\_tags) | The tags to apply to the Service Plan. | `map(string)` | `{}` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | The name of the Storage Account where the network traffic logs will be stored. | `string` | n/a | yes |
| <a name="input_storage_account_resource_group_name"></a> [storage\_account\_resource\_group\_name](#input\_storage\_account\_resource\_group\_name) | The name of the resource group where the Storage Account is located. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to apply to the Stream Security Azure resources. | `map(string)` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
