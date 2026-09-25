# 🏗️ Lab 02 — Subscriptions, Management Groups & Resource Groups

**Difficulty:** 🟢 Beginner  
**Time:** 45 minutes  
**Goal:** Build the Azure organizational hierarchy — the foundation for governance, cost control, and security

---

## Background

Azure's hierarchy (from top to bottom):
```
Root Management Group
  └── Management Groups (like AWS OUs / GCP Folders)
        └── Subscriptions (like AWS Accounts / GCP Projects — billing boundary)
              └── Resource Groups (mandatory logical containers — NO AWS equivalent)
                    └── Resources (VMs, Storage, etc.)
```

**Why this matters for DevOps:**
- Policies applied at Management Group level cascade DOWN (like AWS SCPs / GCP Org Policies)
- RBAC assigned at Resource Group level scopes to all resources in it
- Cost is tracked at Subscription level
- Resources CANNOT exist outside a Resource Group

---

## Lab Objectives

1. View and navigate Management Groups
2. Create a subscription (or understand subscription types)
3. Create Resource Groups with naming conventions
4. Move resources between Resource Groups
5. Apply tags for cost allocation
6. Understand provider namespaces

---

## Part 1 — Management Groups

```bash
# List management groups
az account management-group list --output table

# Get the root management group
az account management-group list --query "[?details.parent==null].{Name:name, DisplayName:displayName}" --output table

# Create a management group hierarchy
az account management-group create \
  --name "mg-platform" \
  --display-name "Platform"

az account management-group create \
  --name "mg-workloads" \
  --display-name "Workloads"

az account management-group create \
  --name "mg-sandbox" \
  --display-name "Sandbox" \
  --parent "mg-platform"

# Show the hierarchy
az account management-group show \
  --name "mg-platform" \
  --expand \
  --recurse

# Move a subscription under a management group
# NOTE: You need Owner role on both the MG and the subscription
az account management-group subscription add \
  --name "mg-sandbox" \
  --subscription "YOUR-SUBSCRIPTION-ID"
```

### Management Group Best Practices (Enterprise Scale)

```
Root Management Group
├── mg-platform (shared services)
│   ├── mg-connectivity (networking hub)
│   ├── mg-identity (AD, DNS)
│   └── mg-management (monitoring, security)
├── mg-workloads
│   ├── mg-corp (corporate internal apps)
│   └── mg-online (customer-facing apps)
├── mg-sandbox (developer experimentation)
└── mg-decommissioned (sunsetted subscriptions)
```

---

## Part 2 — Subscriptions

```bash
# List all subscriptions (like aws account list in AWS Organizations)
az account list --output table

# Show current subscription details
az account show

# Get subscription ID (useful for scripting)
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"

# Switch between subscriptions
az account set --subscription "Subscription-Name-or-ID"

# List subscription locations (regions available to this subscription)
az account list-locations --query "[].{Region:name, DisplayName:displayName}" --output table

# Subscription types in Azure:
# - Free (12 months free services + $200 credit)
# - Pay-As-You-Go (PAYG) — most common
# - Enterprise Agreement (EA) — large organizations
# - CSP (Cloud Solution Provider) — via partner
# - Visual Studio / Dev/Test — discounted for dev
```

---

## Part 3 — Resource Groups Deep Dive

### Naming Convention (Important for Real Projects)

```bash
# Recommended naming: {resource-type}-{workload}-{environment}-{region}-{instance}
# Examples:
# rg-webapp-prod-eastus-001
# rg-database-dev-westus2-001
# rg-networking-shared-centralus-001

# Create Resource Groups with full tagging
az group create \
  --name rg-webapp-prod-eastus-001 \
  --location eastus \
  --tags \
    Environment=Production \
    Project=WebApp \
    CostCenter=CC-1234 \
    Owner=devops-team@company.com \
    CreatedBy=az-cli \
    CreatedDate=$(date +%Y-%m-%d)

az group create \
  --name rg-webapp-dev-eastus-001 \
  --location eastus \
  --tags Environment=Development Project=WebApp CostCenter=CC-1234

az group create \
  --name rg-networking-shared-eastus-001 \
  --location eastus \
  --tags Environment=Shared Project=Networking CostCenter=CC-0001

# List with specific tags
az group list --query "[?tags.Environment=='Production'].{Name:name, Location:location}" --output table
```

### Resource Group Operations

```bash
# Update tags on existing group
az group update \
  --name rg-webapp-dev-eastus-001 \
  --set tags.LastModified=$(date +%Y-%m-%d)

# Get resource group details
az group show --name rg-webapp-prod-eastus-001

# Export resource group as ARM template (snapshot of configuration)
az group export \
  --name rg-webapp-prod-eastus-001 \
  --output json > rg-webapp-prod-template.json

# List all resources in resource group
az resource list \
  --resource-group rg-webapp-prod-eastus-001 \
  --output table

# Deploy resources to a resource group
az deployment group create \
  --resource-group rg-webapp-prod-eastus-001 \
  --template-file template.json \
  --parameters parameters.json

# Preview deployment (what-if analysis — like Terraform plan)
az deployment group what-if \
  --resource-group rg-webapp-prod-eastus-001 \
  --template-file template.json
```

### Moving Resources Between Resource Groups

```bash
# Check if a resource can be moved
# Not all resources support cross-RG moves — always check first!
az resource list --resource-group rg-webapp-dev-eastus-001 --query "[].id" --output tsv

# Move resources (specify the resource IDs)
RESOURCE_ID="/subscriptions/SUB_ID/resourceGroups/rg-source/providers/Microsoft.Storage/storageAccounts/mystorage"

az resource move \
  --destination-group rg-webapp-prod-eastus-001 \
  --ids $RESOURCE_ID

# Move multiple resources at once
az resource move \
  --destination-group rg-webapp-prod-eastus-001 \
  --ids $RESOURCE_ID1 $RESOURCE_ID2 $RESOURCE_ID3

# NOTE: During a move, resources are temporarily unavailable for writes
# Cross-subscription moves are also possible:
az resource move \
  --destination-group rg-destination \
  --destination-subscription-id TARGET_SUB_ID \
  --ids $RESOURCE_ID
```

---

## Part 4 — Azure Resource Providers

```bash
# Resource Providers are like AWS service namespaces
# Before using a service, its provider must be registered

# List all providers and their registration status
az provider list --output table

# Show specific provider details
az provider show --namespace Microsoft.Compute --output table

# Register a provider (required for first-time service use)
az provider register --namespace Microsoft.ContainerService  # AKS
az provider register --namespace Microsoft.Network           # Networking
az provider register --namespace Microsoft.Storage           # Storage
az provider register --namespace Microsoft.Sql               # SQL Database
az provider register --namespace Microsoft.KeyVault          # Key Vault
az provider register --namespace Microsoft.Web               # App Service
az provider register --namespace Microsoft.ContainerRegistry # ACR
az provider register --namespace Microsoft.OperationalInsights # Log Analytics
az provider register --namespace Microsoft.Insights          # Azure Monitor

# Check registration status
az provider show --namespace Microsoft.ContainerService --query registrationState --output tsv

# List operations available in a provider (for RBAC policy definition)
az provider operation show --namespace Microsoft.Compute --output table
```

---

## Part 5 — Tags Deep Dive (Cost Management Foundation)

```bash
# Tags are key-value pairs applied to resources
# Maximum: 50 tags per resource / resource group
# NOT inherited automatically from RG to resources (unlike AWS)

# List all unique tag names in subscription
az tag list --output table

# Apply tags to specific resources
az resource tag \
  --name myStorageAccount \
  --resource-group rg-webapp-prod-eastus-001 \
  --resource-type "Microsoft.Storage/storageAccounts" \
  --tags Environment=Production Project=WebApp

# Get resources by tag (like AWS resource tagging)
az resource list \
  --tag Environment=Production \
  --output table

# List all resources missing a specific tag
az resource list --query "[?tags.Environment==null].{Name:name, Type:type}" --output table

# Bulk tag update using PowerShell (Azure CLI doesn't support bulk tag well)
# Use Azure Policy for automatic tagging instead (Lab-03)
```

---

## Part 6 — Subscription-Level Deployments

```bash
# Some resources deploy at subscription level (not RG level):
# - Management Groups, Policies, RBAC at subscription scope

# Deploy at subscription scope
az deployment sub create \
  --location eastus \
  --template-file subscription-template.json

# Example: Create multiple RGs from subscription deployment
cat > create-rgs.json << 'EOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "resources": [
    {
      "type": "Microsoft.Resources/resourceGroups",
      "apiVersion": "2021-04-01",
      "name": "rg-app-eastus",
      "location": "eastus",
      "tags": {
        "Environment": "Production"
      }
    },
    {
      "type": "Microsoft.Resources/resourceGroups",
      "apiVersion": "2021-04-01",
      "name": "rg-data-eastus",
      "location": "eastus",
      "tags": {
        "Environment": "Production"
      }
    }
  ]
}
EOF

az deployment sub create \
  --location eastus \
  --template-file create-rgs.json
```

---

## Part 7 — Real-World Scenario: Multi-Environment Setup

```bash
#!/bin/bash
# Script: setup-environments.sh
# Creates a full multi-environment resource group structure

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
LOCATION="eastus"
PROJECT="myapp"
COMPANY="contoso"

# Define environments
declare -A ENVIRONMENTS=(
  ["dev"]="CC-DEV-001"
  ["test"]="CC-TEST-001"
  ["staging"]="CC-STG-001"
  ["prod"]="CC-PROD-001"
)

# Define workloads
WORKLOADS=("frontend" "backend" "database" "networking")

# Create resource groups for each environment/workload combination
for ENV in "${!ENVIRONMENTS[@]}"; do
  COST_CENTER=${ENVIRONMENTS[$ENV]}
  
  for WORKLOAD in "${WORKLOADS[@]}"; do
    RG_NAME="rg-${PROJECT}-${WORKLOAD}-${ENV}-${LOCATION}-001"
    
    echo "Creating: $RG_NAME"
    az group create \
      --name "$RG_NAME" \
      --location "$LOCATION" \
      --tags \
        Environment="$ENV" \
        Workload="$WORKLOAD" \
        Project="$PROJECT" \
        CostCenter="$COST_CENTER" \
        ManagedBy="terraform" \
        CreatedDate="$(date +%Y-%m-%d)" \
      --output none
    
    echo "✅ Created: $RG_NAME"
  done
done

echo ""
echo "All resource groups created:"
az group list --query "[?contains(name,'${PROJECT}')].{Name:name,Location:location,Tags:tags}" --output table
```

---

## Cleanup

```bash
#!/bin/bash
# Cleanup all lab resource groups

GROUPS_TO_DELETE=(
  "rg-webapp-prod-eastus-001"
  "rg-webapp-dev-eastus-001"
  "rg-networking-shared-eastus-001"
  "mg-platform"
  "mg-workloads"
  "mg-sandbox"
)

for RG in "${GROUPS_TO_DELETE[@]}"; do
  echo "Deleting: $RG"
  az group delete --name "$RG" --yes --no-wait 2>/dev/null || \
  az account management-group delete --name "$RG" 2>/dev/null || \
  echo "  (Not found or already deleted)"
done

echo "Cleanup initiated. Resources will be deleted in the background."
```

---

## ✅ Lab Checklist

- [ ] Viewed Management Group hierarchy
- [ ] Created nested Management Groups
- [ ] Listed all subscriptions
- [ ] Created Resource Groups with naming conventions
- [ ] Applied tags to resource groups
- [ ] Listed resources by tag
- [ ] Registered resource providers
- [ ] Moved a resource between RGs (conceptually)
- [ ] Created multi-environment RG structure via script

---

## 📚 Key Takeaways

1. **Resource Groups are mandatory** — every Azure resource MUST be in an RG
2. **Tags don't inherit** — apply tags at both RG and resource level, or use Azure Policy
3. **Management Groups = AWS OUs** — they contain subscriptions, not resources directly
4. **Subscriptions = AWS Accounts** — they are the billing boundary
5. **Resource Providers must be registered** — unlike AWS where services are always available
