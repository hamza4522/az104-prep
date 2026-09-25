# 🚀 Azure Deep Dive — Complete Hands-On Lab Repository

> **Audience:** DevOps Engineers with AWS / GCP / OCI background transitioning to Azure  
> **Certification Target:** AZ-104 (Azure Administrator) & beyond  
> **Structure:** One folder per service → Multiple labs per service → Full solutions included

---

## 📐 Repository Structure

```
az104/
├── 01-azure-fundamentals/
├── 02-identity-and-access-management/
├── 03-virtual-networking/
├── 04-compute-virtual-machines/
├── 05-storage/
├── 06-databases/
├── 07-app-service/
├── 08-containers-and-kubernetes/
├── 09-serverless/
├── 10-monitoring-and-governance/
├── 11-security/
├── 12-devops-and-cicd/
├── 13-infrastructure-as-code/
├── 14-messaging-and-events/
├── 15-hybrid-and-migration/
├── 16-cost-management/
├── 17-disaster-recovery/
└── 18-advanced-networking/
```

---

## 🗺️ AWS / GCP / OCI → Azure Service Mapping

| Your Experience | Azure Equivalent |
|---|---|
| AWS EC2 / GCP Compute Engine / OCI Compute | Azure Virtual Machines |
| AWS VPC / GCP VPC / OCI VCN | Azure Virtual Network (VNet) |
| AWS S3 / GCP GCS / OCI Object Storage | Azure Blob Storage |
| AWS RDS / GCP Cloud SQL / OCI DB | Azure SQL / Managed Instances |
| AWS Lambda / GCP Cloud Functions / OCI Functions | Azure Functions |
| AWS EKS / GCP GKE / OCI OKE | Azure Kubernetes Service (AKS) |
| AWS IAM / GCP IAM / OCI IAM | Azure Active Directory + RBAC |
| AWS CloudWatch / GCP Cloud Monitoring | Azure Monitor + Log Analytics |
| AWS CloudFormation / GCP Deployment Manager | Azure Resource Manager (ARM) / Bicep |
| AWS CodePipeline / GCP Cloud Build | Azure DevOps / GitHub Actions |
| AWS Route53 / GCP Cloud DNS | Azure DNS + Traffic Manager |
| AWS ELB / GCP Load Balancing | Azure Load Balancer + Application Gateway |
| AWS SQS/SNS / GCP Pub/Sub | Azure Service Bus + Event Grid |
| AWS DirectConnect / GCP Interconnect | Azure ExpressRoute |
| AWS Transit Gateway / GCP VPC Peering | Azure Virtual WAN |

---

## 🛠️ Prerequisites

```bash
# 1. Install Azure CLI
# Windows (PowerShell - Admin)
winget install Microsoft.AzureCLI

# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 2. Login
az login

# 3. Set subscription
az account list --output table
az account set --subscription "<your-subscription-id>"

# 4. Install Bicep
az bicep install

# 5. Install Terraform (for IaC labs)
# Download from https://developer.hashicorp.com/terraform/downloads

# 6. Install kubectl
az aks install-cli

# 7. Verify setup
az --version
az account show
```

---

## 📋 Lab Difficulty Legend

| Icon | Level | Description |
|---|---|---|
| 🟢 | **Level 1** | Hardened Production Foundation (Zero default passwords, Least-privilege RBAC, Key Vault integration) |
| 🟡 | **Level 2** | Enterprise Resiliency & DevOps Automation (VNet integration, Private Endpoints, Blue-Green, Autoscaling) |
| 🔴 | **Level 3** | Zero-Trust, High-Scale & Disaster Recovery (Multi-region active-active, CMK envelope crypto, ASR, Front Door, GitOps) |

---

## 🏆 Production-Grade Multi-Level Scenario Matrix

Every major domain contains an automated, fully scripted **Multi-Level Production Lab** (`lab-script.sh`) tailored specifically for DevOps engineers moving from AWS/GCP/OCI:

| Domain | 🟢 Level 1 | 🟡 Level 2 | 🔴 Level 3 | Runnable Production Script |
|---|---|---|---|---|
| **02 - IAM & Identity** | Users, Dynamic Groups, RBAC | Custom Roles, Managed Identities | Conditional Access, PIM, Workload Identity | [`lab-script.sh`](file:///c:/Users/syedh/Downloads/az104/02-identity-and-access-management/Lab-01-azure-ad-users-groups/lab-script.sh) |
| **03 - Virtual Networking** | 3-Tier VNet, NSG, Bastion | Hub-Spoke, Azure Firewall, Flow Logs | Multi-Region HA, ExpressRoute, BGP | [`lab-script.sh`](file:///c:/Users/syedh/Downloads/az104/03-virtual-networking/Lab-01-vnet-subnets-nsg/lab-script.sh) |
| **04 - Compute & VMs** | Hardened VM, Key Vault SSH, Disks | VMSS Flex, Autoscaling, Rolling Upgrades, Spot | Confidential VM, CMK Disk Encryption, ASR | [`lab-script.sh`](file:///c:/Users/syedh/Downloads/az104/04-compute-virtual-machines/Lab-01-create-manage-vms/lab-script.sh) |
| **05 - Storage** | Secure Blob, CDN, Lifecycle rules | Data Lake Gen2, Event-Driven Ingest | CMK, WORM Immutability, Legal Hold, GRS DR | [`lab-script.sh`](file:///c:/Users/syedh/Downloads/az104/05-storage/Lab-01-blob-storage/lab-script.sh) |
| **06 - Databases** | SQL CMK, TDE, Private Endpoint | Geo-Failover, Elastic Pool, Cosmos DB | Multi-region Active-Active, Event Sourcing | [`lab-script.sh`](file:///c:/Users/syedh/Downloads/az104/06-databases/Lab-01-azure-sql-database/lab-script.sh) |
| **07 - App Service** | Linux Container, Key Vault Refs, Managed Identity | Regional VNet Integration, Blue/Green, Canary | Multi-region Front Door, Auto-Heal, Custom WAF | [`lab-script.sh`](file:///c:/Users/syedh/Downloads/az104/07-app-service/Lab-01-web-apps/lab-script.sh) |
| **08 - Containers & AKS** | Hardened AKS, Calico CNI, ACR | Workload Identity, Autoscaler, Ingress NGINX | Multi-tenant GitOps, Kyverno, KEDA, Spot Pools | [`lab-script.sh`](file:///c:/Users/syedh/Downloads/az104/08-containers-and-kubernetes/Lab-02-aks-cluster/lab-script.sh) |
| **09 - Serverless** | Consumption Function, Managed Identity | Elastic Premium (EP1), Pre-Warmed, VNet Outbound | Stateful Durable Functions (Fan-out/in, Approval) | [`lab-script.sh`](file:///c:/Users/syedh/Downloads/az104/09-serverless/Lab-01-azure-functions/lab-script.sh) |
| **10 - Monitor & Governance** | Log Analytics, AMA, DCR, Action Groups | KQL Operational Suite, Scheduled Query Alerts | Policy Governance, Auto-Remediation, Locks | [`lab-script.sh`](file:///c:/Users/syedh/Downloads/az104/10-monitoring-and-governance/Lab-01-azure-monitor/lab-script.sh) |
| **11 - Cloud Security** | Key Vault, RBAC, Auto-Renewing Certs | Private Link, Firewall Whitelist, Audit Logs | Automated Key Rotation, HSM, Defender for Cloud | [`lab-script.sh`](file:///c:/Users/syedh/Downloads/az104/11-security/Lab-01-key-vault/lab-script.sh) |
| **13 - IaC & Terraform** | Modular Terraform, State Storage | GitHub Actions OIDC CI/CD, Drift Detection | CAF Enterprise Landing Zone, Management Groups | [`enterprise-lab-script.sh`](file:///c:/Users/syedh/Downloads/az104/13-infrastructure-as-code/Lab-03-terraform/enterprise-lab-script.sh) |
| **14 - Messaging & Events** | Service Bus Queue, DLQ, RBAC Auth | Pub/Sub Topics, SQL Filters, FIFO Sessions | Premium Geo-DR Pairing, Event Hubs Capture | [`lab-script.sh`](file:///c:/Users/syedh/Downloads/az104/14-messaging-and-events/Lab-01-service-bus/lab-script.sh) |
| **18 - Advanced Networking** | Hub-Spoke, Non-transitive Peering, UDR | Azure Firewall Policy, FQDN Rules, IDPS | Application Gateway v2 WAF, E2E SSL, Rate Limits | [`lab-script.sh`](file:///c:/Users/syedh/Downloads/az104/18-advanced-networking/Lab-01-hub-spoke-firewall/lab-script.sh) |

---

## 🎯 Learning Path

### Week 1–2: Foundations & Core Networking
- Azure Fundamentals (01)
- Identity & Access Management (02)
- Virtual Networking & Security (03)

### Week 3–4: Core Infrastructure & Storage
- Virtual Machines & VMSS (04)
- Blob Storage & Data Lake Gen2 (05)
- Azure SQL & Cosmos DB (06)

### Week 5–6: Modern Application Platforms
- App Service & Deployment Slots (07)
- Containers & Kubernetes / AKS (08)
- Serverless Functions & Event Grid (09)

### Week 7–8: Operations, Security & Governance
- Monitoring, KQL & Azure Policy (10)
- Key Vault, Defender & Zero-Trust Security (11)
- Cost Management & Budgets (16)

### Week 9–10: DevOps, IaC & Messaging
- DevOps & CI/CD (12)
- Infrastructure as Code: Terraform & Bicep (13)
- Service Bus & Event Hubs (14)

### Week 11–12: Advanced Transit & Hybrid
- Hybrid & Migration (15)
- Disaster Recovery & Business Continuity (17)
- Advanced Networking & Hub-Spoke Firewalls (18)

---

## 🤝 How to Run the Production Labs

1. **Open any lab script** (e.g. `04-compute-virtual-machines/Lab-01-create-manage-vms/lab-script.sh`)
2. **Review the architecture** in the script comments and associated `README.md`.
3. **Execute the script** in Azure Cloud Shell (Bash) or your local terminal with Azure CLI:
   ```bash
   chmod +x ./lab-script.sh
   ./lab-script.sh
   ```
4. **Inspect resources** created in your Azure Portal.
5. **Execute teardown commands** provided at the end of each script or README to avoid unexpected cloud spend:
   ```bash
   az group delete --name <resource-group-name> --yes --no-wait
   ```

---

*Happy Learning! Azure has some of the most robust enterprise patterns in cloud computing. Let's master them all! 🚀*

