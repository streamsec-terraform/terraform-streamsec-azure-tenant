locals {
  # one scope per management group or subscription, keyed by its ID
  scopes = var.grant_on.management_group_id != null ? {
    (var.grant_on.management_group_id) = "/providers/Microsoft.Management/managementGroups/${var.grant_on.management_group_id}"
    } : {
    for id in var.grant_on.subscription_ids : lower(id) => "/subscriptions/${lower(id)}"
  }

  # each hub on each scope, keyed "<scope>/<hub>"
  grants = {
    for pair in setproduct(keys(local.scopes), keys(var.hub_principal_ids)) : "${pair[0]}/${pair[1]}" => {
      scope        = pair[0]
      principal_id = var.hub_principal_ids[pair[1]]
    }
  }

  workload_kind_list     = [for kind in split(",", var.workload_kinds) : trimspace(kind) if trimspace(kind) != ""]
  scan_workloads         = length(local.workload_kind_list) > 0
  scan_function_packages = contains(local.workload_kind_list, "azurefunctions")

  # Azure refuses a custom role with data actions on a management group, so the package
  # read there is the built-in Storage Blob Data Reader, limited by the same condition
  on_management_group = var.grant_on.management_group_id != null
}

################################################################################
# Roles
################################################################################

# modules/volume-scanner's scanner role without starting jobs, which only the hub does,
# plus the subscription read the hub checks each subscription with before scanning it.
# Snapshots are made in the scanned subscription: Azure keeps an incremental snapshot
# in its disk's subscription.
resource "azurerm_role_definition" "target" {
  for_each = local.scopes

  # custom role names are unique per tenant, so the name includes the scope
  name        = "Stream Security Volume Scanner Target (${each.key})"
  scope       = each.value
  description = "Lets Stream Security volume scanner hubs scan the subscriptions here: VM and workload discovery, and snapshot create/SAS-grant/SAS-revoke/delete on their managed disks."

  permissions {
    actions = [
      "Microsoft.Resources/subscriptions/read",
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
      "Microsoft.ResourceGraph/resources/read",
      "Microsoft.App/containerApps/read",
      "Microsoft.App/containerApps/revisions/read",
      "Microsoft.Web/sites/read",
      "Microsoft.Web/sites/sitecontainers/Read",
      "Microsoft.ContainerInstance/containerGroups/read",
    ]
  }

  assignable_scopes = [each.value]
}

resource "azurerm_role_assignment" "target" {
  for_each = local.grants

  scope              = local.scopes[each.value.scope]
  role_definition_id = azurerm_role_definition.target[each.value.scope].role_definition_resource_id
  principal_id       = each.value.principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "acr_pull" {
  for_each = local.scan_workloads ? local.grants : {}

  scope                = local.scopes[each.value.scope]
  role_definition_name = "AcrPull"
  principal_id         = each.value.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_definition" "function_packages" {
  for_each = local.scan_function_packages && !local.on_management_group ? local.scopes : {}

  name        = "Stream Security Volume Scanner Target function packages (${each.key})"
  scope       = each.value
  description = "Lets Stream Security volume scanner hubs read Flex Consumption Function App deployment packages here. Its assignments limit the read to blobs named released-package.zip."

  permissions {
    data_actions = ["Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"]
  }

  assignable_scopes = [each.value]
}

resource "azurerm_role_assignment" "function_packages" {
  for_each = local.scan_function_packages ? local.grants : {}

  scope                = local.scopes[each.value.scope]
  role_definition_id   = local.on_management_group ? null : azurerm_role_definition.function_packages[each.value.scope].role_definition_resource_id
  role_definition_name = local.on_management_group ? "Storage Blob Data Reader" : null
  principal_id         = each.value.principal_id
  principal_type       = "ServicePrincipal"
  condition_version    = "2.0"
  condition            = "((!(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'})) OR (@Resource[Microsoft.Storage/storageAccounts/blobServices/containers/blobs:path] StringEquals 'released-package.zip'))"
}
