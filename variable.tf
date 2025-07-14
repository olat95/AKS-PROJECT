variable "azure_region" {
  description = "Azure region for all resources"
  type        = string
  default     = "East US 2"
}

variable "client_id" {
  description = "Azure service principal client ID"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Azure service principal client secret"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
  sensitive   = true
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "dev-aks-cluster"
}

variable "kafka_namespace" {
  description = "Name of the Event Hubs namespace"
  type        = string
  default     = "dev-kafka-namespace"
}

variable "vnet_cidr" {
  description = "CIDR block for the VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "aks_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.33.0"
}

variable "node_instance_type" {
  description = "VM size for AKS node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "node_min_count" {
  description = "Minimum number of nodes in AKS node pool"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum number of nodes in AKS node pool"
  type        = number
  default     = 2
}

variable "node_count" {
  description = "Desired number of nodes in AKS node pool"
  type        = number
  default     = 1
}

variable "kafka_sku" {
  description = "SKU for Event Hubs namespace"
  type        = string
  default     = "Basic"
}

variable "kafka_capacity" {
  description = "Throughput units for Event Hubs namespace"
  type        = number
  default     = 2
}

variable "kafka_storage_size" {
  description = "Storage size for Event Hubs in GB"
  type        = number
  default     = 100
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "development"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "development"
    Project     = "aks-kafka-dev"
  }
}
