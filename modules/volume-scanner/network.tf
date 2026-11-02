################################################################################
# Network
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

# azapi rather than azurerm_subnet, whose service endpoint arguments differ between azurerm 4 and 5
resource "azapi_resource" "subnet" {
  count = local.create_network ? 1 : 0

  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  name      = "streamsec-scanner-subnet"
  parent_id = azurerm_virtual_network.this[0].id

  body = {
    properties = {
      addressPrefix = "10.255.0.0/24"
      # keeps disk reads and image pulls off the NAT gateway
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

  depends_on = [azurerm_nat_gateway_public_ip_association.this]
}
