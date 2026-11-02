################################################################################
# network_mode = "create_new": a dedicated VNet whose one subnet reaches the
# internet only through a NAT gateway with a static public IP, and takes no
# inbound traffic. "use_existing" skips all of it and uses existing_subnet_id.
################################################################################

locals {
  create_network = var.network_mode == "create_new"

  subnet_id = local.create_network ? azapi_resource.subnet[0].id : var.existing_subnet_id
}

resource "azurerm_public_ip" "nat" {
  count = local.create_network ? 1 : 0

  name                = "streamsec-scanner-nat-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  allocation_method   = "Static"

  tags = local.tags
}

resource "azurerm_nat_gateway" "this" {
  count = local.create_network ? 1 : 0

  name                    = "streamsec-scanner-nat"
  location                = azurerm_resource_group.this.location
  resource_group_name     = azurerm_resource_group.this.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4

  tags = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count = local.create_network ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_network_security_group" "this" {
  count = local.create_network ? 1 : 0

  name                = "streamsec-scanner-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.tags
}

resource "azurerm_virtual_network" "this" {
  count = local.create_network ? 1 : 0

  name                = "streamsec-scanner-vnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.255.0.0/24"]

  tags = local.tags
}

# azapi, not azurerm_subnet: its service endpoint argument changed shape in azurerm 5.0
# (service_endpoints became service_endpoint blocks), and no one configuration fits both
# majors. The body is the ARM template's subnet, with the NSG and NAT gateway attached.
resource "azapi_resource" "subnet" {
  count = local.create_network ? 1 : 0

  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  name      = "streamsec-scanner-subnet"
  parent_id = azurerm_virtual_network.this[0].id

  body = {
    properties = {
      addressPrefix = "10.255.0.0/24"
      # Disk reads over SAS and registry layer pulls are blob traffic: over the endpoint
      # they take the Azure backbone instead of the NAT gateway, which bills per GB.
      serviceEndpoints = [
        { service = "Microsoft.Storage" },
      ]
      delegations = [
        {
          name       = "containerapps"
          properties = { serviceName = "Microsoft.App/environments" }
        },
      ]
      networkSecurityGroup = { id = azurerm_network_security_group.this[0].id }
      natGateway           = { id = azurerm_nat_gateway.this[0].id }
    }
  }

  # The jobs need egress from their first run: the NAT gateway must have its address.
  depends_on = [azurerm_nat_gateway_public_ip_association.this]
}
