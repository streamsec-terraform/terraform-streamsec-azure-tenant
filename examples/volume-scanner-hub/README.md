# Volume scanner hub

A hub subscription's volume scanner that also scans a second subscription of the tenant. [`modules/volume-scanner`](../../modules/volume-scanner) deploys the scanner in the hub, and [`modules/volume-scanner-hub-access`](../../modules/volume-scanner-hub-access) grants its managed identity access to the second subscription. Choose that subscription in the Stream Security console afterwards, under the hub's "Subscriptions this scanner scans".

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.17 |
| <a name="requirement_streamsec"></a> [streamsec](#requirement\_streamsec) | >= 1.15.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_streamsec"></a> [streamsec](#provider\_streamsec) | >= 1.15.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_hub_access"></a> [hub\_access](#module\_hub\_access) | ../../modules/volume-scanner-hub-access | n/a |
| <a name="module_hub_scanner"></a> [hub\_scanner](#module\_hub\_scanner) | ../../modules/volume-scanner | n/a |

## Resources

| Name | Type |
|------|------|
| [streamsec_azure_tenant.this](https://registry.terraform.io/providers/streamsec-terraform/streamsec/latest/docs/data-sources/azure_tenant) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_hub_subscription_id"></a> [hub\_subscription\_id](#input\_hub\_subscription\_id) | The subscription whose scanner also scans the other one. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The location of the hub's scanner resources. | `string` | `"eastus"` | no |
| <a name="input_scanned_subscription_id"></a> [scanned\_subscription\_id](#input\_scanned\_subscription\_id) | The subscription the hub scans. | `string` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | The Azure tenant ID, connected to Stream Security. | `string` | n/a | yes |
| <a name="input_workspace_id"></a> [workspace\_id](#input\_workspace\_id) | The Stream Security workspace ID. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_granted_on"></a> [granted\_on](#output\_granted\_on) | Where the hub has access. |
| <a name="output_hub_principal_id"></a> [hub\_principal\_id](#output\_hub\_principal\_id) | Principal ID of the hub scanner's managed identity. |
<!-- END_TF_DOCS -->
