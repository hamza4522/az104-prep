# 🏛️ Lab 02 — Azure Policy: Governance at Scale

**Difficulty:** 🔴 Advanced  
**Time:** 75 minutes  
**Goal:** Implement Azure Policy for compliance enforcement — the AWS Config Rules equivalent

---

## Background

| Concept | Azure Policy | AWS Config Rules | GCP Org Policy |
|---|---|---|---|
| Policy definition | JSON policy document | Lambda-based rule or managed rule | Constraint |
| Assignment scope | MG / Sub / RG / Resource | Account / Org | Org / Folder / Project |
| Auto-remediation | Remediation tasks | Config remediation | — |
| Deny effect | Yes | No (detect only) | Yes |
| Audit effect | Yes | Yes | Audit |
| Initiative | Policy Set (initiative) | Conformance Pack | Policy bundle |
| Built-in policies | 5000+ | 400+ | 200+ |
| Cost | Free | Pay per rule/evaluation | Free |

---

## Part 1 — Built-in Policies

```bash
RG="rg-policy-lab"
LOCATION="eastus"
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

az group create --name $RG --location $LOCATION

# List all built-in policies
az policy definition list \
  --query "[?policyType=='BuiltIn'].{Name:displayName, Mode:mode}" \
  --output table | head -30

# Search for specific policies
az policy definition list \
  --query "[?contains(displayName,'tag')].{Name:displayName, ID:name}" \
  --output table

az policy definition list \
  --query "[?contains(displayName,'location')].{Name:displayName, ID:name}" \
  --output table

az policy definition list \
  --query "[?contains(displayName,'encryption')].{Name:displayName, ID:name}" \
  --output table

# Show policy details
az policy definition show --name "Require a tag on resources" --output json

# Get specific built-in policy IDs
REQUIRE_TAG_ID=$(az policy definition list \
  --query "[?displayName=='Require a tag on resource groups'].name" \
  --output tsv)

ALLOWED_LOCATIONS_ID=$(az policy definition list \
  --query "[?displayName=='Allowed locations'].name" \
  --output tsv)
```

---

## Part 2 — Assign Built-in Policies

```bash
# =========================================
# Policy 1: Require specific tag on all resource groups
# =========================================
az policy assignment create \
  --name "require-environment-tag" \
  --display-name "Require Environment tag on Resource Groups" \
  --policy "96670d01-0a4d-4649-9c89-2d3bedcef605" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}" \
  --params '{"tagName": {"value": "Environment"}}' \
  --enforcement-mode Default

# =========================================
# Policy 2: Allowed locations — restrict where resources can be deployed
# =========================================
az policy assignment create \
  --name "allowed-locations-eastus" \
  --display-name "Allowed locations: East US and West US 2 only" \
  --policy "e56962a6-4747-49cd-b67b-bf8b01975c4f" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}" \
  --params '{"listOfAllowedLocations": {"value": ["eastus", "westus2", "global"]}}' \
  --enforcement-mode Default

# =========================================
# Policy 3: Not allowed resource types (deny creating expensive VMs)
# =========================================
az policy assignment create \
  --name "deny-expensive-vms" \
  --display-name "Deny creation of expensive VM sizes" \
  --policy "a08ec900-254a-4555-9bf5-e42af04b5c5c" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}" \
  --params '{"notAllowedResourceTypes": {"value": ["Microsoft.Compute/virtualMachines/Standard_M128s","Microsoft.Compute/virtualMachines/Standard_L80s_v2"]}}' \
  --enforcement-mode Default

# List policy assignments
az policy assignment list \
  --scope "/subscriptions/${SUBSCRIPTION_ID}" \
  --output table

# Test the policy (try to create an RG without the required tag)
az group create --name rg-test-policy --location eastus
# Should FAIL or be flagged non-compliant!
```

---

## Part 3 — Create Custom Policy Definitions

```bash
# =========================================
# Custom Policy 1: Require HTTPS on Storage Accounts
# =========================================
cat > policy-storage-https.json << 'EOF'
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Storage/storageAccounts"
      },
      {
        "field": "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly",
        "notEquals": true
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
EOF

az policy definition create \
  --name "custom-require-storage-https" \
  --display-name "Custom: Require HTTPS traffic for Storage Accounts" \
  --description "Denies creation of Storage Accounts without HTTPS-only enabled" \
  --rules @policy-storage-https.json \
  --mode All \
  --subscription $SUBSCRIPTION_ID

# =========================================
# Custom Policy 2: Require specific tags with allowed values
# =========================================
cat > policy-tags-validation.json << 'EOF'
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Compute/virtualMachines"
      },
      {
        "not": {
          "field": "tags['Environment']",
          "in": ["Production", "Staging", "Development", "Test"]
        }
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
EOF

az policy definition create \
  --name "custom-require-env-tag-values" \
  --display-name "Custom: VMs must have valid Environment tag" \
  --description "VMs must have Environment tag with valid value: Production, Staging, Development, or Test" \
  --rules @policy-tags-validation.json \
  --mode All

# =========================================
# Custom Policy 3: Allowed VM SKUs (restrict to cost-effective sizes)
# =========================================
cat > policy-allowed-vm-skus.json << 'EOF'
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Compute/virtualMachines"
      },
      {
        "not": {
          "field": "Microsoft.Compute/virtualMachines/sku.name",
          "in": [
            "Standard_B1s", "Standard_B2s", "Standard_B2ms",
            "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3",
            "Standard_E2s_v3", "Standard_E4s_v3",
            "Standard_F2s_v2", "Standard_F4s_v2"
          ]
        }
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
EOF

az policy definition create \
  --name "custom-allowed-vm-skus" \
  --display-name "Custom: Allowed VM SKUs — Cost Optimized" \
  --description "Only allows cost-effective VM sizes" \
  --rules @policy-allowed-vm-skus.json \
  --mode Indexed

# List custom policies
az policy definition list \
  --query "[?policyType=='Custom'].{Name:displayName, ID:name}" \
  --output table
```

---

## Part 4 — Policy Initiatives (Policy Sets)

```bash
# =========================================
# Create a Policy Initiative (like AWS Config Conformance Pack)
# Groups multiple policies into a single assignment
# =========================================

cat > initiative-security-baseline.json << EOF
{
  "policyDefinitions": [
    {
      "policyDefinitionId": "/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.Authorization/policyDefinitions/custom-require-storage-https",
      "policyDefinitionReferenceId": "storage-https-policy",
      "parameters": {}
    },
    {
      "policyDefinitionId": "/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.Authorization/policyDefinitions/custom-require-env-tag-values",
      "policyDefinitionReferenceId": "vm-env-tag-policy",
      "parameters": {}
    },
    {
      "policyDefinitionId": "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4f",
      "policyDefinitionReferenceId": "allowed-locations-policy",
      "parameters": {
        "listOfAllowedLocations": {
          "value": ["eastus", "westus2"]
        }
      }
    }
  ],
  "parameters": {},
  "policyDefinitionGroups": [
    {
      "name": "SECURITY",
      "displayName": "Security Policies",
      "description": "Policies enforcing security baselines"
    },
    {
      "name": "COST",
      "displayName": "Cost Management Policies",
      "description": "Policies controlling cost"
    }
  ]
}
EOF

az policy set-definition create \
  --name "initiative-security-baseline" \
  --display-name "Security Baseline Initiative" \
  --description "Baseline security policies for all subscriptions" \
  --definitions @initiative-security-baseline.json \
  --subscription $SUBSCRIPTION_ID

# Assign the initiative
az policy assignment create \
  --name "assign-security-baseline" \
  --display-name "Assign Security Baseline Initiative" \
  --policy-set-definition "initiative-security-baseline" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}" \
  --enforcement-mode Default

echo "✅ Policy Initiative assigned"
```

---

## Part 5 — Policy Remediation (Auto-Fix)

```bash
# =========================================
# DeployIfNotExists effect with remediation
# Automatically add missing tags to resources
# =========================================

cat > policy-auto-tag.json << 'EOF'
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Compute/virtualMachines"
      },
      {
        "field": "tags['Environment']",
        "exists": false
      }
    ]
  },
  "then": {
    "effect": "modify",
    "details": {
      "roleDefinitionIds": [
        "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
      ],
      "operations": [
        {
          "operation": "add",
          "field": "tags['Environment']",
          "value": "Untagged"
        },
        {
          "operation": "add",
          "field": "tags['ManagedByPolicy']",
          "value": "true"
        }
      ]
    }
  }
}
EOF

az policy definition create \
  --name "custom-auto-tag-vms" \
  --display-name "Custom: Auto-tag VMs missing Environment tag" \
  --rules @policy-auto-tag.json \
  --mode Indexed

az policy assignment create \
  --name "auto-tag-vms" \
  --policy "custom-auto-tag-vms" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}" \
  --assign-identity \
  --identity-scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}" \
  --role "Contributor" \
  --location $LOCATION

# Get assignment ID
ASSIGNMENT_ID=$(az policy assignment show \
  --name "auto-tag-vms" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}" \
  --query id \
  --output tsv)

# Create remediation task (fix existing non-compliant resources)
az policy remediation create \
  --name "remediate-vm-tags" \
  --policy-assignment $ASSIGNMENT_ID \
  --resource-discovery-mode ReEvaluateCompliance

# Check remediation status
az policy remediation show \
  --name "remediate-vm-tags" \
  --output json
```

---

## Part 6 — Compliance Reporting

```bash
# Check compliance state
az policy state list \
  --resource-group $RG \
  --query "[].{Resource:resourceId, Policy:policyDefinitionName, Compliant:complianceState}" \
  --output table

# Check specific resource compliance
az policy state list \
  --resource "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}" \
  --output table

# Summarize compliance
az policy state summarize \
  --resource-group $RG \
  --output json

# Trigger compliance evaluation (don't wait for 24-hour cycle)
az policy state trigger-scan \
  --resource-group $RG

# List non-compliant resources
az policy state list \
  --resource-group $RG \
  --filter "complianceState eq 'NonCompliant'" \
  --query "[].{Resource:resourceId, Policy:policyDefinitionName}" \
  --output table
```

---

## Cleanup

```bash
# Remove policy assignments first
az policy assignment delete --name "require-environment-tag" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}"
az policy assignment delete --name "allowed-locations-eastus" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}"
az policy assignment delete --name "auto-tag-vms" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}"
az policy assignment delete --name "assign-security-baseline" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}"

# Remove custom policy definitions
az policy definition delete --name "custom-require-storage-https"
az policy definition delete --name "custom-require-env-tag-values"
az policy definition delete --name "custom-allowed-vm-skus"
az policy definition delete --name "custom-auto-tag-vms"
az policy set-definition delete --name "initiative-security-baseline"

# Remove resource group
az group delete --name rg-policy-lab --yes --no-wait

rm -f policy-*.json initiative-*.json
```

---

## ✅ Lab Checklist

- [ ] Listed and searched built-in policies
- [ ] Assigned "Require tag" built-in policy
- [ ] Assigned "Allowed locations" policy
- [ ] Created custom "Require HTTPS on Storage" policy (Deny effect)
- [ ] Created custom "VM environment tag values" policy
- [ ] Created custom "Allowed VM SKUs" policy
- [ ] Created Policy Initiative with multiple policies
- [ ] Assigned initiative to scope
- [ ] Created auto-remediation policy (Modify effect)
- [ ] Created remediation task for existing resources
- [ ] Checked compliance state and reports
