# 🔐 Lab 01 — Azure Portal & CLI Orientation

**Difficulty:** 🟢 Beginner  
**Time:** 30 minutes  
**Goal:** Get comfortable navigating the Azure Portal and using the Azure CLI

---

## Background

The Azure Portal is your graphical control plane — equivalent to the AWS Console or GCP Cloud Console. The Azure CLI (`az`) is the command-line equivalent of `aws cli` or `gcloud`.

Key differences from AWS/GCP:
- Azure uses **Resource Groups** as mandatory containers for ALL resources (no resource exists outside an RG)
- Azure CLI is `az` not `aws` / `gcloud`
- Azure Cloud Shell (in-browser terminal) is available at https://shell.azure.com

---

## Lab Objectives

1. Navigate the Azure Portal dashboard
2. Use Azure Cloud Shell (bash & PowerShell)
3. Install and configure Azure CLI locally
4. List subscriptions, resource groups, and resources
5. Use `az find` and `az interactive` for discovery
6. Set default subscription and resource group

---

## Part 1 — Azure Portal Walkthrough

### Step 1: Access the Portal
1. Go to https://portal.azure.com
2. Sign in with your Azure account
3. Explore the **left navigation panel**:
   - **Home** — recent resources, pinned services
   - **Dashboard** — customizable overview
   - **All Services** — full service catalog (like AWS Console home)
   - **Resource Groups** — logical containers

### Step 2: Customize Dashboard
1. Click **Dashboard** → **Edit**
2. Add tiles: Resource Groups, Recent Resources, All Resources
3. Click **Done customizing**
4. Save the dashboard with your name

### Step 3: Use Azure Cloud Shell
1. Click the **Cloud Shell icon** (>_) in the top toolbar
2. Choose **Bash**
3. If first time, create a storage account when prompted
4. Try these commands:
```bash
# Check your account
az account show

# List all locations
az account list-locations --output table | head -20

# Check Azure CLI version
az --version
```

---

## Part 2 — Azure CLI Local Setup

### Step 1: Install Azure CLI
```powershell
# Windows — PowerShell (Admin)
winget install Microsoft.AzureCLI

# Or via MSI installer
# Download: https://aka.ms/installazurecliwindows
```

### Step 2: Login
```bash
# Interactive browser login
az login

# Login with service principal (for automation — like AWS access keys)
az login --service-principal \
  --username <app-id> \
  --password <password> \
  --tenant <tenant-id>

# Login with managed identity (for resources running in Azure — like EC2 instance profiles)
az login --identity
```

### Step 3: Configure defaults
```bash
# List all subscriptions
az account list --output table

# Set your active subscription (like AWS_PROFILE or CLOUDSDK_CORE_PROJECT)
az account set --subscription "Your-Subscription-Name-or-ID"

# Set default resource group and location (saves typing --resource-group every time)
az configure --defaults group=rg-mylab location=eastus

# View current config
az configure --list-defaults
```

---

## Part 3 — Exploring Resources via CLI

### Step 1: Create your first Resource Group
```bash
# Resource Groups are MANDATORY containers — no AWS equivalent
# Think of them as a logical folder for related resources
az group create \
  --name rg-az104-lab01 \
  --location eastus \
  --tags Environment=Lab Project=AZ104 Owner=YourName

# Verify
az group show --name rg-az104-lab01 --output table
```

### Step 2: List and Filter Resources
```bash
# List all resource groups
az group list --output table

# List with JMESPath query (like AWS --query or gcloud --filter)
az group list --query "[?location=='eastus'].{Name:name, Location:location}" --output table

# List all resources in a group
az resource list --resource-group rg-az104-lab01 --output table

# List all resources across subscription
az resource list --output table
```

### Step 3: Use az find (AI-powered discovery)
```bash
# Find commands related to a topic
az find "how to create a virtual machine"
az find "storage account"
az find "AKS cluster"
```

### Step 4: Use az interactive (auto-complete shell)
```bash
# Launch interactive mode (like aws-shell)
az interactive
# Type 'group' to see group subcommands
# Use Tab for auto-complete
# Type exit to quit
```

---

## Part 4 — Azure CLI Output Formats

```bash
# Table format (human readable)
az group list --output table

# JSON format (default, great for scripting)
az group list --output json

# YAML format
az group list --output yaml

# TSV format (great for piping to awk/cut)
az group list --output tsv

# JSON with specific fields using JMESPath
az group list --query "[].{Name:name,Location:location,State:properties.provisioningState}" --output table

# Compact JSON (single line)
az group list --output jsonc
```

---

## Part 5 — Azure Resource Manager Concepts

```bash
# Every Azure resource has a Resource ID (like an ARN in AWS)
# Format: /subscriptions/{subId}/resourceGroups/{rgName}/providers/{namespace}/{type}/{name}

# Get your subscription ID
az account show --query id --output tsv

# Get full resource ID of a resource group
az group show --name rg-az104-lab01 --query id --output tsv

# Use resource ID for operations
RESOURCE_ID=$(az group show --name rg-az104-lab01 --query id --output tsv)
echo $RESOURCE_ID
```

---

## Part 6 — Azure Regions & Availability Zones

```bash
# List all Azure regions
az account list-locations --output table

# List regions with availability zones
az account list-locations --query "[?not_null(availabilityZoneMappings)].{Region:name, DisplayName:displayName}" --output table

# Common regions used in labs:
# eastus        — US East (Virginia) [largest, most services]
# westus2       — US West 2 (Washington)
# westeurope    — Netherlands
# northeurope   — Ireland
# eastasia      — Hong Kong
# southeastasia — Singapore

# Check if a specific service is available in a region
az provider show --namespace Microsoft.Compute --query "resourceTypes[?resourceType=='virtualMachines'].locations" --output table
```

---

## Part 7 — Useful Aliases and Shell Configuration

```bash
# Add to ~/.bashrc or ~/.zshrc for convenience
alias azl="az account list --output table"
alias azs="az account show"
alias azrg="az group list --output table"

# Set environment variables
export AZURE_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
export AZURE_RESOURCE_GROUP="rg-az104-lab01"

# Create a helper function
azset() {
  az account set --subscription "$1"
  echo "Switched to subscription: $1"
  az account show --query "{Name:name, SubscriptionId:id}" --output table
}
```

---

## Cleanup

```bash
# Delete the lab resource group and all resources within it
az group delete --name rg-az104-lab01 --yes --no-wait

# Verify deletion (may take a minute)
az group list --output table
```

---

## ✅ Lab Checklist

- [ ] Accessed Azure Portal and customized dashboard
- [ ] Used Azure Cloud Shell (Bash mode)
- [ ] Installed Azure CLI locally
- [ ] Logged in with `az login`
- [ ] Set active subscription
- [ ] Created a Resource Group with tags
- [ ] Listed resources using different output formats
- [ ] Used JMESPath queries to filter output
- [ ] Used `az find` for command discovery
- [ ] Explored Azure regions

---

## 📚 Key Takeaways

| Azure Concept | AWS/GCP Equivalent | Notes |
|---|---|---|
| Resource Group | N/A (AWS uses tags/accounts) | Mandatory container, resources must belong to one RG |
| Subscription | AWS Account / GCP Project | Billing boundary |
| Tenant | AWS Organization / GCP Org | Azure AD identity boundary |
| Management Group | AWS OU / GCP Folder | Hierarchical policy container |
| Resource ID | ARN (AWS) / Resource URI (GCP) | Full path identifier |
| Azure CLI `az` | `aws` / `gcloud` | Similar patterns, different syntax |

---

## 🔗 Further Reading
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure Portal Documentation](https://docs.microsoft.com/en-us/azure/azure-portal/)
- [JMESPath Query Tutorial](https://jmespath.org/tutorial.html)
