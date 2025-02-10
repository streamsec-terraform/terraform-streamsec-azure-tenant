<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1 |
| <a name="requirement_streamsec"></a> [streamsec](#requirement\_streamsec) | >= 1.8 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.1 |
| <a name="provider_streamsec"></a> [streamsec](#provider\_streamsec) | >= 1.8 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_application_insights.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_eventhub.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) | resource |
| [azurerm_eventhub_authorization_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_authorization_rule) | resource |
| [azurerm_eventhub_namespace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) | resource |
| [azurerm_eventhub_namespace_authorization_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace_authorization_rule) | resource |
| [azurerm_linux_function_app.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_monitor_aad_diagnostic_setting.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_aad_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_service_plan.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [random_string.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [azurerm_application_insights.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/application_insights) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account) | data source |
| [streamsec_azure_tenant.this](https://registry.terraform.io/providers/streamsec-terraform/streamsec/latest/docs/data-sources/azure_tenant) | data source |
| [streamsec_host.this](https://registry.terraform.io/providers/streamsec-terraform/streamsec/latest/docs/data-sources/host) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_insights_name"></a> [application\_insights\_name](#input\_application\_insights\_name) | The name of the Application Insights instance to create. | `string` | `"appi-streamsec-rte"` | no |
| <a name="input_application_insights_tags"></a> [application\_insights\_tags](#input\_application\_insights\_tags) | The tags to apply to the Application Insights instance. | `map(string)` | `{}` | no |
| <a name="input_create_application_insights"></a> [create\_application\_insights](#input\_create\_application\_insights) | Whether to create a new Application Insights instance for the Stream Security Azure resources. | `bool` | `true` | no |
| <a name="input_create_resource_group"></a> [create\_resource\_group](#input\_create\_resource\_group) | Whether to create a new resource group for the Stream Security Azure resources. if false, the resources will be created in the resource group specified by the `resource_group_name` variable. | `bool` | `true` | no |
| <a name="input_create_storage_account"></a> [create\_storage\_account](#input\_create\_storage\_account) | Whether to create a new Storage Account for the Stream Security Azure resources. if false, the resources will be created in the Storage Account specified by the `existing_storage_account_name` variable. | `bool` | `true` | no |
| <a name="input_diagnostic_setting_name"></a> [diagnostic\_setting\_name](#input\_diagnostic\_setting\_name) | The name of the Diagnostic Setting to create. | `string` | `"ds-streamsec-rte"` | no |
| <a name="input_eventhub_authorization_rule_name"></a> [eventhub\_authorization\_rule\_name](#input\_eventhub\_authorization\_rule\_name) | The name of the Event Hub authorization rule to create. | `string` | `"eventhub-ar-streamsec-rte"` | no |
| <a name="input_eventhub_message_retention"></a> [eventhub\_message\_retention](#input\_eventhub\_message\_retention) | The number of days to retain messages in the Event Hub. | `number` | `1` | no |
| <a name="input_eventhub_name"></a> [eventhub\_name](#input\_eventhub\_name) | The name of the Event Hub to create. | `string` | `"eventhub-streamsec-rte"` | no |
| <a name="input_eventhub_namespace_authorization_rule_name"></a> [eventhub\_namespace\_authorization\_rule\_name](#input\_eventhub\_namespace\_authorization\_rule\_name) | The name of the Event Hub Namespace authorization rule to create. | `string` | `"eventhubns-ar-streamsec-rte"` | no |
| <a name="input_eventhub_namespace_name"></a> [eventhub\_namespace\_name](#input\_eventhub\_namespace\_name) | The name of the Event Hub namespace to create. | `string` | `"eventhubns-streamsec-rte"` | no |
| <a name="input_eventhub_namespace_sku"></a> [eventhub\_namespace\_sku](#input\_eventhub\_namespace\_sku) | The SKU for the Event Hub namespace. | `string` | `"Standard"` | no |
| <a name="input_eventhub_namespace_tags"></a> [eventhub\_namespace\_tags](#input\_eventhub\_namespace\_tags) | The tags to apply to the Event Hub namespace. | `map(string)` | `{}` | no |
| <a name="input_eventhub_partition_count"></a> [eventhub\_partition\_count](#input\_eventhub\_partition\_count) | The number of partitions for the Event Hub. | `number` | `4` | no |
| <a name="input_existing_application_insights_name"></a> [existing\_application\_insights\_name](#input\_existing\_application\_insights\_name) | The name of the existing Application Insights instance to use in case `create_application_insights` is set to false. | `string` | `null` | no |
| <a name="input_existing_application_insights_resource_group_name"></a> [existing\_application\_insights\_resource\_group\_name](#input\_existing\_application\_insights\_resource\_group\_name) | The name of the resource group to create/import the Application Insights instance | `string` | `null` | no |
| <a name="input_existing_storage_account_name"></a> [existing\_storage\_account\_name](#input\_existing\_storage\_account\_name) | The name of the Storage Account to use in case `create_storage_account` is set to false. | `string` | `null` | no |
| <a name="input_existing_storage_account_resource_group_name"></a> [existing\_storage\_account\_resource\_group\_name](#input\_existing\_storage\_account\_resource\_group\_name) | The name of the resource group the existing Storage Account is in in case `create_storage_account` is set to false. | `string` | `null` | no |
| <a name="input_function_bucket_name"></a> [function\_bucket\_name](#input\_function\_bucket\_name) | The name of the bucket to store the Function App code. | `string` | `"prod-lightlytics-azure-functions"` | no |
| <a name="input_function_certificate_enabled"></a> [function\_certificate\_enabled](#input\_function\_certificate\_enabled) | Whether to enable the Function App certificate. | `bool` | `true` | no |
| <a name="input_function_certificate_mode"></a> [function\_certificate\_mode](#input\_function\_certificate\_mode) | The certificate mode for the Function App. | `string` | `"Required"` | no |
| <a name="input_function_ftps_state"></a> [function\_ftps\_state](#input\_function\_ftps\_state) | The FTPS state for the Function App. | `string` | `"FtpsOnly"` | no |
| <a name="input_function_http2_enabled"></a> [function\_http2\_enabled](#input\_function\_http2\_enabled) | Whether to enable HTTP2 for the Function App. | `bool` | `true` | no |
| <a name="input_function_https_only"></a> [function\_https\_only](#input\_function\_https\_only) | Whether to only allow HTTPS access to the Function App. | `bool` | `true` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | The name of the Function App to create. | `string` | `"funcapp-streamsec-rte"` | no |
| <a name="input_function_public_access_enabled"></a> [function\_public\_access\_enabled](#input\_function\_public\_access\_enabled) | Whether to enable public access to the Function App. | `bool` | `false` | no |
| <a name="input_function_tags"></a> [function\_tags](#input\_function\_tags) | The tags to apply to the Function App. | `map(string)` | `{}` | no |
| <a name="input_function_zip_filename"></a> [function\_zip\_filename](#input\_function\_zip\_filename) | The name of the zip file to store the Function App code. | `string` | `"LightlyticsEventhubtrigger.zip"` | no |
| <a name="input_location"></a> [location](#input\_location) | The location to create the Stream Security Azure resources in. | `string` | `"East US"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group to create the Stream Security Azure resources in. | `string` | `"rg-streamsec-rte"` | no |
| <a name="input_resource_group_tags"></a> [resource\_group\_tags](#input\_resource\_group\_tags) | The tags to apply to the resource group. | `map(string)` | `{}` | no |
| <a name="input_service_plan_name"></a> [service\_plan\_name](#input\_service\_plan\_name) | The name of the Service Plan to create. | `string` | `"asp-streamsec-rte"` | no |
| <a name="input_service_plan_tags"></a> [service\_plan\_tags](#input\_service\_plan\_tags) | The tags to apply to the Service Plan. | `map(string)` | `{}` | no |
| <a name="input_storage_account_blob_delete_retention_days"></a> [storage\_account\_blob\_delete\_retention\_days](#input\_storage\_account\_blob\_delete\_retention\_days) | The number of days to retain deleted blobs in the Storage Account. | `number` | `7` | no |
| <a name="input_storage_account_min_tls_version"></a> [storage\_account\_min\_tls\_version](#input\_storage\_account\_min\_tls\_version) | The minimum TLS version for the Storage Account. | `string` | `"TLS1_2"` | no |
| <a name="input_storage_account_name_prefix"></a> [storage\_account\_name\_prefix](#input\_storage\_account\_name\_prefix) | The name of the Storage Account to prefix | `string` | `"storstreamsecrte"` | no |
| <a name="input_storage_account_replication_type"></a> [storage\_account\_replication\_type](#input\_storage\_account\_replication\_type) | The replication type for the Storage Account. | `string` | `"LRS"` | no |
| <a name="input_storage_account_tags"></a> [storage\_account\_tags](#input\_storage\_account\_tags) | The tags to apply to the Storage Account. | `map(string)` | `{}` | no |
| <a name="input_storage_account_tier"></a> [storage\_account\_tier](#input\_storage\_account\_tier) | The tier for the Storage Account. | `string` | `"Standard"` | no |
| <a name="input_subscriptions"></a> [subscriptions](#input\_subscriptions) | The list of Azure subscription IDs enable Real Time Events for. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to apply to the Stream Security Azure resources. | `map(string)` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
