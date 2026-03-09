output "eventhub_namespaces" {
  description = "Map of region key to Event Hub namespace details."
  value = {
    for key, rt in module.real_time : key => {
      eventhub_namespace_name                  = rt.eventhub_namespace_name
      eventhub_namespace_id                    = rt.eventhub_namespace_id
      eventhub_name                            = rt.eventhub_name
      eventhub_namespace_authorization_rule_id = rt.eventhub_namespace_authorization_rule_id
      resource_group_name                      = rt.resource_group_name
      location                                 = rt.resource_group_location
    }
  }
}
