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

run "create_new_matches_the_arm_template" {
  command = apply

  assert {
    condition = alltrue([
      azurerm_public_ip.nat[0].name == "streamsec-scanner-nat-pip",
      azurerm_public_ip.nat[0].sku == "Standard",
      azurerm_public_ip.nat[0].allocation_method == "Static",
      azurerm_nat_gateway.this[0].name == "streamsec-scanner-nat",
      azurerm_nat_gateway.this[0].sku_name == "Standard",
      azurerm_nat_gateway.this[0].idle_timeout_in_minutes == 4,
      azurerm_nat_gateway_public_ip_association.this[0].nat_gateway_id == azurerm_nat_gateway.this[0].id,
      azurerm_nat_gateway_public_ip_association.this[0].public_ip_address_id == azurerm_public_ip.nat[0].id,
    ])
    error_message = "Egress must be a Standard NAT gateway (idle timeout 4) with a Standard static public IP."
  }

  assert {
    condition = (
      length(azurerm_network_security_group.this[0].security_rule) == 1 &&
      alltrue([
        for rule in azurerm_network_security_group.this[0].security_rule :
        rule.name == "DenyAllInbound" && rule.priority == 4096 && rule.direction == "Inbound" && rule.access == "Deny" &&
        rule.protocol == "*" && rule.source_port_range == "*" && rule.destination_port_range == "*" &&
        rule.source_address_prefix == "*" && rule.destination_address_prefix == "*"
      ])
    )
    error_message = "The NSG must hold only DenyAllInbound, at priority 4096."
  }

  assert {
    condition = alltrue([
      azurerm_virtual_network.this[0].name == "streamsec-scanner-vnet",
      azurerm_virtual_network.this[0].address_space == toset(["10.255.0.0/24"]),
    ])
    error_message = "The VNet must be 10.255.0.0/24."
  }

  assert {
    condition = alltrue([
      azapi_resource.subnet[0].name == "streamsec-scanner-subnet",
      azapi_resource.subnet[0].type == "Microsoft.Network/virtualNetworks/subnets@2024-05-01",
      azapi_resource.subnet[0].parent_id == azurerm_virtual_network.this[0].id,
      azapi_resource.subnet[0].body.properties.addressPrefix == "10.255.0.0/24",
      [for e in azapi_resource.subnet[0].body.properties.serviceEndpoints : e.service] == ["Microsoft.Storage"],
      [for d in azapi_resource.subnet[0].body.properties.delegations : d.properties.serviceName] == ["Microsoft.App/environments"],
      azapi_resource.subnet[0].body.properties.networkSecurityGroup.id == azurerm_network_security_group.this[0].id,
      azapi_resource.subnet[0].body.properties.natGateway.id == azurerm_nat_gateway.this[0].id,
    ])
    error_message = "The subnet must be the whole VNet, with a Microsoft.Storage endpoint, delegated to Microsoft.App/environments, with the NSG and NAT gateway attached."
  }

  assert {
    condition     = azurerm_container_app_environment.this.infrastructure_subnet_id == azapi_resource.subnet[0].id
    error_message = "The environment must run on the subnet this module created."
  }

  assert {
    condition     = output.subnet_id == azapi_resource.subnet[0].id && output.nat_gateway_public_ip == "192.0.2.10"
    error_message = "The outputs must expose the subnet and the NAT gateway's egress IP."
  }
}

run "use_existing_creates_no_network" {
  command = apply

  variables {
    network_mode       = "use_existing"
    existing_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/shared/subnets/scanner"
  }

  assert {
    condition = alltrue([
      length(azurerm_public_ip.nat) == 0,
      length(azurerm_nat_gateway.this) == 0,
      length(azurerm_nat_gateway_public_ip_association.this) == 0,
      length(azurerm_network_security_group.this) == 0,
      length(azurerm_virtual_network.this) == 0,
      length(azapi_resource.subnet) == 0,
    ])
    error_message = "use_existing must create no network resources."
  }

  assert {
    condition     = azurerm_container_app_environment.this.infrastructure_subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/shared/subnets/scanner"
    error_message = "The environment must run on existing_subnet_id."
  }

  assert {
    condition     = output.nat_gateway_public_ip == null && output.subnet_id == var.existing_subnet_id
    error_message = "With use_existing there is no NAT gateway IP, and subnet_id is the one supplied."
  }
}

run "use_existing_needs_a_subnet" {
  command = plan

  variables {
    network_mode = "use_existing"
  }

  expect_failures = [azurerm_container_app_environment.this]
}

run "blank_existing_subnet_id_is_rejected" {
  command = plan

  variables {
    network_mode       = "use_existing"
    existing_subnet_id = " "
  }

  expect_failures = [var.existing_subnet_id]
}

# The ARM template ignores existingSubnetId unless networkMode is use_existing.
run "existing_subnet_id_is_ignored_with_create_new" {
  command = apply

  variables {
    existing_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/shared/subnets/scanner"
  }

  assert {
    condition     = length(azapi_resource.subnet) == 1 && azurerm_container_app_environment.this.infrastructure_subnet_id == azapi_resource.subnet[0].id
    error_message = "With create_new the module's own subnet is used, whatever existing_subnet_id says."
  }
}
