## Stream Security volume scanner: hubs' access to other subscriptions

A **hub** is a subscription whose volume scanner ([`modules/volume-scanner`](../volume-scanner)) also scans other subscriptions of the tenant, the ones chosen in Stream Security. The hub runs every scan from its own Container Apps jobs, as its own managed identity. In the subscriptions it scans, it reads VMs and workloads and snapshots their disks there: Azure keeps an incremental snapshot in its disk's subscription, so the snapshots go to the disk's resource group, and the hub deletes them as the scanner does in its own subscription.

This module gives the hubs' managed identities that access, on a management group or on a list of subscriptions. It grants what the console's "Deploy to Azure" access template grants, for teams that manage Azure RBAC with Terraform.

### What this module creates

On each scope, the management group or each subscription:

- The custom role `Stream Security Volume Scanner Target (<scope ID>)`: the actions of the scanner's own role without starting jobs, which only the hub does, plus `Microsoft.Resources/subscriptions/read`, which the hub checks each subscription with before scanning it.
- With `azurefunctions` in `workload_kinds`, the custom role `Stream Security Volume Scanner Target function packages (<scope ID>)`, a blob read.

For each hub on each scope, assignments to its managed identity:

- the target role;
- `AcrPull`, when `workload_kinds` has any kind, to pull workload images;
- the function-package role, limited by its assignment's condition to blobs named `released-package.zip`.

Nothing is created in the hubs.

### Usage

```hcl
module "hub_scanner" {
  source      = "streamsec-terraform/azure-tenant/streamsec//modules/volume-scanner"
  account_id  = data.streamsec_azure_tenant.this.id
  customer_id = var.workspace_id
  location    = "eastus"
}

module "hub_access" {
  source = "streamsec-terraform/azure-tenant/streamsec//modules/volume-scanner-hub-access"

  hub_principal_ids = {
    hub = module.hub_scanner.managed_identity_principal_id
  }

  grant_on = {
    subscription_ids = ["xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]
  }
}
```

Then set which subscriptions the hub scans, with the streamsec provider's `streamsec_azure_scanner_hub` or in the Stream Security console, under "Subscriptions this scanner scans". [`examples/volume-scanner-hub`](../../examples/volume-scanner-hub) has the whole setup.

### Notes

- **Where to grant.** A management group covers every subscription under it, including ones added later, whether or not it is chosen in Stream Security. To match the chosen subscriptions exactly, use `subscription_ids`.
- **One instance per scope.** Custom role names are unique in a tenant, so a second instance on the same management group or subscription fails on the role. List every hub in `hub_principal_ids`. To stop a hub, remove it and apply: that revokes its assignments and nothing else.
- **Plan-time keys.** The keys of `hub_principal_ids` and the IDs in `grant_on` must be known at plan time. The principal IDs may come from a scanner created in the same apply.
- **Permissions to apply.** The identity running Terraform needs Owner, or User Access Administrator, on each scope: the module creates role definitions and role assignments.
- **A subscription with its own scanner** keeps scanning itself; a hub doesn't scan it.
- **Removing access.** `terraform destroy` deletes the roles and assignments. Until the subscriptions are also taken off the hub in Stream Security, the hub reports them as having no access.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.17 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.17 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_role_assignment.acr_pull](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.function_packages](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.target](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_definition.function_packages](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |
| [azurerm_role_definition.target](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_grant_on"></a> [grant\_on](#input\_grant\_on) | Where the hubs get access, exactly one of: `{ management_group_id = "..." }` for every subscription under the management group, including ones added later; or `{ subscription_ids = [...] }` for those subscriptions only. IDs must be known at plan time. | <pre>object({<br/>    management_group_id = optional(string)<br/>    subscription_ids    = optional(list(string))<br/>  })</pre> | n/a | yes |
| <a name="input_hub_principal_ids"></a> [hub\_principal\_ids](#input\_hub\_principal\_ids) | The principal IDs of the hubs' scanner identities, each hub's `managed_identity_principal_id` output of modules/volume-scanner, keyed by any name known at plan time, such as the hub's subscription ID. A hub is a volume scanner that also scans other subscriptions of the tenant, the ones chosen in Stream Security. List every hub of the scope in one instance. | `map(string)` | n/a | yes |
| <a name="input_workload_kinds"></a> [workload\_kinds](#input\_workload\_kinds) | Comma-separated workloads the hubs scan besides VMs, as their modules/volume-scanner `workload_kinds`: AcrPull is granted when any is set, and the read of Flex Consumption function packages with azurefunctions. Set to an empty string to grant VM scanning only. | `string` | `"containerapps,azurefunctions,appservice,containerinstances"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_granted_on"></a> [granted\_on](#output\_granted\_on) | Where the hubs have access: scope is management\_group or subscriptions, and ids the management group ID or the subscription IDs. |
| <a name="output_role_definition_ids"></a> [role\_definition\_ids](#output\_role\_definition\_ids) | Resource IDs of the custom role granted to the hubs, one per management group or subscription, keyed by its ID. |
<!-- END_TF_DOCS -->
