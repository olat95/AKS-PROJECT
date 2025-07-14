# Random string for unique resource naming
resource "random_pet" "resource_suffix" {
  length = 2
}

# Azure resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.cluster_name}-rg"
  location = var.azure_region
  tags     = var.common_tags
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.cluster_name}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [var.vnet_cidr]
  tags                = var.common_tags

  depends_on = [azurerm_resource_group.rg]
}

# Public Subnets
resource "azurerm_subnet" "public" {
  count                = length(var.public_subnets)
  name                 = "${var.cluster_name}-public-subnet-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [element(var.public_subnets, count.index)]
}

# Private Subnets
resource "azurerm_subnet" "private" {
  count                = length(var.private_subnets)
  name                 = "${var.cluster_name}-private-subnet-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [element(var.private_subnets, count.index)]
}

# NAT Gateway
resource "azurerm_public_ip" "nat_ip" {
  name                = "${var.cluster_name}-nat-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.common_tags
}

resource "azurerm_nat_gateway" "nat" {
  name                = "${var.cluster_name}-nat"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
  tags                = var.common_tags

  depends_on = [azurerm_public_ip.nat_ip]
}

resource "azurerm_nat_gateway_public_ip_association" "nat_ip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "nat_subnet_assoc" {
  count          = length(azurerm_subnet.private)
  subnet_id      = azurerm_subnet.private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.cluster_name}-dns"
  kubernetes_version  = var.aks_version

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.node_instance_type
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = var.node_min_count
    max_count           = var.node_max_count
    vnet_subnet_id      = azurerm_subnet.private[0].id
    max_pods            = 30
    tags                = var.common_tags
    node_labels = {
      "node-type" = "spot"
    }
    # Use spot instances
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.2.0.0/16" # IPs for Kubernetes services
    dns_service_ip = "10.2.0.10"   # Must be in the same block
  }

  tags = var.common_tags
}

# Network Security Group for AKS-Event Hubs communication
resource "azurerm_network_security_group" "kafka_nsg" {
  name                = "${var.kafka_namespace}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.common_tags

  security_rule {
    name                       = "AllowKafkaFromAKS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9092"
    source_address_prefix      = var.vnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowEgress"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_virtual_network.vnet]
}

# Event Hubs Namespace (Kafka equivalent)
resource "azurerm_eventhub_namespace" "kafka" {
  name                = "${var.kafka_namespace}-${random_pet.resource_suffix.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.kafka_sku
  capacity            = var.kafka_capacity
  # kafka_enabled       = true
  tags = var.common_tags

  depends_on = [azurerm_resource_group.rg]
}

# Event Hub instance
resource "azurerm_eventhub" "kafka_hub" {
  name                = "kafka-hub"
  namespace_name      = azurerm_eventhub_namespace.kafka.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 1
}

# Event Hubs Authorization Rule (SAS key for Kafka clients)
resource "azurerm_eventhub_namespace_authorization_rule" "kafka_auth" {
  name                = "kafka-auth-rule"
  namespace_name      = azurerm_eventhub_namespace.kafka.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = true
}

# Associate NSG with private subnets
resource "azurerm_subnet_network_security_group_association" "kafka_nsg_assoc" {
  count                     = length(azurerm_subnet.private)
  subnet_id                 = azurerm_subnet.private[count.index].id
  network_security_group_id = azurerm_network_security_group.kafka_nsg.id
}
