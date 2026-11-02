provider "azurerm" {
  features {}
}

provider "streamsec" {
  host         = "xxxxx.streamsec.io"
  username     = "xxxxx@example.com"
  password     = "xxxxxxxxxxxx"
  workspace_id = "xxxxxxxxxxxx"
}


module "tenant" {
  source        = "../../"
  display_name  = "test"
  subscriptions = ["xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]
}

module "real_time" {
  source        = "../../modules/real-time-events"
  subscriptions = ["xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]
  depends_on    = [module.tenant]
}

module "flowlogs" {
  source                              = "../../modules/flowlogs"
  storage_account_name                = "xxxxxxx"
  storage_account_resource_group_name = "xxxxxx"
  network_traffic_container_name      = "insights-logs-flowlogflowevent"
  depends_on                          = [module.tenant]
}

# Agentless vulnerability scanning of the azurerm provider's subscription. customer_id
# is the streamsec provider's workspace_id. Remove the console's ARM deployment of the
# scanner from the subscription first; the module refuses to apply alongside it.
module "volume_scanner" {
  source      = "../../modules/volume-scanner"
  account_id  = module.tenant.account_id
  customer_id = "xxxxxxxxxxxx"
  location    = "eastus"

  # Optional scans: language packages and data disks are on by default.
  # scan_secrets            = true
  # scan_ai_workloads       = true
  # scan_databases          = true
  # scan_kubernetes_volumes = true

  # Run in your own subnet instead of a dedicated VNet with a NAT gateway.
  # network_mode       = "use_existing"
  # existing_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/shared/subnets/scanner"
}
