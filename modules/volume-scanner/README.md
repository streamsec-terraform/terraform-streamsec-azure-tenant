# terraform-streamsec-azure-tenant/volume-scanner

Terraform module for the Stream Security agentless volume scanner in one Azure subscription. It scans your VMs, Container Apps, Function Apps, App Service web apps and Container Instances for vulnerabilities, with no agents on your VMs and no credentials given to Stream Security.

A Container Apps job, the orchestrator, runs on a schedule (daily at 03:00 UTC by default). It finds the subscription's VMs and starts executions of a second job, the worker, which snapshot the VMs' managed disks, read the installed packages and send them to Stream Security. One more worker execution scans the workloads. The scanner covers every region of the subscription; `location` only places its own resources. Deploy one module instance per subscription you want scanned.

This is the Terraform alternative to the ARM template the console deploys. Use one or the other in a subscription, not both. If the console's deployment is already in the subscription, remove it first; the module stops with an error until you do.

## Usage

```hcl
module "tenant" {
  source        = "streamsec-terraform/azure-tenant/streamsec"
  display_name  = "My tenant"
  subscriptions = ["00000000-0000-0000-0000-000000000000"]
}

# The scanner goes into the azurerm provider's subscription.
module "volume_scanner" {
  source      = "streamsec-terraform/azure-tenant/streamsec//modules/volume-scanner"
  account_id  = module.tenant.account_id
  customer_id = "your-workspace-id"
  location    = "eastus"
}
```

`customer_id` is the same value as `workspace_id` on the `streamsec` provider. `account_id` is the Stream Security id of the tenant. Stream Security hands out the scanner's collection token only once the tenant is acknowledged, and the root module's `account_id` output waits for that. For a tenant connected from the console, read the id instead:

```hcl
data "azurerm_client_config" "current" {}

data "streamsec_azure_tenant" "this" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}

module "volume_scanner" {
  source      = "streamsec-terraform/azure-tenant/streamsec//modules/volume-scanner"
  account_id  = data.streamsec_azure_tenant.this.id
  customer_id = "your-workspace-id"
  location    = "eastus"
}
```

To scan several subscriptions, add a module block for each, with an `azurerm` provider configured for that subscription:

```hcl
provider "azurerm" {
  alias           = "production"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  features {}
}

module "volume_scanner_production" {
  source      = "streamsec-terraform/azure-tenant/streamsec//modules/volume-scanner"
  account_id  = module.tenant.account_id
  customer_id = "your-workspace-id"
  location    = "westeurope"
  providers = {
    azurerm = azurerm.production
  }
}
```

Language packages and the VMs' data disks are scanned by default. Optional scans for secrets, AI/ML frameworks, databases and Kubernetes persistent volumes are off by default: turn them on with `scan_secrets`, `scan_ai_workloads`, `scan_databases` and `scan_kubernetes_volumes`.

## Good to know

- **Permissions.** The identity running Terraform needs Owner or User Access Administrator on the subscription, since the module creates custom roles and assigns them. The `streamsec` provider needs an API token that can write: the module reads the scanner's collection token and acknowledges the install.
- **Resource providers.** `Microsoft.App`, `Microsoft.OperationalInsights`, `Microsoft.Network` and `Microsoft.ManagedIdentity` must be registered in the subscription. From azurerm 5.0 the provider no longer registers them for you by default.
- **Networking.** By default the module creates a VNet (`10.255.0.0/24`, not peered to anything) whose subnet reaches the internet only through a NAT gateway and accepts no inbound traffic. The `nat_gateway_public_ip` output is the scanner's fixed outbound IP, if you need to allowlist it. To use your own network, set `network_mode = "use_existing"` and `existing_subnet_id`. That subnet must be delegated to `Microsoft.App/environments`, be `/27` or larger, and have outbound internet access. A `Microsoft.Storage` service endpoint on it keeps disk reads off your NAT gateway.
- **Workloads.** `workload_kinds` picks the workloads scanned besides VMs. Scanning any of them assigns `AcrPull` on the subscription, to pull images from your registries. `azurefunctions` also assigns a custom role that reads Function App deployment packages, limited by a condition to blobs named `released-package.zip`. Set `workload_kinds = ""` to scan VMs only and drop both.
- **The first scan.** The apply that creates the scanner starts one scan at its end; set `trigger_initial_scan = false` to wait for the schedule instead. If the start fails, so does the apply, and the next apply tries again.
- **Secrets in state.** The collection token is in the Terraform state and in plan files, in plaintext. Store both accordingly.
- **Uninstalling.** Run `terraform destroy`. It tells Stream Security the scanner is uninstalled in the subscription. Disk snapshots the scanner made are in the disks' own resource groups, tagged `Purpose=ebs-package-collector`, and are not in the Terraform state: delete them yourself.
- **Renaming the module block.** Add a `moved` block. Without one, Terraform creates the new instance's acknowledgement and destroys the old one's in the same apply, in no fixed order, so the subscription can end up marked uninstalled.

## Moving from the console's ARM deployment

The console's deployment and this module would both scan every VM and delete each other's snapshots, so the module refuses to apply while it finds the console's orchestrator job in the subscription. Delete the deployment's resource group (`streamsec-scanner-<first 8 characters of the subscription id>` unless you renamed it), then apply. The deployment's custom roles and their assignments are at subscription scope and stay behind; delete them too if you like. The module's own resource group is `streamsec-scanner-tf-<same>`, so the two never share a name.

To run both deliberately, set `allow_arm_coexistence = true`.

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
| [azurerm_role_definition.function_packages](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |
| [azurerm_role_definition.scanner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |
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
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Stream Security id of the Azure tenant, not the Azure tenant id: the root module's account\_id output, or the id of a streamsec\_azure\_tenant resource or data source. The tenant must be acknowledged before this module can read the scanner's collection token. | `string` | n/a | yes |
| <a name="input_allow_arm_coexistence"></a> [allow\_arm\_coexistence](#input\_allow\_arm\_coexistence) | Allow deploying alongside another scanner in the same subscription, such as the console's ARM deployment. Off by default: two scanners scan every VM twice and delete each other's snapshots. | `bool` | `false` | no |
| <a name="input_customer_id"></a> [customer\_id](#input\_customer\_id) | Stream Security workspace id, the same value as the streamsec provider's workspace\_id. A wrong value is silent: findings are dropped and the scanner still looks healthy. | `string` | n/a | yes |
| <a name="input_existing_subnet_id"></a> [existing\_subnet\_id](#input\_existing\_subnet\_id) | Resource id of the subnet to run the scanner in, required when network\_mode is "use\_existing" and ignored otherwise. It must be delegated to Microsoft.App/environments, be /27 or larger, and have outbound internet access. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for all of the scanner's resources, such as "eastus". The scanner covers every region of the subscription regardless. | `string` | n/a | yes |
| <a name="input_max_concurrent_shards"></a> [max\_concurrent\_shards](#input\_max\_concurrent\_shards) | Maximum number of worker executions in flight at once. | `number` | `10` | no |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | "create\_new" creates a VNet with a NAT gateway for the scanner. "use\_existing" runs it in existing\_subnet\_id instead. | `string` | `"create_new"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group to create for the scanner. Defaults to streamsec-scanner-tf- and the first 8 characters of the subscription id, apart from the console's streamsec-scanner- with the same suffix. | `string` | `null` | no |
| <a name="input_scan_ai_workloads"></a> [scan\_ai\_workloads](#input\_scan\_ai\_workloads) | Detect AI/ML framework installs and surface them as workload metadata. | `bool` | `false` | no |
| <a name="input_scan_data_volumes"></a> [scan\_data\_volumes](#input\_scan\_data\_volumes) | Also snapshot and scan the data disks attached to a VM, not only its OS disk. | `bool` | `true` | no |
| <a name="input_scan_databases"></a> [scan\_databases](#input\_scan\_databases) | Detect installed databases from their on-disk signatures. Adds a filesystem walk per VM. | `bool` | `false` | no |
| <a name="input_scan_kubernetes_volumes"></a> [scan\_kubernetes\_volumes](#input\_scan\_kubernetes\_volumes) | Also scan the data disks a Kubernetes CSI driver created for pod volume claims, which the data disk scan otherwise skips. | `bool` | `false` | no |
| <a name="input_scan_language_packages"></a> [scan\_language\_packages](#input\_scan\_language\_packages) | Detect language-level packages on disk (Python, Node, Ruby, Go, Rust, Java). | `bool` | `true` | no |
| <a name="input_scan_secrets"></a> [scan\_secrets](#input\_scan\_secrets) | Detect secrets and credentials on disk. Significantly increases scan duration. | `bool` | `false` | no |
| <a name="input_scanner_image"></a> [scanner\_image](#input\_scanner\_image) | Container image of the scanner. Pin a release tag to control upgrades; :latest follows every release. | `string` | `"public.ecr.aws/stream-security/volume-scanner:latest"` | no |
| <a name="input_schedule_cron_expression"></a> [schedule\_cron\_expression](#input\_schedule\_cron\_expression) | When the orchestrator runs, as a five-field cron expression in UTC. Daily at 03:00 by default. | `string` | `"0 3 * * *"` | no |
| <a name="input_shard_size"></a> [shard\_size](#input\_shard\_size) | VMs per worker execution. Lower means more executions in parallel; higher means fewer, longer ones. | `number` | `100` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to add to every resource the module creates. | `map(string)` | `{}` | no |
| <a name="input_tenant_name"></a> [tenant\_name](#input\_tenant\_name) | Stream Security tenant name. Defaults to the first DNS label of the provider host; set it explicitly behind a shared endpoint or a custom DNS name. | `string` | `null` | no |
| <a name="input_trigger_initial_scan"></a> [trigger\_initial\_scan](#input\_trigger\_initial\_scan) | Start one scan at the end of the apply that creates the scanner, instead of waiting for the schedule. | `bool` | `true` | no |
| <a name="input_workload_kinds"></a> [workload\_kinds](#input\_workload\_kinds) | Workloads to scan besides VMs, comma-separated: containerapps, azurefunctions, appservice, containerinstances. "" scans VMs only. Also gates the AcrPull and function-package role assignments. | `string` | `"containerapps,azurefunctions,appservice,containerinstances"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id) | Log Analytics workspace receiving the scanner's container logs |
| <a name="output_managed_identity_client_id"></a> [managed\_identity\_client\_id](#output\_managed\_identity\_client\_id) | Client id of the scanner's user-assigned managed identity |
| <a name="output_managed_identity_principal_id"></a> [managed\_identity\_principal\_id](#output\_managed\_identity\_principal\_id) | Principal id of the scanner's user-assigned managed identity, which holds the subscription-scoped roles |
| <a name="output_nat_gateway_public_ip"></a> [nat\_gateway\_public\_ip](#output\_nat\_gateway\_public\_ip) | Static egress IP of the scanner's NAT gateway, for allowlisting. Null with network\_mode = "use\_existing", since egress is then through a network this module does not own. |
| <a name="output_orchestrator_job_id"></a> [orchestrator\_job\_id](#output\_orchestrator\_job\_id) | Resource id of the orchestrator job, for starting a scan by hand |
| <a name="output_orchestrator_job_name"></a> [orchestrator\_job\_name](#output\_orchestrator\_job\_name) | Name of the Container Apps job that runs on the schedule and starts the workers |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group holding the scanner's resources |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | Subnet the scanner runs in: the one this module created, or existing\_subnet\_id |
| <a name="output_worker_job_name"></a> [worker\_job\_name](#output\_worker\_job\_name) | Name of the Container Apps job the orchestrator starts once per shard of VMs and once for the workloads |
<!-- END_TF_DOCS -->
