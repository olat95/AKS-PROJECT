output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_endpoint" {
  description = "AKS cluster endpoint"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "kafka_bootstrap_servers" {
  description = "Event Hubs Kafka bootstrap servers"
  value       = "${azurerm_eventhub_namespace.kafka.name}.servicebus.windows.net:9092"
}

output "kafka_sas_key" {
  description = "Event Hubs SAS key for Kafka clients"
  value       = azurerm_eventhub_namespace_authorization_rule.kafka_auth.primary_connection_string
  sensitive   = true
}

output "vnet_id" {
  description = "VNet ID"
  value       = azurerm_virtual_network.vnet.id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = azurerm_subnet.private[*].id
}