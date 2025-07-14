# 🚀 Terraform Azure Infrastructure (AKS + Kafka)

This project provisions Azure infrastructure using Terraform. It currently deploys:

- Azure Kubernetes Service (AKS)
- Azure Event Hubs (Kafka-compatible)
- Virtual Network and Subnet

---

## 📸 Architecture Overview

> _You can insert your infrastructure diagram below_

![Infrastructure Diagram](./assets/success.png)
![Infrastructure Diagram](./assets/infra-creation.png)

---

## 📂 Planned Directory Structure

> _This is the structure this project is evolving toward as modularization continues._

```

terraform/
├── modules/
│   ├── network/   # VNet, Subnet, NSG, NAT Gateway (to be added)
│   ├── aks/       # Kubernetes cluster (to be added)
│   └── kafka/     # Event Hub Kafka resources (to be added)
├── env/
│   └── dev/       # Environment-specific configuration (partially implemented)
└── provider.tf    # Provider configuration (backend not yet enabled)

```

---

## ☁️ Components Created

This version of the project provisions the following:

- AKS Cluster with default node pool
- Kafka-compatible Event Hub Namespace + Topic
- VNet and subnet for cluster connectivity

> _Remote Terraform backend and full module separation are planned for future iterations._

---

## ⚙️ Deployment Instructions

### 1. 📦 Prerequisites

- Azure CLI logged in (`az login`)
- Terraform CLI (`>= 1.4`)
- Service Principal credentials or `az login` session

---

### 2. 🧱 Initialize + Apply

```bash
cd terraform/env/dev

terraform init
terraform plan -out=tf.plan
terraform apply tf.plan
```

---

## 🐛 Troubleshooting & Error Log

Below is a full catalog of errors encountered during deployment:

---

### 1. ❌ `Attribute not expected here`

**Cause**: Misuse of `enable_auto_scaling`, `spot_max_price`, or `kafka_enabled`.
**Fix**: Moved invalid attributes to a separate node pool block or corrected syntax from registry examples like:

```hcl
node_labels = {
  "node-type" = "spot"
}
```

---

### 2. 🔐 `AADSTS900023: tenant_id is not valid`

**Cause**: Used placeholder tenant ID (`your_tenant_id`).
**Fix**: Removed hardcoded credentials, used `.env` or `az login` to authenticate.

---

### 3. ⚠️ `K8sVersionNotSupported`

**Cause**: Used unsupported version (`1.28.15`).
**Fix**: Changed to supported version with:

```bash
az aks get-versions --location eastus --output table
```

---

### 4. 🔄 `Saved plan is stale`

**Cause**: Terraform state changed after plan was saved.
**Fix**:

```bash
terraform plan -out=tf.plan
terraform apply tf.plan
```

Or simply:

```bash
terraform apply
```

---

### 5. 🚫 `VM size not allowed in location`

**Cause**: Chosen size not available or quota exceeded in region.
**Fix**: Switched to a different region.

---

### 6. 🔁 `Provider produced inconsistent result after apply`

**Cause**: Azure resource wasn't fully ready before Terraform read it.
**Fix**: Used `depends_on` for resource order enforcement.

---

### 7. 🔍 `namespaces/networkrulesets: parent resource not found`

**Cause**: Event Hub rules applied before namespace was created.
**Fix**:

```bash
terraform apply -target=azurerm_eventhub_namespace.kafka
terraform apply
```

---

### 8. 🌐 `service_cidr conflicts with subnet`

**Cause**: `service_cidr` overlapped with VNet subnet range.
**Fix**:

```hcl
service_cidr = "10.2.0.0/16"
```

---

### 9. 📛 `dns_service_ip is out of range`

**Cause**: `dns_service_ip` not within `service_cidr` range.
**Fix**:

```hcl
dns_service_ip = "10.2.0.10"
```

---

## ✅ Result

All services deployed successfully. Terraform `apply` completed without errors.

---

## 📌 Next Steps

- Complete full modular separation
- Enable remote Terraform state backend
- Add CI/CD with GitHub Actions
- Integrate Azure Key Vault
- Expand into staging/prod environments
