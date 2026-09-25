# 🌐 Lab 01: Azure App Service — Multi-Level Production Architectures

> **AZ-104 Focus:** Deploy and configure Azure App Service, configure deployment slots, scale App Service, configure networking (VNet integration and Private Endpoints).  
> **AWS Parallel:** AWS Elastic Beanstalk / ECS Fargate + ALB + Secrets Manager  
> **GCP Parallel:** Google Cloud Run / App Engine + Cloud KMS

---

## 🎯 Lab Progression Overview

```
┌────────────────────────────────────────────────────────────────────────┐
│ 🟢 LEVEL 1 — Hardened App Service (Managed Identity + Key Vault)       │
│  - Premium v3 Plan (P1v3) with Zone Redundancy                         │
│  - Python 3.11 Runtime with Container support                          │
│  - System-Assigned Managed Identity + Azure RBAC                       │
│  - Zero Plaintext Secrets: Key Vault References (@Microsoft.KeyVault)  │
│  - TLS 1.2/1.3 Enforcement, HTTPS-Only, FTPS Disabled                  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ 🟡 LEVEL 2 — Enterprise VNet Integration & Blue-Green Deployment Slots │
│  - Regional VNet Integration (Subnet delegation to Microsoft.Web)      │
│  - Inbound lockdown with Private Endpoint (No public internet IP)      │
│  - Staging slot with sticky configuration settings                     │
│  - Canary Traffic Routing (80% production, 20% staging preview)        │
│  - Zero-downtime slot swapping with automatic warm-up validation       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ 🔴 LEVEL 3 — Global Multi-Region Anycast Front Door + Auto-Healing     │
│  - Multi-Region Active-Active deployment (East US + West US 2)         │
│  - Azure Front Door (Global Anycast, SSL Offloading, Edge Caching)     │
│  - Sub-second health probes & automatic failover routing               │
│  - Auto-Heal rules (Automatic worker recycle on 5xx or slow requests)  │
│  - Log Analytics streaming of HTTP access logs & application metrics   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Step-by-Step Execution Guide

### Level 1: Key Vault References & Managed Identity

In AWS, you often use IAM Roles for EC2/ECS and fetch secrets using the AWS SDK from Secrets Manager.  
In Azure, **App Service natively resolves Key Vault secrets without any application code changes** via Key Vault References:

```bash
# Set secret reference in App Settings
az webapp config appsettings set \
  --resource-group rg-appservice-l1-prod \
  --name app-catalog-api \
  --settings "DB_CONNECTION=@Microsoft.KeyVault(SecretUri=https://<vault-name>.vault.azure.net/secrets/<secret-name>/<version>)"
```

The Azure App Service infrastructure uses the App's **Managed Identity** to fetch and decrypt the secret into the environment variable automatically!

---

### Level 2: VNet Outbound Integration vs Private Endpoints

One of the most common confusions for DevOps engineers moving from AWS:

| Feature | Direction | What it achieves | AWS Equivalent |
|---|---|---|---|
| **VNet Integration** | **Outbound** | Allows the Web App to make outbound calls to private resources in your VNet (e.g. private RDS/SQL, Redis, internal VMs). | Running Lambda/ECS in a VPC private subnet |
| **Private Endpoint** | **Inbound** | Gives the Web App a private IP inside your VNet. Disables public internet access. | AWS PrivateLink / VPC Interface Endpoint |
| **Deployment Slots** | **Lifecycle** | Provides parallel live environments (`production`, `staging`) sharing the same App Service Plan. | AWS Blue/Green with Route 53 or ECS Task Sets |

#### Traffic Routing (Canary):
```bash
# Route 15% of traffic to staging slot
az webapp traffic-routing set \
  --resource-group rg-appservice-l2-enterprise \
  --name app-payment-service \
  --distribution staging=15
```

---

### Level 3: Azure Front Door & Auto-Healing

Azure Front Door operates at Layer 7 across Microsoft's global edge points of presence (PoPs):
- **Anycast IP**: Single global ingress routing users to the nearest PoP.
- **Split TCP**: Accelerates SSL handshake latency.
- **Origin Groups**: Automatic load balancing and failover between primary and secondary regions based on health probes.

#### Auto-Heal Rules:
Configuring proactive auto-healing safeguards against memory leaks and hanging worker threads:
- Triggers on consecutive HTTP 500 errors within 2 minutes.
- Triggers on slow requests taking > 15 seconds.
- Automatically executes worker process recycling without restarting the entire container.

---

## 🧪 Verification & Testing Commands

```bash
# 1. Verify Managed Identity Key Vault resolution
az webapp config appsettings list \
  --resource-group rg-appservice-l1-prod \
  --name app-catalog-api \
  --query "[?name=='DB_CONNECTION']" -o table

# 2. Verify Private Endpoint DNS resolution
nslookup app-payment-service.privatelink.azurewebsites.net

# 3. Test Front Door Endpoint
curl -I https://<endpoint-name>.azurefd.net/healthz

# 4. Check deployment slots
az webapp deployment slot list \
  --resource-group rg-appservice-l2-enterprise \
  --name app-payment-service -o table
```

---

## 🧹 Teardown Command

```bash
az group delete --name rg-appservice-l1-prod --yes --no-wait
az group delete --name rg-appservice-l2-enterprise --yes --no-wait
az group delete --name rg-appservice-l3-global --yes --no-wait
```
