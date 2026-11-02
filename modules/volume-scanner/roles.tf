################################################################################
# Subscription-scoped roles of the scanner's managed identity. Creating a custom
# role needs Owner or User Access Administrator on the subscription.
################################################################################

# What the scanner reads, snapshots and starts across the subscription. Named after the
# resource group: custom role names are unique in the Entra tenant.
resource "azurerm_role_definition" "scanner" {
  name        = "Stream Security Volume Scanner (${azurerm_resource_group.this.name})"
  scope       = local.subscription_scope
  description = "Minimum permissions for the Stream Security agentless volume scanner: VM/disk discovery via Resource Graph, snapshot create/SAS-grant/SAS-revoke/delete on managed disks, Container Apps Job orchestrator -> worker fan-out."

  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachineScaleSets/read",
      "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/read",
      "Microsoft.Compute/disks/read",
      "Microsoft.Compute/disks/beginGetAccess/action",
      "Microsoft.Compute/snapshots/read",
      "Microsoft.Compute/snapshots/write",
      "Microsoft.Compute/snapshots/delete",
      "Microsoft.Compute/snapshots/beginGetAccess/action",
      "Microsoft.Compute/snapshots/endGetAccess/action",
      "Microsoft.App/jobs/read",
      "Microsoft.App/jobs/start/action",
      "Microsoft.App/jobs/executions/read",
      "Microsoft.ResourceGraph/resources/read",
      "Microsoft.App/containerApps/read",
      "Microsoft.App/containerApps/revisions/read",
      "Microsoft.Web/sites/read",
      "Microsoft.Web/sites/sitecontainers/Read",
      "Microsoft.ContainerInstance/containerGroups/read",
    ]
  }

  assignable_scopes = [local.subscription_scope]
}

resource "azurerm_role_assignment" "scanner" {
  scope              = local.subscription_scope
  role_definition_id = azurerm_role_definition.scanner.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.this.principal_id
  # Set, so a just-created identity that has not replicated yet is not rejected.
  principal_type = "ServicePrincipal"
}

# Pulls workload images from any registry in the subscription. To scope it to specific
# registries instead, set workload_kinds = "" and assign AcrPull on them yourself.
resource "azurerm_role_assignment" "acr_pull" {
  count = local.scan_workloads ? 1 : 0

  scope                = local.subscription_scope
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  principal_type       = "ServicePrincipal"
}

# Flex Consumption Function Apps keep their code in a blob. A custom role, as the built-in
# Storage Blob Data Reader also lists every container; the assignment's condition limits
# the read to blobs named released-package.zip.
resource "azurerm_role_definition" "function_packages" {
  count = local.scan_function_packages ? 1 : 0

  name        = "Stream Security Volume Scanner function packages (${azurerm_resource_group.this.name})"
  scope       = local.subscription_scope
  description = "Lets the Stream Security volume scanner read Flex Consumption Function App deployment packages. Its assignment limits the read to blobs named released-package.zip."

  permissions {
    data_actions = ["Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"]
  }

  assignable_scopes = [local.subscription_scope]
}

resource "azurerm_role_assignment" "function_packages" {
  count = local.scan_function_packages ? 1 : 0

  scope              = local.subscription_scope
  role_definition_id = azurerm_role_definition.function_packages[0].role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.this.principal_id
  principal_type     = "ServicePrincipal"
  condition_version  = "2.0"
  condition          = "((!(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'})) OR (@Resource[Microsoft.Storage/storageAccounts/blobServices/containers/blobs:path] StringEquals 'released-package.zip'))"
}
