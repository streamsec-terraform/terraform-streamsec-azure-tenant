# Well-formed resource ids: the azurerm provider still validates the arguments they feed.

mock_data "azurerm_subscription" {
  defaults = {
    id              = "/subscriptions/00000000-0000-0000-0000-000000000000"
    subscription_id = "00000000-0000-0000-0000-000000000000"
  }
}

# No other scanner in the subscription unless a run overrides this.
mock_data "azurerm_resources" {
  defaults = { resources = [] }
}

mock_resource "azurerm_resource_group" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/streamsec-scanner-tf-00000000"
  }
}

mock_resource "azurerm_log_analytics_workspace" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/streamsec-scanner-tf-00000000/providers/Microsoft.OperationalInsights/workspaces/streamsec-scanner-logs"
  }
}

mock_resource "azurerm_user_assigned_identity" {
  defaults = {
    id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/streamsec-scanner-tf-00000000/providers/Microsoft.ManagedIdentity/userAssignedIdentities/streamsec-scanner-mi"
    client_id    = "00000000-0000-0000-0000-000000000001"
    principal_id = "00000000-0000-0000-0000-000000000002"
    tenant_id    = "00000000-0000-0000-0000-000000000000"
  }
}

mock_resource "azurerm_container_app_environment" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/streamsec-scanner-tf-00000000/providers/Microsoft.App/managedEnvironments/streamsec-scanner-env"
  }
}

mock_resource "azurerm_container_app_job" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/streamsec-scanner-tf-00000000/providers/Microsoft.App/jobs/streamsec-scanner-orchestrator"
  }
}

mock_resource "azurerm_role_definition" {
  defaults = {
    role_definition_id          = "00000000-0000-0000-0000-000000000003"
    role_definition_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000003"
  }
}

mock_resource "azurerm_public_ip" {
  defaults = {
    id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/streamsec-scanner-tf-00000000/providers/Microsoft.Network/publicIPAddresses/streamsec-scanner-nat-pip"
    ip_address = "192.0.2.10"
  }
}

mock_resource "azurerm_nat_gateway" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/streamsec-scanner-tf-00000000/providers/Microsoft.Network/natGateways/streamsec-scanner-nat"
  }
}

mock_resource "azurerm_network_security_group" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/streamsec-scanner-tf-00000000/providers/Microsoft.Network/networkSecurityGroups/streamsec-scanner-nsg"
  }
}

mock_resource "azurerm_virtual_network" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/streamsec-scanner-tf-00000000/providers/Microsoft.Network/virtualNetworks/streamsec-scanner-vnet"
  }
}
