# 🌐 Azure Fundamentals

> **AWS Parallel:** Core AWS concepts → Azure equivalent  
> **GCP Parallel:** GCP projects/organizations → Azure subscriptions/management groups

## Core Azure Concepts

| Concept | Azure | AWS | GCP |
|---|---|---|---|
| Account hierarchy | Management Group → Subscription → Resource Group → Resource | Organization → Account → Region | Organization → Folder → Project |
| Billing unit | Subscription | Account | Project |
| Logical grouping | Resource Group | — (tags + account) | Project |
| Global backbone | Azure backbone network | AWS Global Network | Google backbone |
| Regions | 60+ regions | 30+ regions | 37+ regions |
| Availability | Availability Zones (3 per region) | AZs (2–6 per region) | Zones (3 per region) |

---

## Labs in This Section

| Lab | Title | Difficulty |
|---|---|---|
| Lab-01 | Azure Portal & CLI Orientation | 🟢 |
| Lab-02 | Subscriptions, Management Groups & Resource Groups | 🟢 |
| Lab-03 | Azure Policy — Enforce Governance | 🟡 |
| Lab-04 | Tagging Strategy & Cost Allocation | 🟢 |
| Lab-05 | Azure Resource Locks | 🟢 |
| Lab-06 | ARM Template Basics | 🟡 |
| Lab-07 | Azure Regions, Availability Zones & Paired Regions | 🟢 |

---

## Key Azure CLI Commands Reference

```bash
# Account management
az login
az account list --output table
az account set --subscription "SUB_ID"
az account show

# Resource Groups
az group list --output table
az group create --name rg-lab --location eastus
az group delete --name rg-lab --yes --no-wait

# Management Groups
az account management-group list
az account management-group create --name "mg-prod" --display-name "Production"

# Locations
az account list-locations --output table

# Resource operations
az resource list --resource-group rg-lab --output table
az resource show --ids "/subscriptions/<sub>/resourceGroups/<rg>/providers/..."
az resource move --destination-group rg-new --ids "<resource-id>"
```
