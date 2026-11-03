################################################################################
# Hubs and where they scan
################################################################################

variable "hub_principal_ids" {
  description = "The principal IDs of the hubs' scanner identities, each hub's `managed_identity_principal_id` output of modules/volume-scanner, keyed by any name known at plan time, such as the hub's subscription ID. A hub is a volume scanner that also scans other subscriptions of the tenant, the ones chosen in Stream Security. List every hub of the scope in one instance."
  type        = map(string)
  nullable    = false

  validation {
    condition = alltrue([
      for id in values(var.hub_principal_ids) :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id))
    ])
    error_message = "Each value of hub_principal_ids must be the principal ID (object ID) of a hub scanner's managed identity, a GUID."
  }
}

variable "grant_on" {
  description = "Where the hubs get access, exactly one of: `{ management_group_id = \"...\" }` for every subscription under the management group, including ones added later; or `{ subscription_ids = [...] }` for those subscriptions only. IDs must be known at plan time."
  type = object({
    management_group_id = optional(string)
    subscription_ids    = optional(list(string))
  })
  nullable = false

  validation {
    condition     = (var.grant_on.management_group_id == null) != (var.grant_on.subscription_ids == null)
    error_message = "Set exactly one of grant_on.management_group_id and grant_on.subscription_ids."
  }

  validation {
    condition     = var.grant_on.management_group_id == null || can(regex("^[A-Za-z0-9._()-]{1,90}$", coalesce(var.grant_on.management_group_id, "-")))
    error_message = "grant_on.management_group_id must be the management group's ID (its name), not its resource ID."
  }

  validation {
    condition = var.grant_on.subscription_ids == null || (
      length(coalesce(var.grant_on.subscription_ids, [])) > 0 &&
      alltrue([
        for id in coalesce(var.grant_on.subscription_ids, []) :
        can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id))
      ])
    )
    error_message = "grant_on.subscription_ids must list at least one subscription ID, each a GUID."
  }
}

################################################################################
# Workloads
################################################################################

variable "workload_kinds" {
  description = "Comma-separated workloads the hubs scan besides VMs, as their modules/volume-scanner `workload_kinds`: AcrPull is granted when any is set, and the read of Flex Consumption function packages with azurefunctions. Set to an empty string to grant VM scanning only."
  type        = string
  default     = "containerapps,azurefunctions,appservice,containerinstances"
  nullable    = false

  validation {
    condition = length(setsubtract(
      toset([for kind in split(",", var.workload_kinds) : trimspace(kind) if trimspace(kind) != ""]),
      toset(["containerapps", "azurefunctions", "appservice", "containerinstances"])
      )) == 0 && (
      var.workload_kinds == "" ||
      length([for kind in split(",", var.workload_kinds) : kind if trimspace(kind) != ""]) > 0
    )
    error_message = "workload_kinds must be a comma-separated subset of containerapps, azurefunctions, appservice and containerinstances, or exactly \"\" to grant VM scanning only."
  }
}
