# 🔑 Lab 02 — RBAC: Built-in Roles & Custom Roles

**Difficulty:** 🟡 Intermediate  
**Time:** 60 minutes  
**Goal:** Master Azure RBAC — assign roles, create custom roles, understand scope inheritance

---

## Background

Azure RBAC (Role-Based Access Control) controls WHAT users/services can DO to resources.

**RBAC = Who + What + Where**
- **Who:** User, Group, Service Principal, or Managed Identity
- **What:** Role (collection of permissions called "actions")
- **Where:** Scope (Management Group, Subscription, Resource Group, or Resource)

**Comparison:**
- AWS IAM: Policies attached to identities or resources
- GCP IAM: Roles bound to principals at resource level
- Azure RBAC: Role assignments (principal + role + scope)

---

## Part 1 — Understanding Built-in Roles

```bash
# List ALL built-in roles
az role definition list --custom-role-only false --output table

# Count built-in roles
az role definition list --custom-role-only false --query "length(@)"
# Azure has 300+ built-in roles!

# Find roles by name
az role definition list --name "Contributor" --output json
az role definition list --name "Reader" --output json
az role definition list --name "Owner" --output json

# Search for service-specific roles
az role definition list \
  --query "[?contains(roleName,'Storage')].{Name:roleName, Description:description}" \
  --output table

az role definition list \
  --query "[?contains(roleName,'Virtual Machine')].{Name:roleName}" \
  --output table

# Show all actions in a role
az role definition list --name "Contributor" \
  --query "[0].permissions[0].actions" \
  --output json

# Show what a role CANNOT do (NotActions)
az role definition list --name "Contributor" \
  --query "[0].permissions[0].notActions" \
  --output json
```

### Key Built-in Roles Reference

```bash
# Show full details of key roles

# 1. Owner — Full access + can assign roles
az role definition list --name "Owner" \
  --query "[0].{Name:roleName, Actions:permissions[0].actions, NotActions:permissions[0].notActions}" \
  --output json

# 2. Contributor — Full access, NO role assignment
az role definition list --name "Contributor" \
  --query "[0].{Name:roleName, Actions:permissions[0].actions}" --output json

# 3. Reader — Read-only
az role definition list --name "Reader" \
  --query "[0].{Name:roleName, Actions:permissions[0].actions}" --output json

# 4. Storage Blob Data Contributor
az role definition list --name "Storage Blob Data Contributor" \
  --query "[0].{Name:roleName, Description:description, Actions:permissions[0].actions}" --output json

# 5. Virtual Machine Contributor
az role definition list --name "Virtual Machine Contributor" \
  --query "[0].{Name:roleName, Actions:permissions[0].actions}" --output json

# 6. Network Contributor
az role definition list --name "Network Contributor" --output json

# 7. Key Vault Secrets Officer
az role definition list --name "Key Vault Secrets Officer" --output json
```

---

## Part 2 — Assign Built-in Roles

### Setup

```bash
# Create resource group for this lab
az group create --name rg-rbac-lab --location eastus

# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
DOMAIN=$(az ad signed-in-user show --query userPrincipalName --output tsv | cut -d@ -f2)

# Create test users (if not already from Lab-01)
az ad user create \
  --display-name "RBAC Test User" \
  --user-principal-name "rbac-test@${DOMAIN}" \
  --password "TestP@ss2024!" \
  --force-change-password-next-sign-in false

TEST_USER_ID=$(az ad user show --id "rbac-test@${DOMAIN}" --query id --output tsv)
echo "Test User ID: $TEST_USER_ID"
```

### Assign Roles at Different Scopes

```bash
# 1. Assign Contributor at Resource Group scope
az role assignment create \
  --assignee "$TEST_USER_ID" \
  --role "Contributor" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/rg-rbac-lab"

# 2. Assign Reader at Subscription scope (broad — affects ALL RGs)
az role assignment create \
  --assignee "$TEST_USER_ID" \
  --role "Reader" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}"

# 3. Assign to a GROUP instead of individual user (best practice)
az ad group create \
  --display-name "grp-storage-admins" \
  --mail-nickname "grp-storage-admins"

GROUP_ID=$(az ad group show --group "grp-storage-admins" --query id --output tsv)

# Create a storage account first
az storage account create \
  --name "st$(date +%s)rbac" \
  --resource-group rg-rbac-lab \
  --location eastus \
  --sku Standard_LRS

STORAGE_ID=$(az storage account list --resource-group rg-rbac-lab --query "[0].id" --output tsv)

# Assign Storage Blob Data Contributor at resource scope (most granular)
az role assignment create \
  --assignee "$GROUP_ID" \
  --role "Storage Blob Data Contributor" \
  --scope "$STORAGE_ID"

echo "Role assignments created:"
az role assignment list --resource-group rg-rbac-lab --output table
```

### List Role Assignments

```bash
# List all assignments in a resource group
az role assignment list \
  --resource-group rg-rbac-lab \
  --output table

# List all assignments for a specific user
az role assignment list \
  --assignee "rbac-test@${DOMAIN}" \
  --all \
  --output table

# List assignments at subscription scope
az role assignment list \
  --scope "/subscriptions/${SUBSCRIPTION_ID}" \
  --output table

# List all assignments including inherited ones
az role assignment list \
  --resource-group rg-rbac-lab \
  --include-inherited \
  --output table

# JSON with full details
az role assignment list \
  --resource-group rg-rbac-lab \
  --include-inherited \
  --output json | python3 -m json.tool
```

---

## Part 3 — Remove Role Assignments

```bash
# Remove a specific role assignment
az role assignment delete \
  --assignee "rbac-test@${DOMAIN}" \
  --role "Contributor" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/rg-rbac-lab"

# Remove all assignments for a user
az role assignment list \
  --assignee "rbac-test@${DOMAIN}" \
  --all \
  --query "[].{Role:roleDefinitionName, Scope:scope}" \
  --output tsv | while IFS=$'\t' read -r ROLE SCOPE; do
    echo "Removing: $ROLE from $SCOPE"
    az role assignment delete \
      --assignee "rbac-test@${DOMAIN}" \
      --role "$ROLE" \
      --scope "$SCOPE"
done
```

---

## Part 4 — Create Custom Roles

### Scenario: DevOps team needs to:
- Start/Stop/Restart VMs
- Read all resources
- BUT cannot delete or create resources
- AND cannot see any key vault secrets

```bash
# Step 1: Export an existing role as a starting point
az role definition list --name "Virtual Machine Contributor" \
  --output json > vm-contributor-template.json

# Step 2: Create custom role definition file
cat > custom-role-devops-vm.json << 'EOF'
{
  "Name": "Custom - DevOps VM Operator",
  "IsCustom": true,
  "Description": "Can start, stop, restart, and deallocate VMs. Read access to all resources. Cannot create, delete, or access Key Vault secrets.",
  "Actions": [
    "Microsoft.Compute/virtualMachines/start/action",
    "Microsoft.Compute/virtualMachines/powerOff/action",
    "Microsoft.Compute/virtualMachines/restart/action",
    "Microsoft.Compute/virtualMachines/deallocate/action",
    "Microsoft.Compute/virtualMachines/read",
    "Microsoft.Compute/virtualMachines/instanceView/read",
    "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/start/action",
    "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/powerOff/action",
    "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/restart/action",
    "Microsoft.Network/networkInterfaces/read",
    "Microsoft.Network/publicIPAddresses/read",
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Resources/subscriptions/resourceGroups/resources/read",
    "Microsoft.Storage/storageAccounts/read",
    "Microsoft.Authorization/*/read",
    "Microsoft.Support/*"
  ],
  "NotActions": [
    "Microsoft.KeyVault/vaults/secrets/*"
  ],
  "DataActions": [],
  "NotDataActions": [],
  "AssignableScopes": [
    "/subscriptions/REPLACE_WITH_YOUR_SUBSCRIPTION_ID"
  ]
}
EOF

# Replace subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
sed -i "s/REPLACE_WITH_YOUR_SUBSCRIPTION_ID/$SUBSCRIPTION_ID/" custom-role-devops-vm.json

# Create the custom role
az role definition create --role-definition custom-role-devops-vm.json

# Verify creation
az role definition list --custom-role-only true --output table

# Show the new role
az role definition list --name "Custom - DevOps VM Operator" --output json
```

### Another Custom Role: Read-Only with Specific Restrictions

```bash
cat > custom-role-auditor.json << 'EOF'
{
  "Name": "Custom - Security Auditor",
  "IsCustom": true,
  "Description": "Read-only access to all resources for security audit. Can read Key Vault metadata but NOT secrets.",
  "Actions": [
    "*/read",
    "Microsoft.Security/*",
    "Microsoft.PolicyInsights/*",
    "Microsoft.Authorization/*/read"
  ],
  "NotActions": [
    "Microsoft.KeyVault/vaults/secrets/getSecret/action",
    "Microsoft.KeyVault/vaults/secrets/readMetadata/action"
  ],
  "DataActions": [],
  "NotDataActions": [],
  "AssignableScopes": [
    "/subscriptions/REPLACE_WITH_YOUR_SUBSCRIPTION_ID"
  ]
}
EOF

sed -i "s/REPLACE_WITH_YOUR_SUBSCRIPTION_ID/$SUBSCRIPTION_ID/" custom-role-auditor.json
az role definition create --role-definition custom-role-auditor.json
```

### Update a Custom Role

```bash
# Get the role ID first
ROLE_ID=$(az role definition list --name "Custom - DevOps VM Operator" --query "[0].name" --output tsv)

# Update the role (download → modify → update)
az role definition list --name "Custom - DevOps VM Operator" --output json > update-role.json

# Edit the JSON to add new permissions, then update:
az role definition update --role-definition update-role.json

# Delete a custom role
az role definition delete --name "Custom - DevOps VM Operator"
```

---

## Part 5 — RBAC Best Practices Workshop

### Scenario: Multi-team Azure subscription

```bash
#!/bin/bash
# Script: setup-rbac-model.sh
# Implements RBAC for a development team setup

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
RG="rg-production"

# Create resource groups
az group create --name rg-production --location eastus
az group create --name rg-staging --location eastus
az group create --name rg-development --location eastus
az group create --name rg-shared-services --location eastus

# Create groups
declare -A GROUPS=(
  ["grp-platform-owners"]="Platform team with Owner access"
  ["grp-app-contributors"]="App team with Contributor on dev/staging"
  ["grp-security-auditors"]="Security team with Reader + Security Center access"
  ["grp-cost-readers"]="Finance team with cost/billing read access"
)

for GROUP_NAME in "${!GROUPS[@]}"; do
  az ad group create \
    --display-name "$GROUP_NAME" \
    --mail-nickname "$GROUP_NAME" \
    --description "${GROUPS[$GROUP_NAME]}" \
    --output none
  echo "✅ Created group: $GROUP_NAME"
done

# Assign roles to groups (ALWAYS assign to groups, not individuals)

# Platform owners — Owner at subscription (full control)
PLATFORM_ID=$(az ad group show --group "grp-platform-owners" --query id --output tsv)
az role assignment create \
  --assignee "$PLATFORM_ID" \
  --role "Owner" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}"
echo "✅ Platform team: Owner at subscription"

# App contributors — Contributor on dev and staging only
APP_ID=$(az ad group show --group "grp-app-contributors" --query id --output tsv)
for RG_NAME in "rg-development" "rg-staging"; do
  az role assignment create \
    --assignee "$APP_ID" \
    --role "Contributor" \
    --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NAME}"
  echo "✅ App team: Contributor on $RG_NAME"
done

# Security auditors — Reader + Security Center Reader across everything
SECURITY_ID=$(az ad group show --group "grp-security-auditors" --query id --output tsv)
az role assignment create \
  --assignee "$SECURITY_ID" \
  --role "Reader" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}"
az role assignment create \
  --assignee "$SECURITY_ID" \
  --role "Security Reader" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}"
echo "✅ Security team: Reader + Security Reader at subscription"

# Cost readers — Billing Reader
COST_ID=$(az ad group show --group "grp-cost-readers" --query id --output tsv)
az role assignment create \
  --assignee "$COST_ID" \
  --role "Billing Reader" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}"
echo "✅ Finance team: Billing Reader"

echo ""
echo "=== RBAC Summary ==="
az role assignment list --scope "/subscriptions/${SUBSCRIPTION_ID}" \
  --query "[].{Principal:principalName, Role:roleDefinitionName, Scope:scope}" \
  --output table
```

---

## Part 6 — Verify Permissions (What-If)

```bash
# Check what actions a user can perform (access review)
az role assignment list \
  --assignee "rbac-test@${DOMAIN}" \
  --all \
  --include-inherited \
  --output table

# Test specific permission
az resource test-access \
  --resource-id "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/rg-production" \
  --permissions "Microsoft.Compute/virtualMachines/write"
```

---

## Cleanup

```bash
# Delete custom roles
az role definition delete --name "Custom - DevOps VM Operator" 2>/dev/null
az role definition delete --name "Custom - Security Auditor" 2>/dev/null

# Delete resource groups
az group delete --name rg-rbac-lab --yes --no-wait
az group delete --name rg-production --yes --no-wait
az group delete --name rg-staging --yes --no-wait
az group delete --name rg-development --yes --no-wait
az group delete --name rg-shared-services --yes --no-wait

# Delete test users and groups
az ad user delete --id "rbac-test@${DOMAIN}" 2>/dev/null
for G in "grp-platform-owners" "grp-app-contributors" "grp-security-auditors" "grp-cost-readers" "grp-storage-admins"; do
  az ad group delete --group "$G" 2>/dev/null
done
```

---

## ✅ Lab Checklist

- [ ] Listed all built-in roles and their permissions
- [ ] Assigned Contributor role at Resource Group scope
- [ ] Assigned Reader role at Subscription scope
- [ ] Assigned role to a group (not individual)
- [ ] Listed and verified role assignments
- [ ] Created a custom role with specific VM permissions
- [ ] Created a custom Security Auditor role
- [ ] Implemented multi-team RBAC model
- [ ] Removed role assignments

---

## 📚 Key RBAC Rules to Remember

1. **Assign to Groups, not individuals** — easier to manage at scale
2. **Use least privilege** — assign the minimum role needed
3. **Scope matters** — prefer narrow scope (RG or resource) over subscription
4. **Additive, never subtractive** — if you're Owner AND Reader, Owner wins
5. **NotActions ≠ Deny** — they just remove permissions from the role, but another role can grant them back
6. **Deny Assignments** — real denials (overrides everything) — used by Azure Blueprints
