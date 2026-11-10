# `terraform test` needs Terraform >= 1.7 (mock_provider), stricter than the module's own
# required_version. Mock providers throughout: no Azure or Stream Security API calls.

mock_provider "azurerm" {
  source = "./tests/mocks/azurerm"
}

mock_provider "azapi" {
  source = "./tests/mocks/azapi"
}

mock_provider "streamsec" {
  source = "./tests/mocks/streamsec"
}

variables {
  account_id  = "0123456789abcdef01234567"
  customer_id = "workspace-abc"
  location    = "eastus"
}

################################################################################
# Shape and the console's settings
################################################################################

run "default_plan_creates_the_whole_scanner" {
  command = plan

  assert {
    condition     = azurerm_resource_group.this.name == "streamsec-scanner-tf-00000000"
    error_message = "The resource group must default to streamsec-scanner-tf-<first 8 characters of the subscription id>."
  }

  assert {
    condition = alltrue([
      length(azurerm_public_ip.nat) == 1,
      length(azurerm_nat_gateway.this) == 1,
      length(azurerm_nat_gateway_public_ip_association.this) == 1,
      length(azurerm_network_security_group.this) == 1,
      length(azurerm_virtual_network.this) == 1,
      length(azapi_resource.subnet) == 1,
    ])
    error_message = "network_mode defaults to create_new: the VNet, subnet, NSG, NAT gateway and its IP must all be planned."
  }

  assert {
    condition = alltrue([
      azurerm_container_app_job.worker.name == "streamsec-scanner-worker",
      azurerm_container_app_job.orchestrator.name == "streamsec-scanner-orchestrator",
      azurerm_container_app_environment.this.name == "streamsec-scanner-env",
      azurerm_log_analytics_workspace.this.name == "streamsec-scanner-logs",
      azurerm_user_assigned_identity.this.name == "streamsec-scanner-mi",
    ])
    error_message = "Inner resource names must stay the ARM template's."
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.acr_pull) == 1,
      length(azurerm_role_definition.function_packages) == 1,
      length(azurerm_role_assignment.function_packages) == 1,
      length(azapi_resource_action.initial_scan) == 1,
    ])
    error_message = "Every workload kind is on by default, so AcrPull, the function-package role and the initial scan must all be planned."
  }

  assert {
    condition = alltrue([
      streamsec_azure_volume_scanner_ack.this.account_id == "0123456789abcdef01234567",
      streamsec_azure_volume_scanner_ack.this.subscription_id == "00000000-0000-0000-0000-000000000000",
      streamsec_azure_volume_scanner_ack.this.module_version == "1.6.0",
      streamsec_azure_volume_scanner_ack.this.resource_group == "streamsec-scanner-tf-00000000",
    ])
    error_message = "The acknowledgement must name the tenant, the subscription, the module version and the resource group."
  }

  assert {
    condition = alltrue([
      azurerm_resource_group.this.tags["streamsec:component"] == "azure-volume-scanner",
      azurerm_resource_group.this.tags["streamsec:customer"] == "workspace-abc",
    ])
    error_message = "The resource group must carry the ARM template's tags."
  }
}

run "resource_group_can_be_renamed" {
  command = plan

  variables {
    resource_group_name = "rg-scanner"
  }

  assert {
    condition = alltrue([
      azurerm_resource_group.this.name == "rg-scanner",
      azurerm_role_definition.scanner.name == "Stream Security Volume Scanner (rg-scanner, 00000000)",
      streamsec_azure_volume_scanner_ack.this.resource_group == "rg-scanner",
    ])
    error_message = "resource_group_name must reach the group, the custom role's name and the acknowledgement."
  }
}

run "subscription_id_is_lowercased" {
  command = plan

  override_data {
    target = data.azurerm_subscription.current
    values = {
      id              = "/subscriptions/0000000A-0000-0000-0000-00000000000B"
      subscription_id = "0000000A-0000-0000-0000-00000000000B"
    }
  }

  assert {
    condition = alltrue([
      data.streamsec_azure_volume_scanner.this.subscription_id == "0000000a-0000-0000-0000-00000000000b",
      streamsec_azure_volume_scanner_ack.this.subscription_id == "0000000a-0000-0000-0000-00000000000b",
      azurerm_resource_group.this.name == "streamsec-scanner-tf-0000000a",
    ])
    error_message = "Stream Security matches the subscription id exactly, in lowercase."
  }
}

run "jobs_match_the_arm_template" {
  command = apply

  assert {
    condition = alltrue([
      azurerm_container_app_job.worker.replica_timeout_in_seconds == 7200,
      azurerm_container_app_job.worker.replica_retry_limit == 0,
      azurerm_container_app_job.worker.manual_trigger_config[0].parallelism == 1,
      azurerm_container_app_job.worker.manual_trigger_config[0].replica_completion_count == 1,
      length(azurerm_container_app_job.worker.schedule_trigger_config) == 0,
      azurerm_container_app_job.worker.template[0].container[0].cpu == 4,
      azurerm_container_app_job.worker.template[0].container[0].memory == "8Gi",
    ])
    error_message = "The worker must be a manual job: 7200s timeout, no retry, parallelism 1, 4 CPU and 8Gi."
  }

  assert {
    condition = alltrue([
      azurerm_container_app_job.orchestrator.replica_timeout_in_seconds == 21600,
      azurerm_container_app_job.orchestrator.replica_retry_limit == 0,
      azurerm_container_app_job.orchestrator.schedule_trigger_config[0].cron_expression == "0 3 * * *",
      azurerm_container_app_job.orchestrator.schedule_trigger_config[0].parallelism == 1,
      length(azurerm_container_app_job.orchestrator.manual_trigger_config) == 0,
      azurerm_container_app_job.orchestrator.template[0].container[0].cpu == 2,
      azurerm_container_app_job.orchestrator.template[0].container[0].memory == "4Gi",
    ])
    error_message = "The orchestrator must be a scheduled job: daily at 03:00, 21600s timeout, 2 CPU and 4Gi."
  }

  # The orchestrator overrides the worker's container by name when it starts a shard.
  assert {
    condition = alltrue([
      azurerm_container_app_job.worker.template[0].container[0].name == "scanner",
      azurerm_container_app_job.orchestrator.template[0].container[0].name == "scanner",
      azurerm_container_app_job.worker.template[0].container[0].image == "public.ecr.aws/stream-security/volume-scanner:latest",
    ])
    error_message = "Both containers must be named scanner and run the scanner image."
  }

  assert {
    condition = alltrue([
      for job in [azurerm_container_app_job.worker, azurerm_container_app_job.orchestrator] :
      job.identity[0].type == "UserAssigned" &&
      job.identity[0].identity_ids == toset([azurerm_user_assigned_identity.this.id]) &&
      [for s in job.secret : s.name] == ["collection-token"] &&
      job.workload_profile_name == "Consumption" &&
      job.container_app_environment_id == azurerm_container_app_environment.this.id
    ])
    error_message = "Both jobs must run as the managed identity, in the environment, with the collection-token secret."
  }

  assert {
    condition = alltrue([
      azurerm_container_app_environment.this.internal_load_balancer_enabled == false,
      azurerm_container_app_environment.this.infrastructure_subnet_id == azapi_resource.subnet[0].id,
      azurerm_container_app_environment.this.log_analytics_workspace_id == azurerm_log_analytics_workspace.this.id,
      azurerm_container_app_environment.this.logs_destination == "log-analytics",
      azurerm_log_analytics_workspace.this.sku == "PerGB2018",
      azurerm_log_analytics_workspace.this.retention_in_days == 30,
    ])
    error_message = "The environment must be external, on the scanner subnet, logging to the PerGB2018 workspace kept 30 days."
  }
}

run "schedule_can_be_changed" {
  command = plan

  variables {
    schedule_cron_expression = "30 1 * * 6"
  }

  assert {
    condition     = azurerm_container_app_job.orchestrator.schedule_trigger_config[0].cron_expression == "30 1 * * 6"
    error_message = "schedule_cron_expression must reach the orchestrator's schedule."
  }
}

################################################################################
# Container environment
################################################################################

run "worker_environment_is_the_arm_templates_plus_kubernetes_volumes" {
  command = apply

  assert {
    condition = (
      length(azurerm_container_app_job.worker.template[0].container[0].env) == 17 &&
      toset([for e in azurerm_container_app_job.worker.template[0].container[0].env : e.name]) == toset([
        "COLLECTOR_PROVIDER",
        "COLLECTOR_ROLE",
        "COLLECTOR_CONCURRENCY",
        "AZURE_CLIENT_ID",
        "COLLECTOR_AZURE_SUBSCRIPTION_ID",
        "COLLECTOR_AZURE_RESOURCE_GROUP",
        "COLLECTOR_TENANT_NAME",
        "COLLECTOR_CUSTOMER_ID",
        "COLLECTOR_STREAM_SCAN_URL",
        "COLLECTOR_STREAM_SCAN_TOKEN",
        "COLLECTOR_STREAM_SCAN_WORKSPACE",
        "COLLECTOR_SCAN_LANGUAGE_PACKAGES",
        "COLLECTOR_SCAN_DATABASES",
        "COLLECTOR_SCAN_AI_WORKLOADS",
        "COLLECTOR_SCAN_SECRETS",
        "COLLECTOR_SCAN_DATA_VOLUMES",
        "COLLECTOR_SCAN_KUBERNETES_VOLUMES",
      ])
    )
    error_message = "The worker's environment must be exactly the ARM template's, plus COLLECTOR_SCAN_KUBERNETES_VOLUMES."
  }

  assert {
    condition = alltrue([
      for pair in [
        "COLLECTOR_PROVIDER=azure",
        "COLLECTOR_ROLE=worker",
        "COLLECTOR_CONCURRENCY=5",
        "AZURE_CLIENT_ID=00000000-0000-0000-0000-000000000001",
        "COLLECTOR_AZURE_SUBSCRIPTION_ID=00000000-0000-0000-0000-000000000000",
        "COLLECTOR_AZURE_RESOURCE_GROUP=streamsec-scanner-tf-00000000",
        "COLLECTOR_TENANT_NAME=acme",
        "COLLECTOR_CUSTOMER_ID=workspace-abc",
        "COLLECTOR_STREAM_SCAN_URL=https://acme.streamsec.io/openapi/vulnerabilities/stream_scan/raw",
        "COLLECTOR_STREAM_SCAN_TOKEN=secret:collection-token",
        "COLLECTOR_STREAM_SCAN_WORKSPACE=workspace-abc",
      ] :
      contains([
        for e in azurerm_container_app_job.worker.template[0].container[0].env :
        e.secret_name != null ? "${e.name}=secret:${e.secret_name}" : "${e.name}=${e.value}"
      ], pair)
    ])
    error_message = "The worker's identity, subscription, tenant, workspace, scan URL and token must reach its environment."
  }
}

run "orchestrator_environment_is_the_arm_templates" {
  command = apply

  assert {
    condition = (
      length(azurerm_container_app_job.orchestrator.template[0].container[0].env) == 14 &&
      toset([for e in azurerm_container_app_job.orchestrator.template[0].container[0].env : e.name]) == toset([
        "COLLECTOR_PROVIDER",
        "COLLECTOR_ROLE",
        "AZURE_CLIENT_ID",
        "COLLECTOR_AZURE_SUBSCRIPTION_ID",
        "COLLECTOR_AZURE_RESOURCE_GROUP",
        "COLLECTOR_AZURE_CONTAINER_APP_JOB",
        "COLLECTOR_SHARD_SIZE",
        "COLLECTOR_MAX_CONCURRENT_SHARDS",
        "COLLECTOR_WORKLOAD_KINDS",
        "COLLECTOR_TENANT_NAME",
        "COLLECTOR_CUSTOMER_ID",
        "COLLECTOR_STREAM_SCAN_URL",
        "COLLECTOR_STREAM_SCAN_TOKEN",
        "COLLECTOR_STREAM_SCAN_WORKSPACE",
      ])
    )
    error_message = "The orchestrator's environment must be exactly the ARM template's."
  }

  assert {
    condition = alltrue([
      for pair in [
        "COLLECTOR_ROLE=orchestrator",
        "COLLECTOR_AZURE_CONTAINER_APP_JOB=streamsec-scanner-worker",
        "COLLECTOR_SHARD_SIZE=100",
        "COLLECTOR_MAX_CONCURRENT_SHARDS=10",
        "COLLECTOR_WORKLOAD_KINDS=containerapps,azurefunctions,appservice,containerinstances",
        "COLLECTOR_STREAM_SCAN_TOKEN=secret:collection-token",
      ] :
      contains([
        for e in azurerm_container_app_job.orchestrator.template[0].container[0].env :
        e.secret_name != null ? "${e.name}=secret:${e.secret_name}" : "${e.name}=${e.value}"
      ], pair)
    ])
    error_message = "The orchestrator must start the worker job, with the default shard size, concurrency and workload kinds."
  }
}

run "scan_options_default_to_the_consoles" {
  command = plan

  assert {
    condition = alltrue([
      for pair in [
        "COLLECTOR_SCAN_LANGUAGE_PACKAGES=true",
        "COLLECTOR_SCAN_DATABASES=false",
        "COLLECTOR_SCAN_AI_WORKLOADS=false",
        "COLLECTOR_SCAN_SECRETS=false",
        "COLLECTOR_SCAN_DATA_VOLUMES=true",
        "COLLECTOR_SCAN_KUBERNETES_VOLUMES=false",
      ] :
      contains([for e in azurerm_container_app_job.worker.template[0].container[0].env : "${e.name}=${coalesce(e.value, "-")}"], pair)
    ])
    error_message = "Scan options must default to the console's: language packages and data volumes on, the rest off."
  }
}

run "scan_options_reach_the_worker" {
  command = plan

  variables {
    scan_language_packages  = false
    scan_databases          = true
    scan_ai_workloads       = true
    scan_secrets            = true
    scan_data_volumes       = false
    scan_kubernetes_volumes = true
    shard_size              = 250
    max_concurrent_shards   = 25
  }

  assert {
    condition = alltrue([
      for pair in [
        "COLLECTOR_SCAN_LANGUAGE_PACKAGES=false",
        "COLLECTOR_SCAN_DATABASES=true",
        "COLLECTOR_SCAN_AI_WORKLOADS=true",
        "COLLECTOR_SCAN_SECRETS=true",
        "COLLECTOR_SCAN_DATA_VOLUMES=false",
        "COLLECTOR_SCAN_KUBERNETES_VOLUMES=true",
      ] :
      contains([for e in azurerm_container_app_job.worker.template[0].container[0].env : "${e.name}=${coalesce(e.value, "-")}"], pair)
    ])
    error_message = "Every scan option must reach the worker's environment."
  }

  assert {
    condition = alltrue([
      for pair in ["COLLECTOR_SHARD_SIZE=250", "COLLECTOR_MAX_CONCURRENT_SHARDS=25"] :
      contains([for e in azurerm_container_app_job.orchestrator.template[0].container[0].env : "${e.name}=${coalesce(e.value, "-")}"], pair)
    ])
    error_message = "shard_size and max_concurrent_shards must reach the orchestrator's environment."
  }

  # The orchestrator hands the worker's environment to every execution it starts.
  assert {
    condition     = length([for e in azurerm_container_app_job.orchestrator.template[0].container[0].env : e if startswith(e.name, "COLLECTOR_SCAN_")]) == 0
    error_message = "Scan options belong on the worker only, as in the ARM template."
  }
}

run "tenant_name_can_be_overridden" {
  command = plan

  variables {
    tenant_name = " other "
  }

  assert {
    condition     = contains([for e in azurerm_container_app_job.worker.template[0].container[0].env : "${e.name}=${coalesce(e.value, "-")}"], "COLLECTOR_TENANT_NAME=other")
    error_message = "tenant_name must replace the derived tenant, trimmed."
  }
}

run "a_non_https_stream_host_is_refused" {
  command = plan

  override_data {
    target = data.streamsec_host.this
    values = { url = "http://acme.streamsec.io" }
  }

  expect_failures = [azurerm_container_app_job.worker]
}

################################################################################
# Roles
################################################################################

run "custom_role_has_the_arm_templates_actions" {
  command = plan

  assert {
    condition = alltrue([
      azurerm_role_definition.scanner.name == "Stream Security Volume Scanner (streamsec-scanner-tf-00000000, 00000000)",
      azurerm_role_definition.scanner.scope == "/subscriptions/00000000-0000-0000-0000-000000000000",
      azurerm_role_definition.scanner.assignable_scopes == tolist(["/subscriptions/00000000-0000-0000-0000-000000000000"]),
      azurerm_role_definition.scanner.permissions[0].actions == tolist([
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
      ]),
    ])
    error_message = "The custom role must carry exactly the ARM template's 19 actions, at subscription scope."
  }

  assert {
    condition = alltrue([
      azurerm_role_assignment.scanner.scope == "/subscriptions/00000000-0000-0000-0000-000000000000",
      azurerm_role_assignment.scanner.principal_type == "ServicePrincipal",
    ])
    error_message = "The custom role must be assigned at subscription scope, to a service principal."
  }
}

run "role_assignments_go_to_the_managed_identity" {
  command = apply

  assert {
    condition = alltrue([
      azurerm_role_assignment.scanner.principal_id == "00000000-0000-0000-0000-000000000002",
      azurerm_role_assignment.scanner.role_definition_id == azurerm_role_definition.scanner.role_definition_resource_id,
      azurerm_role_assignment.acr_pull[0].principal_id == "00000000-0000-0000-0000-000000000002",
      azurerm_role_assignment.function_packages[0].principal_id == "00000000-0000-0000-0000-000000000002",
      azurerm_role_assignment.function_packages[0].role_definition_id == azurerm_role_definition.function_packages[0].role_definition_resource_id,
      azurerm_role_assignment.worker_start.principal_id == "00000000-0000-0000-0000-000000000002",
      azurerm_role_assignment.worker_start.role_definition_id == azurerm_role_definition.worker_start.role_definition_resource_id,
    ])
    error_message = "Every role must be assigned to the scanner's managed identity."
  }
}

run "the_orchestrator_may_override_only_the_worker_job" {
  command = apply

  assert {
    condition = alltrue([
      azurerm_role_definition.worker_start.permissions[0].actions == tolist(["Microsoft.App/jobs/write"]),
      azurerm_role_definition.worker_start.assignable_scopes == tolist(["/subscriptions/00000000-0000-0000-0000-000000000000"]),
      azurerm_role_assignment.worker_start.scope == azurerm_container_app_job.worker.id,
      azurerm_role_assignment.worker_start.principal_type == "ServicePrincipal",
    ])
    error_message = "Starting the worker with a template override needs Microsoft.App/jobs/write, granted on the worker job only."
  }

  assert {
    condition     = !contains(azurerm_role_definition.scanner.permissions[0].actions, "Microsoft.App/jobs/write")
    error_message = "The subscription-wide role must not carry Microsoft.App/jobs/write."
  }
}

run "acr_pull_needs_a_workload_kind" {
  command = plan

  variables {
    workload_kinds = ""
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.acr_pull) == 0,
      length(azurerm_role_definition.function_packages) == 0,
      length(azurerm_role_assignment.function_packages) == 0,
      contains([for e in azurerm_container_app_job.orchestrator.template[0].container[0].env : "${e.name}=${coalesce(e.value, "-")}"], "COLLECTOR_WORKLOAD_KINDS=-"),
    ])
    error_message = "workload_kinds = \"\" must drop AcrPull and the function-package role, and still send an empty COLLECTOR_WORKLOAD_KINDS."
  }
}

run "acr_pull_with_workloads_but_no_functions" {
  command = plan

  variables {
    workload_kinds = "appservice, containerapps"
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.acr_pull) == 1,
      azurerm_role_assignment.acr_pull[0].role_definition_name == "AcrPull",
      azurerm_role_assignment.acr_pull[0].scope == "/subscriptions/00000000-0000-0000-0000-000000000000",
      length(azurerm_role_definition.function_packages) == 0,
      length(azurerm_role_assignment.function_packages) == 0,
    ])
    error_message = "Workload kinds without azurefunctions take AcrPull and no function-package role."
  }

  assert {
    condition     = contains([for e in azurerm_container_app_job.orchestrator.template[0].container[0].env : "${e.name}=${coalesce(e.value, "-")}"], "COLLECTOR_WORKLOAD_KINDS=appservice,containerapps")
    error_message = "COLLECTOR_WORKLOAD_KINDS must be the trimmed list."
  }
}

run "azurefunctions_alone_takes_the_blob_read_role" {
  command = plan

  variables {
    workload_kinds = "azurefunctions"
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.acr_pull) == 1,
      length(azurerm_role_definition.function_packages) == 1,
      azurerm_role_definition.function_packages[0].name == "Stream Security Volume Scanner function packages (streamsec-scanner-tf-00000000, 00000000)",
      azurerm_role_definition.function_packages[0].permissions[0].data_actions == toset(["Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"]),
      try(length(azurerm_role_definition.function_packages[0].permissions[0].actions), 0) == 0,
      azurerm_role_definition.function_packages[0].assignable_scopes == tolist(["/subscriptions/00000000-0000-0000-0000-000000000000"]),
    ])
    error_message = "azurefunctions must add the blob-read custom role, with only the blob read data action."
  }

  assert {
    condition = alltrue([
      azurerm_role_assignment.function_packages[0].condition_version == "2.0",
      azurerm_role_assignment.function_packages[0].condition == "((!(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'})) OR (@Resource[Microsoft.Storage/storageAccounts/blobServices/containers/blobs:path] StringEquals 'released-package.zip'))",
      azurerm_role_assignment.function_packages[0].scope == "/subscriptions/00000000-0000-0000-0000-000000000000",
      azurerm_role_assignment.function_packages[0].principal_type == "ServicePrincipal",
    ])
    error_message = "The blob read must be limited to released-package.zip by the ARM template's exact condition."
  }
}

################################################################################
# Initial scan
################################################################################

run "initial_scan_starts_the_orchestrator" {
  command = apply

  assert {
    condition = alltrue([
      length(azapi_resource_action.initial_scan) == 1,
      azapi_resource_action.initial_scan[0].type == "Microsoft.App/jobs@2024-03-01",
      azapi_resource_action.initial_scan[0].action == "start",
      azapi_resource_action.initial_scan[0].method == "POST",
      azapi_resource_action.initial_scan[0].resource_id == azurerm_container_app_job.orchestrator.id,
    ])
    error_message = "The initial scan must POST start to the orchestrator job, API version 2024-03-01."
  }
}

run "initial_scan_can_be_disabled" {
  command = plan

  variables {
    trigger_initial_scan = false
  }

  assert {
    condition     = length(azapi_resource_action.initial_scan) == 0
    error_message = "trigger_initial_scan = false must drop the start action."
  }
}

################################################################################
# Coexistence guard
################################################################################

run "refuses_to_deploy_alongside_the_arm_scanner" {
  command = plan

  override_data {
    target = data.azurerm_resources.scanner_jobs
    values = {
      resources = [{
        id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/streamsec-scanner-00000000/providers/Microsoft.App/jobs/streamsec-scanner-orchestrator"
        name                = "streamsec-scanner-orchestrator"
        resource_group_name = "streamsec-scanner-00000000"
        type                = "Microsoft.App/jobs"
        location            = "eastus"
        tags                = {}
      }]
    }
  }

  expect_failures = [azurerm_resource_group.this]
}

run "an_arm_scanner_in_a_renamed_group_is_found_too" {
  command = plan

  override_data {
    target = data.azurerm_resources.scanner_jobs
    values = {
      resources = [{
        id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-scanner/providers/Microsoft.App/jobs/STREAMSEC-SCANNER-ORCHESTRATOR"
        name                = "STREAMSEC-SCANNER-ORCHESTRATOR"
        resource_group_name = "rg-scanner"
        type                = "Microsoft.App/jobs"
        location            = "eastus"
        tags                = {}
      }]
    }
  }

  expect_failures = [azurerm_resource_group.this]
}

run "coexistence_can_be_opted_into" {
  command = plan

  variables {
    allow_arm_coexistence = true
  }

  override_data {
    target = data.azurerm_resources.scanner_jobs
    values = {
      resources = [{
        id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/streamsec-scanner-00000000/providers/Microsoft.App/jobs/streamsec-scanner-orchestrator"
        name                = "streamsec-scanner-orchestrator"
        resource_group_name = "streamsec-scanner-00000000"
        type                = "Microsoft.App/jobs"
        location            = "eastus"
        tags                = {}
      }]
    }
  }

  assert {
    condition     = azurerm_resource_group.this.name == "streamsec-scanner-tf-00000000"
    error_message = "allow_arm_coexistence must permit the deploy."
  }

  assert {
    condition     = length(data.azurerm_resources.scanner_jobs) == 0
    error_message = "With the guard off the subscription's jobs are not listed at all."
  }
}

# A later ARM install must not lock an existing Terraform install out of its own
# re-applies.
run "an_existing_install_is_not_locked_out_by_a_later_arm_scanner" {
  command = plan

  override_data {
    target = data.azurerm_resources.scanner_jobs
    values = {
      resources = [
        {
          id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/streamsec-scanner-00000000/providers/Microsoft.App/jobs/streamsec-scanner-orchestrator"
          name                = "streamsec-scanner-orchestrator"
          resource_group_name = "streamsec-scanner-00000000"
          type                = "Microsoft.App/jobs"
          location            = "eastus"
          tags                = {}
        },
        {
          id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/STREAMSEC-SCANNER-TF-00000000/providers/Microsoft.App/jobs/streamsec-scanner-orchestrator"
          name                = "streamsec-scanner-orchestrator"
          resource_group_name = "STREAMSEC-SCANNER-TF-00000000"
          type                = "Microsoft.App/jobs"
          location            = "eastus"
          tags                = {}
        },
      ]
    }
  }

  assert {
    condition     = azurerm_resource_group.this.name == "streamsec-scanner-tf-00000000"
    error_message = "With this module's own orchestrator present the plan must succeed, even alongside the ARM scanner."
  }
}

run "a_second_terraform_scanner_trips_the_guard" {
  command = plan

  override_data {
    target = data.azurerm_resources.scanner_jobs
    values = {
      resources = [{
        id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/streamsec-scanner-tf-other/providers/Microsoft.App/jobs/streamsec-scanner-orchestrator"
        name                = "streamsec-scanner-orchestrator"
        resource_group_name = "streamsec-scanner-tf-other"
        type                = "Microsoft.App/jobs"
        location            = "eastus"
        tags                = { "streamsec:component" = "azure-volume-scanner" }
      }]
    }
  }

  expect_failures = [azurerm_resource_group.this]
}

run "unrelated_jobs_do_not_trip_the_guard" {
  command = plan

  override_data {
    target = data.azurerm_resources.scanner_jobs
    values = {
      resources = [{
        id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/apps/providers/Microsoft.App/jobs/nightly-report"
        name                = "nightly-report"
        resource_group_name = "apps"
        type                = "Microsoft.App/jobs"
        location            = "eastus"
        tags                = {}
      }]
    }
  }

  assert {
    condition     = azurerm_resource_group.this.name == "streamsec-scanner-tf-00000000"
    error_message = "Only a job named streamsec-scanner-orchestrator is another scanner."
  }
}

################################################################################
# Input validation
################################################################################

run "shard_size_below_one_is_rejected" {
  command = plan

  variables {
    shard_size = 0
  }

  expect_failures = [var.shard_size]
}

run "shard_size_above_5000_is_rejected" {
  command = plan

  variables {
    shard_size = 5001
  }

  expect_failures = [var.shard_size]
}

run "fractional_shard_size_is_rejected" {
  command = plan

  variables {
    shard_size = 10.5
  }

  expect_failures = [var.shard_size]
}

run "max_concurrent_shards_below_one_is_rejected" {
  command = plan

  variables {
    max_concurrent_shards = 0
  }

  expect_failures = [var.max_concurrent_shards]
}

run "max_concurrent_shards_above_100_is_rejected" {
  command = plan

  variables {
    max_concurrent_shards = 101
  }

  expect_failures = [var.max_concurrent_shards]
}

run "shard_bounds_are_accepted" {
  command = plan

  variables {
    shard_size            = 5000
    max_concurrent_shards = 100
  }

  assert {
    condition     = contains([for e in azurerm_container_app_job.orchestrator.template[0].container[0].env : "${e.name}=${coalesce(e.value, "-")}"], "COLLECTOR_SHARD_SIZE=5000")
    error_message = "The upper bounds themselves must be accepted."
  }
}

run "unknown_network_mode_is_rejected" {
  command = plan

  variables {
    network_mode = "peered"
  }

  expect_failures = [var.network_mode]
}

run "unknown_workload_kind_is_rejected" {
  command = plan

  variables {
    workload_kinds = "containerapps,lambda"
  }

  expect_failures = [var.workload_kinds]
}

run "whitespace_only_workload_kinds_is_rejected" {
  command = plan

  variables {
    workload_kinds = " , "
  }

  expect_failures = [var.workload_kinds]
}

run "four_field_cron_is_rejected" {
  command = plan

  variables {
    schedule_cron_expression = "0 3 * *"
  }

  expect_failures = [var.schedule_cron_expression]
}

run "azure_tenant_id_as_account_id_is_rejected" {
  command = plan

  variables {
    account_id = "00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [var.account_id]
}

run "blank_customer_id_is_rejected" {
  command = plan

  variables {
    customer_id = "  "
  }

  expect_failures = [var.customer_id]
}

run "blank_tenant_name_is_rejected" {
  command = plan

  variables {
    tenant_name = " "
  }

  expect_failures = [var.tenant_name]
}

run "invalid_resource_group_name_is_rejected" {
  command = plan

  variables {
    resource_group_name = "scanner."
  }

  expect_failures = [var.resource_group_name]
}
