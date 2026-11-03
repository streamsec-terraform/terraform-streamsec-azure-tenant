# `terraform test` needs Terraform >= 1.7 (mock_provider), stricter than the module's own
# required_version. Mock providers throughout: no Azure API calls.

mock_provider "azurerm" {
  source = "./tests/mocks/azurerm"
}

variables {
  hub_principal_ids = {
    hub_a = "11111111-1111-1111-1111-111111111111"
    hub_b = "22222222-2222-2222-2222-222222222222"
  }
  grant_on = {
    subscription_ids = [
      "AAAAAAAA-0000-0000-0000-000000000001",
      "aaaaaaaa-0000-0000-0000-000000000002",
    ]
  }
}

################################################################################
# Where the hubs get access
################################################################################

run "subscriptions_get_a_role_each_and_every_hub_on_each" {
  command = plan

  assert {
    condition = alltrue([
      length(azurerm_role_definition.target) == 2,
      length(azurerm_role_assignment.target) == 4,
      length(azurerm_role_assignment.acr_pull) == 4,
      length(azurerm_role_definition.function_packages) == 2,
      length(azurerm_role_assignment.function_packages) == 4,
    ])
    error_message = "Two subscriptions and two hubs, every workload kind on: a target and a function-package role per subscription, and each assignment once per hub and subscription."
  }

  assert {
    condition = alltrue([
      azurerm_role_definition.target["aaaaaaaa-0000-0000-0000-000000000001"].scope == "/subscriptions/aaaaaaaa-0000-0000-0000-000000000001",
      azurerm_role_definition.target["aaaaaaaa-0000-0000-0000-000000000001"].name == "Stream Security Volume Scanner Target (aaaaaaaa-0000-0000-0000-000000000001)",
      azurerm_role_definition.target["aaaaaaaa-0000-0000-0000-000000000001"].assignable_scopes == tolist(["/subscriptions/aaaaaaaa-0000-0000-0000-000000000001"]),
    ])
    error_message = "Each subscription's role must be defined and assignable there, named after the subscription, with its ID lowercased."
  }

  assert {
    condition = alltrue([
      azurerm_role_assignment.target["aaaaaaaa-0000-0000-0000-000000000002/hub_b"].scope == "/subscriptions/aaaaaaaa-0000-0000-0000-000000000002",
      azurerm_role_assignment.target["aaaaaaaa-0000-0000-0000-000000000002/hub_b"].principal_id == "22222222-2222-2222-2222-222222222222",
      azurerm_role_assignment.target["aaaaaaaa-0000-0000-0000-000000000002/hub_b"].principal_type == "ServicePrincipal",
      azurerm_role_assignment.acr_pull["aaaaaaaa-0000-0000-0000-000000000002/hub_b"].role_definition_name == "AcrPull",
    ])
    error_message = "A hub's assignments must be on the subscription, to its principal, as a service principal."
  }

  assert {
    condition     = output.granted_on.scope == "subscriptions" && output.granted_on.ids == tolist(["aaaaaaaa-0000-0000-0000-000000000001", "aaaaaaaa-0000-0000-0000-000000000002"])
    error_message = "granted_on must name the subscriptions."
  }
}

run "a_management_group_gets_one_role" {
  command = plan

  variables {
    grant_on = { management_group_id = "contoso-workloads" }
  }

  assert {
    condition = alltrue([
      length(azurerm_role_definition.target) == 1,
      azurerm_role_definition.target["contoso-workloads"].scope == "/providers/Microsoft.Management/managementGroups/contoso-workloads",
      azurerm_role_definition.target["contoso-workloads"].name == "Stream Security Volume Scanner Target (contoso-workloads)",
      length(azurerm_role_assignment.target) == 2,
      azurerm_role_assignment.target["contoso-workloads/hub_a"].scope == "/providers/Microsoft.Management/managementGroups/contoso-workloads",
    ])
    error_message = "A management group must get one role, defined and granted on the group."
  }

  assert {
    condition     = output.granted_on.scope == "management_group" && output.granted_on.ids == tolist(["contoso-workloads"])
    error_message = "granted_on must name the management group."
  }
}

################################################################################
# What the grant allows
################################################################################

run "the_target_role_reads_and_snapshots_but_starts_no_jobs" {
  command = plan

  assert {
    condition = alltrue([
      contains(azurerm_role_definition.target["aaaaaaaa-0000-0000-0000-000000000001"].permissions[0].actions, "Microsoft.Resources/subscriptions/read"),
      contains(azurerm_role_definition.target["aaaaaaaa-0000-0000-0000-000000000001"].permissions[0].actions, "Microsoft.Compute/virtualMachines/read"),
      contains(azurerm_role_definition.target["aaaaaaaa-0000-0000-0000-000000000001"].permissions[0].actions, "Microsoft.Compute/snapshots/write"),
      length([
        for action in azurerm_role_definition.target["aaaaaaaa-0000-0000-0000-000000000001"].permissions[0].actions :
        action if startswith(action, "Microsoft.App/jobs")
      ]) == 0,
    ])
    error_message = "The target role must read subscriptions and VMs and write snapshots, and must not start jobs: only the hub runs them."
  }

  assert {
    condition = alltrue([
      azurerm_role_definition.function_packages["aaaaaaaa-0000-0000-0000-000000000001"].permissions[0].data_actions == toset(["Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"]),
      azurerm_role_assignment.function_packages["aaaaaaaa-0000-0000-0000-000000000001/hub_a"].condition_version == "2.0",
      strcontains(azurerm_role_assignment.function_packages["aaaaaaaa-0000-0000-0000-000000000001/hub_a"].condition, "StringEquals 'released-package.zip'"),
    ])
    error_message = "The function-package read must be limited to released-package.zip by its assignment's condition."
  }
}

run "no_workloads_grants_vm_scanning_only" {
  command = plan

  variables {
    workload_kinds = ""
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.target) == 4,
      length(azurerm_role_assignment.acr_pull) == 0,
      length(azurerm_role_definition.function_packages) == 0,
      length(azurerm_role_assignment.function_packages) == 0,
    ])
    error_message = "With no workload kinds, neither AcrPull nor the function-package role may be granted."
  }
}

run "workloads_without_functions_skip_the_package_role" {
  command = plan

  variables {
    workload_kinds = "containerapps, appservice"
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.acr_pull) == 4,
      length(azurerm_role_definition.function_packages) == 0,
    ])
    error_message = "AcrPull comes with any workload kind, the function-package role only with azurefunctions."
  }
}

################################################################################
# Refused inputs
################################################################################

run "both_scopes_are_refused" {
  command = plan

  variables {
    grant_on = {
      management_group_id = "contoso-workloads"
      subscription_ids    = ["aaaaaaaa-0000-0000-0000-000000000001"]
    }
  }

  expect_failures = [var.grant_on]
}

run "no_scope_is_refused" {
  command = plan

  variables {
    grant_on = {}
  }

  expect_failures = [var.grant_on]
}

run "an_empty_subscription_list_is_refused" {
  command = plan

  variables {
    grant_on = { subscription_ids = [] }
  }

  expect_failures = [var.grant_on]
}

run "a_management_group_resource_id_is_refused" {
  command = plan

  variables {
    grant_on = { management_group_id = "/providers/Microsoft.Management/managementGroups/contoso-workloads" }
  }

  expect_failures = [var.grant_on]
}

run "a_principal_that_is_not_a_guid_is_refused" {
  command = plan

  variables {
    hub_principal_ids = { hub_a = "streamsec-scanner-mi" }
  }

  expect_failures = [var.hub_principal_ids]
}

run "an_unknown_workload_kind_is_refused" {
  command = plan

  variables {
    workload_kinds = "containerapps,vms"
  }

  expect_failures = [var.workload_kinds]
}
