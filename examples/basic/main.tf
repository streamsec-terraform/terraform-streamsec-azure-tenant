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
