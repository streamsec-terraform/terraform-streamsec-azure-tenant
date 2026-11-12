## Notes

- The scanner is deployed into the azurerm provider's subscription, which must be one of the tenant's `subscriptions`.
- For a tenant connected from the console, use the `id` of the `streamsec_azure_tenant` data source as `account_id`.
- The identity running Terraform needs Owner, or Contributor and User Access Administrator, on the subscription.
- The `Microsoft.App`, `Microsoft.OperationalInsights`, `Microsoft.Network` and `Microsoft.ManagedIdentity` resource providers must be registered in the subscription.
- Don't deploy the module in a subscription that has the scanner from the console's ARM template: delete that deployment's resource group first.
- To have this scanner also scan other subscriptions of the tenant, as a hub, grant its managed identity access there with [`modules/volume-scanner-hub-access`](../volume-scanner-hub-access), then choose them in Stream Security.
- The collection token is stored in the Terraform state and in plan files.
- `terraform destroy` removes the scanner and reports it uninstalled. Destroy the scanner before disconnecting the tenant, or run `terraform destroy -refresh=false`. Disk snapshots left behind by an interrupted scan are not managed by Terraform.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >= 2.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.17 |
| <a name="requirement_streamsec"></a> [streamsec](#requirement\_streamsec) | >= 1.15.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | >= 2.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.17 |
| <a name="provider_streamsec"></a> [streamsec](#provider\_streamsec) | >= 1.15.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_resource.subnet](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource_action.initial_scan](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource_action) | resource |
| [azurerm_container_app_environment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) | resource |
| [azurerm_container_app_job.orchestrator](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_job) | resource |
| [azurerm_container_app_job.worker](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_job) | resource |
| [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway) | resource |
| [azurerm_nat_gateway_public_ip_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_association) | resource |
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.nat](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.acr_pull](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.function_packages](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.scanner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.worker_start](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_definition.function_packages](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |
| [azurerm_role_definition.scanner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |
| [azurerm_role_definition.worker_start](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |
| [azurerm_user_assigned_identity.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [streamsec_azure_volume_scanner_ack.this](https://registry.terraform.io/providers/streamsec-terraform/streamsec/latest/docs/resources/azure_volume_scanner_ack) | resource |
| [azurerm_resources.scanner_jobs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resources) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |
| [streamsec_azure_volume_scanner.this](https://registry.terraform.io/providers/streamsec-terraform/streamsec/latest/docs/data-sources/azure_volume_scanner) | data source |
| [streamsec_host.this](https://registry.terraform.io/providers/streamsec-terraform/streamsec/latest/docs/data-sources/host) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The Stream Security ID of the Azure tenant, such as the root module's `account_id` output. The tenant must be acknowledged first. | `string` | n/a | yes |
| <a name="input_allow_arm_coexistence"></a> [allow\_arm\_coexistence](#input\_allow\_arm\_coexistence) | Whether to allow deploying when another scanner exists in the subscription, such as the console's ARM deployment. Two scanners in one subscription interfere with each other. | `bool` | `false` | no |
| <a name="input_customer_id"></a> [customer\_id](#input\_customer\_id) | The Stream Security workspace ID, the same as the streamsec provider's `workspace_id`. | `string` | n/a | yes |
| <a name="input_existing_subnet_id"></a> [existing\_subnet\_id](#input\_existing\_subnet\_id) | The ID of an existing subnet to run the scanner in. Only used if `network_mode` is `use_existing`. The subnet must be delegated to Microsoft.App/environments, be /27 or larger and have outbound internet access. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The location to create the scanner resources in. The scanner covers every location of the subscription. | `string` | n/a | yes |
| <a name="input_max_concurrent_shards"></a> [max\_concurrent\_shards](#input\_max\_concurrent\_shards) | The maximum number of worker executions running at once. | `number` | `10` | no |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | Whether to create a new VNet with a NAT gateway for the scanner (`create_new`) or to use an existing subnet (`use_existing`). | `string` | `"create_new"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group to create for the scanner. Defaults to `streamsec-scanner-tf-` followed by the first 8 characters of the subscription ID. | `string` | `null` | no |
| <a name="input_scan_ai_workloads"></a> [scan\_ai\_workloads](#input\_scan\_ai\_workloads) | Whether to detect AI/ML frameworks. | `bool` | `false` | no |
| <a name="input_scan_data_volumes"></a> [scan\_data\_volumes](#input\_scan\_data\_volumes) | Whether to scan VM data disks in addition to OS disks. | `bool` | `true` | no |
| <a name="input_scan_databases"></a> [scan\_databases](#input\_scan\_databases) | Whether to detect installed databases. | `bool` | `false` | no |
| <a name="input_scan_kubernetes_volumes"></a> [scan\_kubernetes\_volumes](#input\_scan\_kubernetes\_volumes) | Whether to scan disks created for Kubernetes persistent volume claims. Only used if `scan_data_volumes` is true. | `bool` | `false` | no |
| <a name="input_scan_language_packages"></a> [scan\_language\_packages](#input\_scan\_language\_packages) | Whether to scan language packages (Python, Node, Ruby, Go, Rust, Java). | `bool` | `true` | no |
| <a name="input_scan_secrets"></a> [scan\_secrets](#input\_scan\_secrets) | Whether to scan for secrets on disk. Increases scan duration. | `bool` | `false` | no |
| <a name="input_scanner_image"></a> [scanner\_image](#input\_scanner\_image) | The scanner container image. Pin a release tag to control upgrades. | `string` | `"public.ecr.aws/stream-security/volume-scanner:latest"` | no |
| <a name="input_schedule_cron_expression"></a> [schedule\_cron\_expression](#input\_schedule\_cron\_expression) | The scan schedule, as a cron expression in UTC. | `string` | `"0 3 * * *"` | no |
| <a name="input_shard_size"></a> [shard\_size](#input\_shard\_size) | The number of VMs each worker execution scans. | `number` | `100` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to apply to the scanner resources. | `map(string)` | `{}` | no |
| <a name="input_tenant_name"></a> [tenant\_name](#input\_tenant\_name) | The Stream Security tenant name. Defaults to the first label of the streamsec provider host. | `string` | `null` | no |
| <a name="input_trigger_initial_scan"></a> [trigger\_initial\_scan](#input\_trigger\_initial\_scan) | Whether to start a scan right after the scanner is created. | `bool` | `true` | no |
| <a name="input_workload_kinds"></a> [workload\_kinds](#input\_workload\_kinds) | Comma-separated workloads to scan besides VMs: containerapps, azurefunctions, appservice, containerinstances. Set to an empty string to scan VMs only. | `string` | `"containerapps,azurefunctions,appservice,containerinstances"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id) | Log Analytics workspace receiving the scanner's container logs |
| <a name="output_managed_identity_client_id"></a> [managed\_identity\_client\_id](#output\_managed\_identity\_client\_id) | Client id of the scanner's user-assigned managed identity |
| <a name="output_managed_identity_principal_id"></a> [managed\_identity\_principal\_id](#output\_managed\_identity\_principal\_id) | Principal id of the scanner's user-assigned managed identity, which holds the subscription-scoped roles and the worker job's start and stop role |
| <a name="output_nat_gateway_public_ip"></a> [nat\_gateway\_public\_ip](#output\_nat\_gateway\_public\_ip) | Static egress IP of the scanner's NAT gateway, for allowlisting. Null with network\_mode = "use\_existing", since egress is then through a network this module does not own. |
| <a name="output_orchestrator_job_id"></a> [orchestrator\_job\_id](#output\_orchestrator\_job\_id) | Resource id of the orchestrator job, for starting a scan by hand |
| <a name="output_orchestrator_job_name"></a> [orchestrator\_job\_name](#output\_orchestrator\_job\_name) | Name of the Container Apps job that runs on the schedule and starts the workers |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group holding the scanner's resources |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | Subnet the scanner runs in: the one this module created, or existing\_subnet\_id |
| <a name="output_worker_job_name"></a> [worker\_job\_name](#output\_worker\_job\_name) | Name of the Container Apps job the orchestrator starts once per shard of VMs and once for the workloads |
<!-- END_TF_DOCS -->
