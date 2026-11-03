################################################################################
# Stream Security
################################################################################

variable "account_id" {
  description = "The Stream Security ID of the Azure tenant, such as the root module's `account_id` output. The tenant must be acknowledged first."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9a-f]{24}$", var.account_id))
    error_message = "account_id must be the Stream Security id of the tenant (24 lowercase hexadecimal characters), such as the root module's account_id output, not the Azure tenant id."
  }
}

variable "customer_id" {
  description = "The Stream Security workspace ID, the same as the streamsec provider's `workspace_id`."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.customer_id) != ""
    error_message = "customer_id must not be blank: set it to the streamsec provider's workspace_id."
  }
}

variable "tenant_name" {
  description = "The Stream Security tenant name. Defaults to the first label of the streamsec provider host."
  type        = string
  default     = null

  validation {
    condition     = var.tenant_name == null ? true : trimspace(var.tenant_name) != ""
    error_message = "tenant_name must not be blank. Leave it unset to derive the tenant from the provider host."
  }
}

################################################################################
# Scanner
################################################################################

variable "location" {
  description = "The location to create the scanner resources in. The scanner covers every location of the subscription."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.location) != ""
    error_message = "location must not be blank."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group to create for the scanner. Defaults to `streamsec-scanner-tf-` followed by the first 8 characters of the subscription ID."
  type        = string
  default     = null

  validation {
    condition     = var.resource_group_name == null ? true : can(regex("^[\\p{L}\\p{N}_.()-]{1,90}$", var.resource_group_name)) && !endswith(var.resource_group_name, ".")
    error_message = "resource_group_name must be 1-90 letters, digits, underscores, periods, parentheses and hyphens, and must not end with a period."
  }
}

variable "scanner_image" {
  description = "The scanner container image. Pin a release tag to control upgrades."
  type        = string
  default     = "public.ecr.aws/stream-security/volume-scanner:latest"
  nullable    = false

  validation {
    condition     = trimspace(var.scanner_image) != ""
    error_message = "scanner_image must not be blank."
  }
}

variable "network_mode" {
  description = "Whether to create a new VNet with a NAT gateway for the scanner (`create_new`) or to use an existing subnet (`use_existing`)."
  type        = string
  default     = "create_new"
  nullable    = false

  validation {
    condition     = contains(["create_new", "use_existing"], var.network_mode)
    error_message = "network_mode must be \"create_new\" or \"use_existing\"."
  }
}

variable "existing_subnet_id" {
  description = "The ID of an existing subnet to run the scanner in. Only used if `network_mode` is `use_existing`. The subnet must be delegated to Microsoft.App/environments, be /27 or larger and have outbound internet access."
  type        = string
  default     = null

  validation {
    condition     = var.existing_subnet_id == null ? true : trimspace(var.existing_subnet_id) != ""
    error_message = "existing_subnet_id must not be blank. Leave it unset with network_mode = \"create_new\"."
  }
}

variable "shard_size" {
  description = "The number of VMs each worker execution scans."
  type        = number
  default     = 100
  nullable    = false

  validation {
    condition     = var.shard_size >= 1 && var.shard_size <= 5000 && floor(var.shard_size) == var.shard_size
    error_message = "shard_size must be a whole number between 1 and 5000."
  }
}

variable "max_concurrent_shards" {
  description = "The maximum number of worker executions running at once."
  type        = number
  default     = 10
  nullable    = false

  validation {
    condition     = var.max_concurrent_shards >= 1 && var.max_concurrent_shards <= 100 && floor(var.max_concurrent_shards) == var.max_concurrent_shards
    error_message = "max_concurrent_shards must be a whole number between 1 and 100."
  }
}

variable "workload_kinds" {
  description = "Comma-separated workloads to scan besides VMs: containerapps, azurefunctions, appservice, containerinstances. Set to an empty string to scan VMs only."
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
    error_message = "workload_kinds must be a comma-separated subset of containerapps, azurefunctions, appservice and containerinstances, or exactly \"\" to scan VMs only."
  }
}

variable "scan_language_packages" {
  description = "Whether to scan language packages (Python, Node, Ruby, Go, Rust, Java)."
  type        = bool
  default     = true
  nullable    = false
}

variable "scan_databases" {
  description = "Whether to detect installed databases."
  type        = bool
  default     = false
  nullable    = false
}

variable "scan_ai_workloads" {
  description = "Whether to detect AI/ML frameworks."
  type        = bool
  default     = false
  nullable    = false
}

variable "scan_secrets" {
  description = "Whether to scan for secrets on disk. Increases scan duration."
  type        = bool
  default     = false
  nullable    = false
}

variable "scan_data_volumes" {
  description = "Whether to scan VM data disks in addition to OS disks."
  type        = bool
  default     = true
  nullable    = false
}

variable "scan_kubernetes_volumes" {
  description = "Whether to scan disks created for Kubernetes persistent volume claims. Only used if `scan_data_volumes` is true."
  type        = bool
  default     = false
  nullable    = false
}

################################################################################
# Schedule and Coexistence
################################################################################

variable "schedule_cron_expression" {
  description = "The scan schedule, as a cron expression in UTC."
  type        = string
  default     = "0 3 * * *"
  nullable    = false

  validation {
    condition     = length(compact(split(" ", trimspace(var.schedule_cron_expression)))) == 5
    error_message = "schedule_cron_expression must be a five-field cron expression (minute hour day-of-month month day-of-week), such as \"0 3 * * *\"."
  }
}

variable "trigger_initial_scan" {
  description = "Whether to start a scan right after the scanner is created."
  type        = bool
  default     = true
  nullable    = false
}

variable "allow_arm_coexistence" {
  description = "Whether to allow deploying when another scanner exists in the subscription, such as the console's ARM deployment. Two scanners in one subscription interfere with each other."
  type        = bool
  default     = false
  nullable    = false
}

variable "tags" {
  description = "The tags to apply to the scanner resources."
  type        = map(string)
  default     = {}
  nullable    = false
}
