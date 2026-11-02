data "azurerm_subscription" "current" {}

data "streamsec_host" "this" {}

# Refused (409) until the tenant is acknowledged in Stream Security.
data "streamsec_azure_volume_scanner" "this" {
  account_id      = var.account_id
  subscription_id = local.subscription_id
}

# Plural: an empty list instead of an error on a miss; count waives the read when the guard is off.
data "azurerm_resources" "scanner_jobs" {
  count = var.allow_arm_coexistence ? 0 : 1

  type = "Microsoft.App/jobs"
}

locals {
  # Reported to Stream Security by the install acknowledgement. Bump it with each release tag.
  module_version = "1.6.0"

  subscription_id    = lower(data.azurerm_subscription.current.subscription_id)
  subscription_scope = "/subscriptions/${local.subscription_id}"

  # The "-tf" marker keeps the group apart from the console's ARM deployment,
  # which creates streamsec-scanner-<first 8 characters of the subscription id>.
  resource_group_name = var.resource_group_name != null ? var.resource_group_name : "streamsec-scanner-tf-${substr(local.subscription_id, 0, 8)}"

  # The console's ARM template names, kept: they are scoped to the resource group.
  managed_identity_name  = "streamsec-scanner-mi"
  log_workspace_name     = "streamsec-scanner-logs"
  container_env_name     = "streamsec-scanner-env"
  orchestrator_job_name  = "streamsec-scanner-orchestrator"
  worker_job_name        = "streamsec-scanner-worker"
  collection_token_name  = "collection-token"
  workload_profile_name  = "Consumption"
  scanner_container_name = "scanner" # the orchestrator overrides the worker's container by this name

  # Every Container Apps job in the subscription; empty when the guard is off.
  scanner_jobs      = flatten(data.azurerm_resources.scanner_jobs[*].resources)
  orchestrator_jobs = [for job in local.scanner_jobs : job if lower(job.name) == local.orchestrator_job_name]

  # Maintenance apply or destroy: this module's own orchestrator never trips the guard.
  already_installed = anytrue([
    for job in local.orchestrator_jobs : lower(job.resource_group_name) == lower(local.resource_group_name)
  ])

  other_scanner_groups = distinct([
    for job in local.orchestrator_jobs : job.resource_group_name
    if lower(job.resource_group_name) != lower(local.resource_group_name)
  ])

  arm_coexistence_ok = var.allow_arm_coexistence || local.already_installed || length(local.other_scanner_groups) == 0

  arm_coexistence_error = <<-EOT
    Another Stream Security volume scanner is already installed in subscription ${local.subscription_id}: the Container Apps job "${local.orchestrator_job_name}" in resource group ${join(", ", local.other_scanner_groups)}, from the console's ARM template or another instance of this module. Both scan every VM and delete each other's snapshots.
    Remove that deployment, then apply. To run both deliberately, set allow_arm_coexistence = true. After a resource_group_name change the group above is this module's previous one, which this name-based guard cannot tell apart: set the flag for that one apply, then unset it.
  EOT

  api_url = trimsuffix(data.streamsec_host.this.url, "/")

  # First DNS label of a per-tenant host is the tenant; untrue behind a shared endpoint.
  derived_tenant_name = split(".", replace(replace(local.api_url, "https://", ""), "http://", ""))[0]
  tenant_name         = var.tenant_name != null ? trimspace(var.tenant_name) : local.derived_tenant_name

  stream_scan_url = "${local.api_url}/openapi/vulnerabilities/stream_scan/raw"

  customer_id = trimspace(var.customer_id)

  # Normalized, not raw: the scanner's comma split would otherwise see " appservice".
  workload_kind_list     = [for kind in split(",", var.workload_kinds) : trimspace(kind) if trimspace(kind) != ""]
  scan_workloads         = length(local.workload_kind_list) > 0
  scan_function_packages = contains(local.workload_kind_list, "azurefunctions")

  tags = merge(var.tags, {
    "streamsec:component" = "azure-volume-scanner"
    "streamsec:customer"  = local.customer_id
  })

  # Shared by both jobs. The collection token is added separately, as a secret reference.
  common_env = [
    { name = "COLLECTOR_PROVIDER", value = "azure" },
    { name = "AZURE_CLIENT_ID", value = azurerm_user_assigned_identity.this.client_id },
    { name = "COLLECTOR_AZURE_SUBSCRIPTION_ID", value = local.subscription_id },
    { name = "COLLECTOR_AZURE_RESOURCE_GROUP", value = azurerm_resource_group.this.name },
    { name = "COLLECTOR_TENANT_NAME", value = local.tenant_name },
    { name = "COLLECTOR_CUSTOMER_ID", value = local.customer_id },
    { name = "COLLECTOR_STREAM_SCAN_URL", value = local.stream_scan_url },
    { name = "COLLECTOR_STREAM_SCAN_WORKSPACE", value = local.customer_id },
  ]

  # The orchestrator starts every worker execution with this environment, so the
  # scan options live here and not on the orchestrator.
  worker_env = concat(local.common_env, [
    { name = "COLLECTOR_ROLE", value = "worker" },
    { name = "COLLECTOR_CONCURRENCY", value = "5" },
    { name = "COLLECTOR_SCAN_LANGUAGE_PACKAGES", value = tostring(var.scan_language_packages) },
    { name = "COLLECTOR_SCAN_DATABASES", value = tostring(var.scan_databases) },
    { name = "COLLECTOR_SCAN_AI_WORKLOADS", value = tostring(var.scan_ai_workloads) },
    { name = "COLLECTOR_SCAN_SECRETS", value = tostring(var.scan_secrets) },
    { name = "COLLECTOR_SCAN_DATA_VOLUMES", value = tostring(var.scan_data_volumes) },
    { name = "COLLECTOR_SCAN_KUBERNETES_VOLUMES", value = tostring(var.scan_kubernetes_volumes) },
  ])

  orchestrator_env = concat(local.common_env, [
    { name = "COLLECTOR_ROLE", value = "orchestrator" },
    { name = "COLLECTOR_AZURE_CONTAINER_APP_JOB", value = azurerm_container_app_job.worker.name },
    { name = "COLLECTOR_SHARD_SIZE", value = tostring(var.shard_size) },
    { name = "COLLECTOR_MAX_CONCURRENT_SHARDS", value = tostring(var.max_concurrent_shards) },
    # Set even when empty: an empty value turns workload scanning off, an unset one leaves it on.
    { name = "COLLECTOR_WORKLOAD_KINDS", value = join(",", local.workload_kind_list) },
  ])
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location

  tags = local.tags

  lifecycle {
    # Every other resource, the roles included, references this group, so this one guard covers them.
    precondition {
      condition     = local.arm_coexistence_ok
      error_message = local.arm_coexistence_error
    }
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.log_workspace_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.tags
}

resource "azurerm_user_assigned_identity" "this" {
  name                = local.managed_identity_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = local.tags
}

resource "azurerm_container_app_environment" "this" {
  name                           = local.container_env_name
  location                       = azurerm_resource_group.this.location
  resource_group_name            = azurerm_resource_group.this.name
  logs_destination               = "log-analytics"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.this.id
  infrastructure_subnet_id       = local.subnet_id
  internal_load_balancer_enabled = false

  # A subnet delegated to Microsoft.App/environments takes a workload profiles environment.
  # Declared, so the profile Azure adds is not planned away on every apply.
  workload_profile {
    name                  = local.workload_profile_name
    workload_profile_type = local.workload_profile_name
  }

  tags = local.tags

  lifecycle {
    precondition {
      condition     = var.network_mode != "use_existing" || var.existing_subnet_id != null
      error_message = "network_mode = \"use_existing\" needs existing_subnet_id: the resource id of a subnet delegated to Microsoft.App/environments, with outbound internet access."
    }
  }
}

# Started by the orchestrator, once per shard of VMs and once for the workloads.
resource "azurerm_container_app_job" "worker" {
  name                         = local.worker_job_name
  location                     = azurerm_resource_group.this.location
  resource_group_name          = azurerm_resource_group.this.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  workload_profile_name        = local.workload_profile_name
  replica_timeout_in_seconds   = 7200
  replica_retry_limit          = 0

  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  secret {
    name  = local.collection_token_name
    value = data.streamsec_azure_volume_scanner.this.collection_token
  }

  template {
    container {
      name   = local.scanner_container_name
      image  = var.scanner_image
      cpu    = 4
      memory = "8Gi"

      dynamic "env" {
        for_each = local.worker_env
        content {
          name  = env.value.name
          value = env.value.value
        }
      }

      env {
        name        = "COLLECTOR_STREAM_SCAN_TOKEN"
        secret_name = local.collection_token_name
      }
    }
  }

  tags = local.tags

  lifecycle {
    # The configuration checks live on the worker: the orchestrator depends on it.

    # Nothing else constrains the scheme: derived_tenant_name strips http:// as well.
    precondition {
      condition     = startswith(local.api_url, "https://")
      error_message = "The Stream Security host resolved to \"${local.api_url}\", which is not https. The scanner sends its collection token and findings there; set the streamsec provider host to an https URL."
    }

    precondition {
      condition     = local.tenant_name != ""
      error_message = "tenant_name resolved to an empty string, which tags every finding with a tenant that does not exist. Leave it unset to derive the tenant from the provider host, or set your tenant name."
    }
  }
}

# Runs on the schedule and for the initial scan: finds the VMs and workloads, and starts the workers.
resource "azurerm_container_app_job" "orchestrator" {
  name                         = local.orchestrator_job_name
  location                     = azurerm_resource_group.this.location
  resource_group_name          = azurerm_resource_group.this.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  workload_profile_name        = local.workload_profile_name
  replica_timeout_in_seconds   = 21600
  replica_retry_limit          = 0

  schedule_trigger_config {
    cron_expression          = var.schedule_cron_expression
    parallelism              = 1
    replica_completion_count = 1
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  secret {
    name  = local.collection_token_name
    value = data.streamsec_azure_volume_scanner.this.collection_token
  }

  template {
    container {
      name   = local.scanner_container_name
      image  = var.scanner_image
      cpu    = 2
      memory = "4Gi"

      dynamic "env" {
        for_each = local.orchestrator_env
        content {
          name  = env.value.name
          value = env.value.value
        }
      }

      env {
        name        = "COLLECTOR_STREAM_SCAN_TOKEN"
        secret_name = local.collection_token_name
      }
    }
  }

  tags = local.tags
}

# Tells Stream Security the scanner is installed in this subscription, and on destroy that it
# is gone. After the jobs and their roles, so it is created last and destroyed first.
resource "streamsec_azure_volume_scanner_ack" "this" {
  account_id      = var.account_id
  subscription_id = local.subscription_id
  module_version  = local.module_version
  resource_group  = azurerm_resource_group.this.name

  depends_on = [
    azurerm_container_app_job.worker,
    azurerm_container_app_job.orchestrator,
    azurerm_role_assignment.scanner,
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.function_packages,
  ]
}

# One immediate scan at apply time; the schedule runs the next ones. Fires once: the
# orchestrator's id does not change on update.
resource "azapi_resource_action" "initial_scan" {
  count = var.trigger_initial_scan ? 1 : 0

  type        = "Microsoft.App/jobs@2024-03-01"
  resource_id = azurerm_container_app_job.orchestrator.id
  action      = "start"
  method      = "POST"

  # Last: the scan needs its roles, and reports to an install Stream Security knows of.
  depends_on = [streamsec_azure_volume_scanner_ack.this]
}
