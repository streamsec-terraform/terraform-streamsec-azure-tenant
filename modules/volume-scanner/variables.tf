################################################################################
# Stream Security
################################################################################

variable "account_id" {
  description = "Stream Security id of the Azure tenant, not the Azure tenant id: the root module's account_id output, or the id of a streamsec_azure_tenant resource or data source. The tenant must be acknowledged before this module can read the scanner's collection token."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9a-f]{24}$", var.account_id))
    error_message = "account_id must be the Stream Security id of the tenant (24 lowercase hexadecimal characters), such as the root module's account_id output, not the Azure tenant id."
  }
}

variable "customer_id" {
  description = "Stream Security workspace id, the same value as the streamsec provider's workspace_id. A wrong value is silent: findings are dropped and the scanner still looks healthy."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.customer_id) != ""
    error_message = "customer_id must not be blank: set it to the streamsec provider's workspace_id."
  }
}

variable "tenant_name" {
  description = "Stream Security tenant name. Defaults to the first DNS label of the provider host; set it explicitly behind a shared endpoint or a custom DNS name."
  type        = string
  default     = null

  validation {
    condition     = var.tenant_name == null ? true : trimspace(var.tenant_name) != ""
    error_message = "tenant_name must not be blank. Leave it unset to derive the tenant from the provider host."
  }
}

################################################################################
# What the console's ARM template asks for. The subscription is the azurerm
# provider's.
################################################################################

variable "location" {
  description = "Azure region for all of the scanner's resources, such as \"eastus\". The scanner covers every region of the subscription regardless."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.location) != ""
    error_message = "location must not be blank."
  }
}

variable "resource_group_name" {
  description = "Resource group to create for the scanner. Defaults to streamsec-scanner-tf- and the first 8 characters of the subscription id, apart from the console's streamsec-scanner- with the same suffix."
  type        = string
  default     = null

  validation {
    condition     = var.resource_group_name == null ? true : can(regex("^[\\p{L}\\p{N}_.()-]{1,90}$", var.resource_group_name)) && !endswith(var.resource_group_name, ".")
    error_message = "resource_group_name must be 1-90 letters, digits, underscores, periods, parentheses and hyphens, and must not end with a period."
  }
}

variable "scanner_image" {
  description = "Container image of the scanner. Pin a release tag to control upgrades; :latest follows every release."
  type        = string
  default     = "public.ecr.aws/stream-security/volume-scanner:latest"
  nullable    = false

  validation {
    condition     = trimspace(var.scanner_image) != ""
    error_message = "scanner_image must not be blank."
  }
}

variable "network_mode" {
  description = "\"create_new\" creates a VNet with a NAT gateway for the scanner. \"use_existing\" runs it in existing_subnet_id instead."
  type        = string
  default     = "create_new"
  nullable    = false

  validation {
    condition     = contains(["create_new", "use_existing"], var.network_mode)
    error_message = "network_mode must be \"create_new\" or \"use_existing\"."
  }
}

variable "existing_subnet_id" {
  description = "Resource id of the subnet to run the scanner in, required when network_mode is \"use_existing\" and ignored otherwise. It must be delegated to Microsoft.App/environments, be /27 or larger, and have outbound internet access."
  type        = string
  default     = null

  validation {
    condition     = var.existing_subnet_id == null ? true : trimspace(var.existing_subnet_id) != ""
    error_message = "existing_subnet_id must not be blank. Leave it unset with network_mode = \"create_new\"."
  }
}

variable "shard_size" {
  description = "VMs per worker execution. Lower means more executions in parallel; higher means fewer, longer ones."
  type        = number
  default     = 100
  nullable    = false

  validation {
    condition     = var.shard_size >= 1 && var.shard_size <= 5000 && floor(var.shard_size) == var.shard_size
    error_message = "shard_size must be a whole number between 1 and 5000."
  }
}

variable "max_concurrent_shards" {
  description = "Maximum number of worker executions in flight at once."
  type        = number
  default     = 10
  nullable    = false

  validation {
    condition     = var.max_concurrent_shards >= 1 && var.max_concurrent_shards <= 100 && floor(var.max_concurrent_shards) == var.max_concurrent_shards
    error_message = "max_concurrent_shards must be a whole number between 1 and 100."
  }
}

variable "workload_kinds" {
  description = "Workloads to scan besides VMs, comma-separated: containerapps, azurefunctions, appservice, containerinstances. \"\" scans VMs only. Also gates the AcrPull and function-package role assignments."
  type        = string
  default     = "containerapps,azurefunctions,appservice,containerinstances"
  nullable    = false

  # Normalized before checking, so "appservice, containerapps" is accepted. "" disables workload
  # scanning deliberately; "  " or "," would disable it silently, dropping the role assignments.
  validation {
    condition = length(setsubtract(
      toset([for kind in split(",", var.workload_kinds) : trimspace(kind) if trimspace(kind) != ""]),
      toset(["containerapps", "azurefunctions", "appservice", "containerinstances"])
      )) == 0 && (
      var.workload_kinds == "" ||
      length([for kind in split(",", var.workload_kinds) : kind if trimspace(kind) != ""]) > 0
    )
    error_message = "workload_kinds must be a comma-separated subset of containerapps, azurefunctions, appservice and containerinstances, or exactly \"\" to scan VMs only."
  }
}

variable "scan_language_packages" {
  description = "Detect language-level packages on disk (Python, Node, Ruby, Go, Rust, Java)."
  type        = bool
  default     = true
  nullable    = false
}

variable "scan_databases" {
  description = "Detect installed databases from their on-disk signatures. Adds a filesystem walk per VM."
  type        = bool
  default     = false
  nullable    = false
}

variable "scan_ai_workloads" {
  description = "Detect AI/ML framework installs and surface them as workload metadata."
  type        = bool
  default     = false
  nullable    = false
}

variable "scan_secrets" {
  description = "Detect secrets and credentials on disk. Significantly increases scan duration."
  type        = bool
  default     = false
  nullable    = false
}

variable "scan_data_volumes" {
  description = "Also snapshot and scan the data disks attached to a VM, not only its OS disk."
  type        = bool
  default     = true
  nullable    = false
}

variable "scan_kubernetes_volumes" {
  description = "Also scan the data disks a Kubernetes CSI driver created for pod volume claims, which the data disk scan otherwise skips."
  type        = bool
  default     = false
  nullable    = false
}

################################################################################
# Terraform only: the console has no equivalent.
################################################################################

variable "schedule_cron_expression" {
  description = "When the orchestrator runs, as a five-field cron expression in UTC. Daily at 03:00 by default."
  type        = string
  default     = "0 3 * * *"
  nullable    = false

  validation {
    condition     = length(compact(split(" ", trimspace(var.schedule_cron_expression)))) == 5
    error_message = "schedule_cron_expression must be a five-field cron expression (minute hour day-of-month month day-of-week), such as \"0 3 * * *\"."
  }
}

variable "trigger_initial_scan" {
  description = "Start one scan at the end of the apply that creates the scanner, instead of waiting for the schedule."
  type        = bool
  default     = true
  nullable    = false
}

variable "allow_arm_coexistence" {
  description = "Allow deploying alongside another scanner in the same subscription, such as the console's ARM deployment. Off by default: two scanners scan every VM twice and delete each other's snapshots."
  type        = bool
  default     = false
  nullable    = false
}

variable "tags" {
  description = "Tags to add to every resource the module creates."
  type        = map(string)
  default     = {}
  nullable    = false
}
