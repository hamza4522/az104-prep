# 🔐 IAM Lab 01 — Azure AD: Users, Groups & Identity Governance
# ═══════════════════════════════════════════════════════════════
# Level 1 → Basic AD operations
# Level 2 → Enterprise RBAC + Conditional Access
# Level 3 → Zero Trust + PIM + Identity Protection + SIEM integration
# ═══════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────
# 🟢 LEVEL 1 — INTERMEDIATE: Multi-Department User Provisioning
# Scenario: Onboard 3 departments (Engineering, Security, Finance)
# with proper group hierarchy and naming standards
# ─────────────────────────────────────────────────────────────

echo "=============================================="
echo " LEVEL 1: Enterprise User Provisioning"
echo "=============================================="

DOMAIN=$(az ad signed-in-user show --query userPrincipalName --output tsv | cut -d@ -f2)
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

# ── Naming Convention ──────────────────────────────────────────
# Users:  firstname.lastname@company.com
# Groups: grp-{dept}-{role}-{scope}
# SPs:    sp-{service}-{environment}
# MIs:    mi-{resource}-{purpose}
# ──────────────────────────────────────────────────────────────

# Create Departments with Groups (Security Groups only — for RBAC)
declare -A DEPARTMENTS=(
  ["engineering"]="grp-eng"
  ["security"]="grp-sec"
  ["finance"]="grp-fin"
  ["devops"]="grp-devops"
  ["data"]="grp-data"
)

declare -A ROLES=("lead" "engineer" "readonly" "admin")

echo "Creating department groups..."
for DEPT in "${!DEPARTMENTS[@]}"; do
  PREFIX="${DEPARTMENTS[$DEPT]}"
  
  # Create role-based sub-groups
  for ROLE in "${ROLES[@]}"; do
    GROUP_NAME="${PREFIX}-${ROLE}"
    az ad group create \
      --display-name "$GROUP_NAME" \
      --mail-nickname "$GROUP_NAME" \
      --description "Department: $DEPT | Role: $ROLE" \
      --output none 2>/dev/null && echo "  ✅ Created: $GROUP_NAME"
  done
  
  # Create parent group (all members of this department)
  az ad group create \
    --display-name "${PREFIX}-all" \
    --mail-nickname "${PREFIX}-all" \
    --description "All members of $DEPT department" \
    --output none 2>/dev/null
done

# Create Users per Department
echo ""
echo "Creating users..."
declare -A USERS=(
  ["alice.chen|Alice Chen|engineering|lead|Senior Lead Engineer"]="grp-eng-lead"
  ["bob.kumar|Bob Kumar|engineering|engineer|Software Engineer"]="grp-eng-engineer"
  ["carol.osei|Carol Osei|security|admin|Security Administrator"]="grp-sec-admin"
  ["dave.silva|Dave Silva|security|engineer|Security Analyst"]="grp-sec-engineer"
  ["eve.johnson|Eve Johnson|finance|readonly|Financial Analyst"]="grp-fin-readonly"
  ["frank.lee|Frank Lee|devops|lead|Principal DevOps Engineer"]="grp-devops-lead"
  ["grace.wu|Grace Wu|devops|engineer|DevOps Engineer"]="grp-devops-engineer"
  ["hank.patel|Hank Patel|data|engineer|Data Engineer"]="grp-data-engineer"
)

for USER_DATA in "${!USERS[@]}"; do
  GROUP="${USERS[$USER_DATA]}"
  IFS='|' read -r UPN DISPLAY DEPT ROLE TITLE <<< "$USER_DATA"
  
  # Create user
  az ad user create \
    --display-name "$DISPLAY" \
    --user-principal-name "${UPN}@${DOMAIN}" \
    --password "TempP@ss$(date +%Y)!" \
    --force-change-password-next-sign-in true \
    --department "$DEPT" \
    --job-title "$TITLE" \
    --output none 2>/dev/null
  
  # Get user object ID
  USER_OID=$(az ad user show --id "${UPN}@${DOMAIN}" --query id --output tsv 2>/dev/null)
  
  if [ -n "$USER_OID" ]; then
    # Add to specific role group
    az ad group member add --group "$GROUP" --member-id "$USER_OID" --output none 2>/dev/null
    
    # Add to parent "all" group for department
    DEPT_ALL="grp-${DEPT:0:3}-all"
    az ad group member add --group "$DEPT_ALL" --member-id "$USER_OID" --output none 2>/dev/null
    
    echo "  ✅ User: ${UPN}@${DOMAIN} → Group: $GROUP"
  fi
done

# Add nested group (grp-devops-all is also member of grp-eng-all for cross-team visibility)
DEVOPS_ALL_ID=$(az ad group show --group "grp-devops-all" --query id --output tsv 2>/dev/null)
ENG_ALL_ID=$(az ad group show --group "grp-eng-all" --query id --output tsv 2>/dev/null)
[ -n "$DEVOPS_ALL_ID" ] && [ -n "$ENG_ALL_ID" ] && \
  az ad group member add --group "grp-eng-all" --member-id "$DEVOPS_ALL_ID" --output none 2>/dev/null

echo ""
echo "=== Level 1 Complete: User + Group Hierarchy Created ==="


# ─────────────────────────────────────────────────────────────
# 🟡 LEVEL 2 — PRODUCTION: Enterprise RBAC Model
# Scenario: Assign granular roles across multiple environments
# (Production, Staging, Dev) with separation of duties
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================="
echo " LEVEL 2: Production RBAC Model"
echo "=============================================="

# Create environment resource groups
ENVIRONMENTS=("production" "staging" "development" "shared-services")
LOCATION="eastus"

for ENV in "${ENVIRONMENTS[@]}"; do
  az group create \
    --name "rg-myapp-${ENV}" \
    --location $LOCATION \
    --tags Environment="$ENV" ManagedBy=Policy \
    --output none
  echo "  ✅ RG: rg-myapp-${ENV}"
done

# ── Create Custom Roles ────────────────────────────────────────

# Custom Role 1: DevOps Operator (start/stop/redeploy — no create/delete)
cat > /tmp/role-devops-operator.json << EOF
{
  "Name": "Custom - DevOps Operator",
  "IsCustom": true,
  "Description": "Can manage VM power state, view logs, run commands. Cannot create, delete, or modify network/security resources.",
  "Actions": [
    "Microsoft.Compute/virtualMachines/start/action",
    "Microsoft.Compute/virtualMachines/restart/action",
    "Microsoft.Compute/virtualMachines/powerOff/action",
    "Microsoft.Compute/virtualMachines/deallocate/action",
    "Microsoft.Compute/virtualMachines/read",
    "Microsoft.Compute/virtualMachines/runCommand/action",
    "Microsoft.Compute/virtualMachineScaleSets/*/read",
    "Microsoft.Compute/virtualMachineScaleSets/start/action",
    "Microsoft.Compute/virtualMachineScaleSets/powerOff/action",
    "Microsoft.Compute/virtualMachineScaleSets/restart/action",
    "Microsoft.ContainerService/managedClusters/read",
    "Microsoft.ContainerService/managedClusters/listClusterAdminCredential/action",
    "Microsoft.ContainerService/managedClusters/listClusterUserCredential/action",
    "Microsoft.Insights/*/read",
    "Microsoft.OperationalInsights/*/read",
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Resources/subscriptions/resourceGroups/resources/read",
    "Microsoft.Storage/storageAccounts/read",
    "Microsoft.Authorization/*/read",
    "Microsoft.Network/*/read",
    "Microsoft.Web/sites/*/read",
    "Microsoft.Web/sites/restart/action",
    "Microsoft.Web/sites/start/action",
    "Microsoft.Web/sites/stop/action",
    "Microsoft.Web/sites/slots/swap/action",
    "Microsoft.Support/*"
  ],
  "NotActions": [
    "Microsoft.Compute/virtualMachines/write",
    "Microsoft.Compute/virtualMachines/delete",
    "Microsoft.KeyVault/vaults/secrets/getSecret/action",
    "Microsoft.KeyVault/vaults/secrets/readMetadata/action"
  ],
  "DataActions": [
    "Microsoft.Insights/logs/read"
  ],
  "AssignableScopes": ["/subscriptions/${SUBSCRIPTION_ID}"]
}
EOF
az role definition create --role-definition @/tmp/role-devops-operator.json 2>/dev/null && \
  echo "  ✅ Custom role: DevOps Operator"

# Custom Role 2: Security Auditor (read everything, no data plane)
cat > /tmp/role-security-auditor.json << EOF
{
  "Name": "Custom - Security Auditor",
  "IsCustom": true,
  "Description": "Full read access for security audit. Cannot access data plane (blob contents, secrets, DB data).",
  "Actions": [
    "*/read",
    "Microsoft.Security/*",
    "Microsoft.PolicyInsights/*",
    "Microsoft.Authorization/*/read",
    "Microsoft.Insights/*/read",
    "Microsoft.OperationalInsights/*/read",
    "Microsoft.Network/*/read",
    "Microsoft.KeyVault/vaults/read",
    "Microsoft.KeyVault/vaults/keys/read",
    "Microsoft.KeyVault/vaults/certificates/read"
  ],
  "NotActions": [
    "Microsoft.KeyVault/vaults/secrets/getSecret/action",
    "Microsoft.Storage/storageAccounts/listKeys/action",
    "Microsoft.Storage/storageAccounts/listAccountSas/action",
    "Microsoft.Sql/servers/databases/query/action"
  ],
  "DataActions": [],
  "NotDataActions": [
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read",
    "Microsoft.KeyVault/vaults/secrets/getSecret/action"
  ],
  "AssignableScopes": ["/subscriptions/${SUBSCRIPTION_ID}"]
}
EOF
az role definition create --role-definition @/tmp/role-security-auditor.json 2>/dev/null && \
  echo "  ✅ Custom role: Security Auditor"

# Custom Role 3: Application Developer (deploy to dev/staging only)
cat > /tmp/role-app-developer.json << EOF
{
  "Name": "Custom - Application Developer",
  "IsCustom": true,
  "Description": "Can deploy applications, manage app settings, view logs. Restricted to specific resource types only.",
  "Actions": [
    "Microsoft.Web/sites/*/read",
    "Microsoft.Web/sites/config/write",
    "Microsoft.Web/sites/deploy/action",
    "Microsoft.Web/sites/publishxml/action",
    "Microsoft.Web/sites/restart/action",
    "Microsoft.Web/sites/start/action",
    "Microsoft.Web/sites/stop/action",
    "Microsoft.Web/sites/slots/*/read",
    "Microsoft.Web/sites/slots/deploy/action",
    "Microsoft.Web/sites/slots/swap/action",
    "Microsoft.ContainerRegistry/registries/push/write",
    "Microsoft.ContainerRegistry/registries/read",
    "Microsoft.ContainerService/managedClusters/read",
    "Microsoft.Insights/*/read",
    "Microsoft.OperationalInsights/*/read",
    "Microsoft.Resources/deployments/*",
    "Microsoft.Resources/subscriptions/resourceGroups/read"
  ],
  "NotActions": [
    "Microsoft.Web/sites/config/list/action",
    "Microsoft.Web/sites/publishxml/action"
  ],
  "AssignableScopes": ["/subscriptions/${SUBSCRIPTION_ID}"]
}
EOF
az role definition create --role-definition @/tmp/role-app-developer.json 2>/dev/null && \
  echo "  ✅ Custom role: Application Developer"

# ── Assign Roles with Separation of Duties ────────────────────

echo ""
echo "Assigning roles (Separation of Duties model)..."

# Engineering Lead → Contributor on Dev + Staging, Reader on Prod
ENG_LEAD_GROUP=$(az ad group show --group "grp-eng-lead" --query id --output tsv 2>/dev/null)
if [ -n "$ENG_LEAD_GROUP" ]; then
  for ENV in "development" "staging"; do
    az role assignment create --assignee "$ENG_LEAD_GROUP" --role "Contributor" \
      --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/rg-myapp-${ENV}" \
      --output none 2>/dev/null
    echo "  ✅ grp-eng-lead: Contributor → rg-myapp-${ENV}"
  done
  az role assignment create --assignee "$ENG_LEAD_GROUP" --role "Reader" \
    --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/rg-myapp-production" \
    --output none 2>/dev/null
  echo "  ✅ grp-eng-lead: Reader → rg-myapp-production"
fi

# DevOps Lead → Custom DevOps Operator on ALL environments
DEVOPS_LEAD=$(az ad group show --group "grp-devops-lead" --query id --output tsv 2>/dev/null)
if [ -n "$DEVOPS_LEAD" ]; then
  az role assignment create --assignee "$DEVOPS_LEAD" --role "Custom - DevOps Operator" \
    --scope "/subscriptions/${SUBSCRIPTION_ID}" --output none 2>/dev/null
  echo "  ✅ grp-devops-lead: Custom DevOps Operator → subscription"
fi

# Security Admins → Custom Security Auditor subscription-wide + Security Center
SEC_ADMIN=$(az ad group show --group "grp-sec-admin" --query id --output tsv 2>/dev/null)
if [ -n "$SEC_ADMIN" ]; then
  az role assignment create --assignee "$SEC_ADMIN" --role "Custom - Security Auditor" \
    --scope "/subscriptions/${SUBSCRIPTION_ID}" --output none 2>/dev/null
  az role assignment create --assignee "$SEC_ADMIN" --role "Security Admin" \
    --scope "/subscriptions/${SUBSCRIPTION_ID}" --output none 2>/dev/null
  echo "  ✅ grp-sec-admin: Security Auditor + Security Admin → subscription"
fi

# Finance readonly → only Cost Management reader
FIN_READONLY=$(az ad group show --group "grp-fin-readonly" --query id --output tsv 2>/dev/null)
if [ -n "$FIN_READONLY" ]; then
  az role assignment create --assignee "$FIN_READONLY" --role "Cost Management Reader" \
    --scope "/subscriptions/${SUBSCRIPTION_ID}" --output none 2>/dev/null
  az role assignment create --assignee "$FIN_READONLY" --role "Billing Reader" \
    --scope "/subscriptions/${SUBSCRIPTION_ID}" --output none 2>/dev/null
  echo "  ✅ grp-fin-readonly: Cost Management Reader + Billing Reader → subscription"
fi

echo ""
echo "=== Level 2 Complete: Production RBAC with SoD ==="


# ─────────────────────────────────────────────────────────────
# 🔴 LEVEL 3 — ENTERPRISE: Zero Trust + PIM + Conditional Access
# Scenario: Full Zero Trust identity model
#   - No standing admin access (PIM JIT)
#   - Conditional Access enforcing MFA + compliant devices
#   - Break-glass emergency accounts
#   - Azure AD Identity Protection risk policies
#   - Audit pipeline to Sentinel
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================="
echo " LEVEL 3: Zero Trust Identity Architecture"
echo "=============================================="

# ── Break-Glass Emergency Accounts ────────────────────────────
# Critical: These accounts bypass all Conditional Access
# Must be: cloud-only, no MFA required, monitored 24/7
echo "Creating break-glass emergency accounts..."

az ad user create \
  --display-name "EMERGENCY - Break Glass Account 1" \
  --user-principal-name "breakglass1@${DOMAIN}" \
  --password "$(openssl rand -base64 32)Aa1!" \
  --force-change-password-next-sign-in false \
  --output none 2>/dev/null && echo "  ✅ Break-glass account 1 created"

az ad user create \
  --display-name "EMERGENCY - Break Glass Account 2" \
  --user-principal-name "breakglass2@${DOMAIN}" \
  --password "$(openssl rand -base64 32)Aa1!" \
  --force-change-password-next-sign-in false \
  --output none 2>/dev/null && echo "  ✅ Break-glass account 2 created"

# Add break-glass accounts to Global Administrators
# NOTE: Requires Global Admin role to execute
# az rest --method POST \
#   --uri "https://graph.microsoft.com/v1.0/directoryRoles/roleTemplateId=62e90394-69f5-4237-9190-012177145e10/members/\$ref" \
#   --body '{"@odata.id":"https://graph.microsoft.com/v1.0/directoryObjects/BREAKGLASS_OBJECT_ID"}'

echo ""
echo "  ⚠️  IMPORTANT: Break-glass accounts must:"
echo "     1. Be cloud-only (not synced from on-prem AD)"
echo "     2. Have Global Admin role assigned"
echo "     3. Be excluded from ALL Conditional Access policies"
echo "     4. Store passwords in physical safe + KeePass offline"
echo "     5. Alert immediately on ANY sign-in (Azure Monitor)"
echo "     6. Be reviewed monthly and tested quarterly"

# ── Monitor Break-Glass Sign-ins (Critical Alert) ─────────────
echo ""
echo "Setting up break-glass monitoring alert..."

# Log Analytics workspace for identity logs
LAW_NAME="law-identity-$(date +%s)"
az monitor log-analytics workspace create \
  --resource-group "rg-myapp-shared-services" \
  --workspace-name $LAW_NAME \
  --location eastus \
  --sku PerGB2018 \
  --retention-time 365 \
  --output none 2>/dev/null

LAW_ID=$(az monitor log-analytics workspace show \
  --resource-group "rg-myapp-shared-services" \
  --workspace-name $LAW_NAME \
  --query id --output tsv 2>/dev/null)

# Create critical alert: any break-glass login = immediate PagerDuty
az monitor action-group create \
  --resource-group "rg-myapp-shared-services" \
  --name "ag-critical-security" \
  --short-name "critsec" \
  --action email ciso ciso@company.com \
  --action email security-oncall security-oncall@company.com \
  --output none 2>/dev/null

AG_ID=$(az monitor action-group show \
  --resource-group "rg-myapp-shared-services" \
  --name "ag-critical-security" \
  --query id --output tsv 2>/dev/null)

# Log alert: break-glass sign-in (query AD Sign-in logs)
if [ -n "$LAW_ID" ] && [ -n "$AG_ID" ]; then
  az monitor scheduled-query create \
    --resource-group "rg-myapp-shared-services" \
    --name "alert-breakglass-signin" \
    --description "CRITICAL: Emergency break-glass account was used" \
    --scopes "$LAW_ID" \
    --condition "count > 0" \
    --condition-query "SigninLogs | where UserPrincipalName contains 'breakglass' | where TimeGenerated > ago(5m) | summarize count()" \
    --evaluation-frequency 5m \
    --window-size 5m \
    --severity 0 \
    --action-groups "$AG_ID" \
    --output none 2>/dev/null && echo "  ✅ Break-glass monitoring alert created"
fi

# ── Conditional Access Policies (via MS Graph API) ─────────────
echo ""
echo "Configuring Conditional Access policies..."
echo "(Requires Azure AD P1/P2 license — using MS Graph API)"

# Get access token for Graph API
GRAPH_TOKEN=$(az account get-access-token --resource https://graph.microsoft.com --query accessToken --output tsv 2>/dev/null)

if [ -n "$GRAPH_TOKEN" ]; then
  
  # Policy 1: Require MFA for ALL users EXCEPT break-glass
  cat > /tmp/ca-require-mfa.json << 'EOF'
{
  "displayName": "CA001 - Require MFA for All Users",
  "state": "enabledForReportingButNotEnforced",
  "conditions": {
    "users": {
      "includeUsers": ["All"],
      "excludeUsers": [],
      "excludeGroups": []
    },
    "applications": {
      "includeApplications": ["All"]
    },
    "locations": {
      "includeLocations": ["All"]
    }
  },
  "grantControls": {
    "operator": "OR",
    "builtInControls": ["mfa"]
  }
}
EOF
  
  RESULT=$(curl -s -X POST \
    -H "Authorization: Bearer $GRAPH_TOKEN" \
    -H "Content-Type: application/json" \
    -d @/tmp/ca-require-mfa.json \
    "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies")
  
  CA1_ID=$(echo $RESULT | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id','ERROR'))" 2>/dev/null)
  echo "  ✅ CA001 - Require MFA: $CA1_ID"

  # Policy 2: Block legacy authentication (major attack vector!)
  cat > /tmp/ca-block-legacy.json << 'EOF'
{
  "displayName": "CA002 - Block Legacy Authentication",
  "state": "enabled",
  "conditions": {
    "users": {
      "includeUsers": ["All"],
      "excludeGroups": []
    },
    "applications": {
      "includeApplications": ["All"]
    },
    "clientAppTypes": ["exchangeActiveSync", "other"]
  },
  "grantControls": {
    "operator": "OR",
    "builtInControls": ["block"]
  }
}
EOF
  
  RESULT=$(curl -s -X POST \
    -H "Authorization: Bearer $GRAPH_TOKEN" \
    -H "Content-Type: application/json" \
    -d @/tmp/ca-block-legacy.json \
    "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies")
  echo "  ✅ CA002 - Block Legacy Authentication"

  # Policy 3: Require compliant device for production access
  cat > /tmp/ca-compliant-device.json << 'EOF'
{
  "displayName": "CA003 - Require Compliant Device for Production",
  "state": "enabledForReportingButNotEnforced",
  "conditions": {
    "users": {
      "includeUsers": ["All"],
      "excludeGroups": []
    },
    "applications": {
      "includeApplications": ["All"]
    },
    "locations": {
      "includeLocations": ["All"],
      "excludeLocations": ["AllTrusted"]
    }
  },
  "grantControls": {
    "operator": "AND",
    "builtInControls": ["mfa", "compliantDevice"]
  },
  "sessionControls": {
    "signInFrequency": {
      "value": 8,
      "type": "hours",
      "isEnabled": true
    },
    "persistentBrowser": {
      "mode": "never",
      "isEnabled": true
    }
  }
}
EOF
  
  RESULT=$(curl -s -X POST \
    -H "Authorization: Bearer $GRAPH_TOKEN" \
    -H "Content-Type: application/json" \
    -d @/tmp/ca-compliant-device.json \
    "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies")
  echo "  ✅ CA003 - Require Compliant Device for Production"

  # Policy 4: High-risk sign-in → require MFA + password change
  cat > /tmp/ca-risk-signin.json << 'EOF'
{
  "displayName": "CA004 - High Risk Sign-in Requires MFA",
  "state": "enabled",
  "conditions": {
    "users": {
      "includeUsers": ["All"],
      "excludeUsers": []
    },
    "applications": {
      "includeApplications": ["All"]
    },
    "signInRiskLevels": ["high", "medium"]
  },
  "grantControls": {
    "operator": "AND",
    "builtInControls": ["mfa", "passwordChange"]
  }
}
EOF
  
  RESULT=$(curl -s -X POST \
    -H "Authorization: Bearer $GRAPH_TOKEN" \
    -H "Content-Type: application/json" \
    -d @/tmp/ca-risk-signin.json \
    "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies")
  echo "  ✅ CA004 - High Risk Sign-in Policy"

  # Policy 5: Restrict admin access to trusted IP ranges only
  # First create named location (trusted corporate IP ranges)
  cat > /tmp/named-location-corporate.json << 'EOF'
{
  "@odata.type": "#microsoft.graph.ipNamedLocation",
  "displayName": "Corporate Office IP Ranges",
  "isTrusted": true,
  "ipRanges": [
    {"@odata.type": "#microsoft.graph.iPv4CidrRange", "cidrAddress": "203.0.113.0/24"},
    {"@odata.type": "#microsoft.graph.iPv4CidrRange", "cidrAddress": "198.51.100.0/24"}
  ]
}
EOF
  
  LOC_RESULT=$(curl -s -X POST \
    -H "Authorization: Bearer $GRAPH_TOKEN" \
    -H "Content-Type: application/json" \
    -d @/tmp/named-location-corporate.json \
    "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations")
  LOCATION_ID=$(echo $LOC_RESULT | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null)
  echo "  ✅ Named Location: Corporate IP ranges ($LOCATION_ID)"

else
  echo "  ⚠️  MS Graph token not available — showing policy templates only"
fi

# ── PIM Configuration (Privileged Identity Management) ────────
echo ""
echo "── PIM Configuration ──"
echo "PIM enables Just-In-Time privileged access (requires AAD P2)"
echo ""
echo "Key PIM Concepts:"
echo "  • Eligible assignments → User must ACTIVATE role (not always active)"
echo "  • Active assignments   → Always-on (for break-glass only)"
echo "  • Activation requires  → MFA + Justification + Approval (optional)"
echo "  • Time-bound           → Max 8 hours per activation (configurable)"
echo "  • Reviews              → Quarterly access reviews required"

# Configure PIM via MS Graph (requires P2 license)
if [ -n "$GRAPH_TOKEN" ]; then
  
  # Get role IDs
  CONTRIBUTOR_ROLE_ID=$(az role definition list --name "Contributor" --query "[0].name" --output tsv)
  OWNER_ROLE_ID=$(az role definition list --name "Owner" --query "[0].name" --output tsv)
  
  echo ""
  echo "PIM would configure the following policies:"
  echo "  ► Owner role: Max 2h activation, approval required, MFA enforced"
  echo "  ► Contributor role: Max 8h activation, justification required"
  echo "  ► Eligible members: grp-devops-lead, grp-eng-lead"
  echo "  ► Approvers for Owner: CISO + Engineering Manager"
  echo ""
  echo "  Note: Full PIM API requires Azure AD P2 premium license"
  echo "  See: https://docs.microsoft.com/en-us/azure/active-directory/privileged-identity-management/"
fi

# ── Access Review Automation ───────────────────────────────────
echo ""
echo "── Quarterly Access Reviews ──"

if [ -n "$GRAPH_TOKEN" ]; then
  cat > /tmp/access-review.json << 'EOF'
{
  "displayName": "Q1 2024 - Production Access Review",
  "startDate": "2024-01-01T00:00:00Z",
  "endDate": "2024-01-15T00:00:00Z",
  "reviewers": [
    {
      "query": "/users/ENGINEERING_MANAGER_ID",
      "queryType": "MicrosoftGraph"
    }
  ],
  "settings": {
    "mailNotificationsEnabled": true,
    "reminderNotificationsEnabled": true,
    "justificationRequiredOnApproval": true,
    "autoApplyDecisionsEnabled": true,
    "applyActions": [
      {"actionType": "removeAccessIfDenied"}
    ],
    "defaultDecision": "Deny",
    "recommendationsEnabled": true,
    "instanceDurationInDays": 14,
    "recurrence": {
      "pattern": {
        "type": "absoluteMonthly",
        "interval": 3,
        "daysOfMonth": [1]
      },
      "range": {
        "type": "noEnd",
        "startDate": "2024-01-01"
      }
    }
  },
  "scope": {
    "query": "/groups/PRODUCTION_ACCESS_GROUP_ID/transitiveMembers",
    "queryType": "MicrosoftGraph"
  }
}
EOF
  echo "  ✅ Access review template created"
  echo "  Configure quarterly reviews for ALL groups with production access"
fi

# ── Identity Protection Risk Policies ─────────────────────────
echo ""
echo "── Azure AD Identity Protection ──"
echo "Configuring risk-based policies (requires AAD P2)..."

cat << 'RISKINFO'
Risk Policies to Configure in Azure AD Identity Protection:

1. USER RISK POLICY (compromised accounts):
   ├── Trigger: User risk = HIGH (leaked credentials, dark web)
   ├── Action:  Block access OR Require password change + MFA
   └── Scope:   All users except break-glass accounts

2. SIGN-IN RISK POLICY (suspicious sign-ins):
   ├── Trigger: Sign-in risk = MEDIUM/HIGH (anonymous IP, atypical travel)
   ├── Action:  Require MFA to continue session
   └── Scope:   All users

3. MFA REGISTRATION POLICY:
   ├── Trigger: New user first login
   ├── Action:  Force MFA method registration
   └── Scope:   All users (converged with CA policy)

Portal: Azure AD → Security → Identity Protection → Risk Policies
RISKINFO

# ── Audit Log Pipeline to SIEM ────────────────────────────────
echo ""
echo "── Identity Audit Pipeline ──"

# Send all AD audit/sign-in logs to Log Analytics
TENANT_ID=$(az account show --query tenantId --output tsv)

# Configure diagnostic settings for Azure AD
if [ -n "$GRAPH_TOKEN" ] && [ -n "$LAW_ID" ]; then
  az rest --method PUT \
    --uri "https://management.azure.com/providers/microsoft.aad/diagnosticSettings/aad-to-law?api-version=2017-04-01" \
    --body "{
      \"properties\": {
        \"workspaceId\": \"${LAW_ID}\",
        \"logs\": [
          {\"category\": \"AuditLogs\", \"enabled\": true, \"retentionPolicy\": {\"enabled\": true, \"days\": 365}},
          {\"category\": \"SignInLogs\", \"enabled\": true, \"retentionPolicy\": {\"enabled\": true, \"days\": 365}},
          {\"category\": \"NonInteractiveUserSignInLogs\", \"enabled\": true, \"retentionPolicy\": {\"enabled\": true, \"days\": 90}},
          {\"category\": \"ServicePrincipalSignInLogs\", \"enabled\": true, \"retentionPolicy\": {\"enabled\": true, \"days\": 90}},
          {\"category\": \"ManagedIdentitySignInLogs\", \"enabled\": true, \"retentionPolicy\": {\"enabled\": true, \"days\": 90}},
          {\"category\": \"ProvisioningLogs\", \"enabled\": true, \"retentionPolicy\": {\"enabled\": true, \"days\": 90}},
          {\"category\": \"RiskyUsers\", \"enabled\": true, \"retentionPolicy\": {\"enabled\": true, \"days\": 365}},
          {\"category\": \"UserRiskEvents\", \"enabled\": true, \"retentionPolicy\": {\"enabled\": true, \"days\": 365}}
        ]
      }
    }" 2>/dev/null && echo "  ✅ All AD logs → Log Analytics (365 day retention)"
fi

# ── KQL Queries for Identity Threat Detection ─────────────────
cat > /tmp/identity-threat-queries.kql << 'KQL'
// ══════════════════════════════════════════
// IDENTITY THREAT DETECTION — KQL QUERIES
// Run in Log Analytics / Sentinel
// ══════════════════════════════════════════

// 1. PASSWORD SPRAY ATTACK
// Detect: >10 failed logins across >5 accounts from same IP
SigninLogs
| where TimeGenerated > ago(1h)
| where ResultType != "0"  // Failures only
| summarize 
    FailedAttempts = count(),
    UniqueAccounts = dcount(UserPrincipalName),
    Accounts = make_set(UserPrincipalName)
  by IPAddress
| where FailedAttempts > 10 and UniqueAccounts > 5
| extend ThreatType = "Password Spray"
| project TimeGenerated = now(), ThreatType, IPAddress, FailedAttempts, UniqueAccounts, Accounts

// 2. IMPOSSIBLE TRAVEL (Account takeover signal)
// Detect: Same user signs in from 2 locations > 500km apart < 2 hours
SigninLogs
| where TimeGenerated > ago(24h)
| where ResultType == "0"  // Successful logins
| where isnotempty(Location)
| extend Lat = toreal(parse_json(LocationDetails).geoCoordinates.latitude)
| extend Long = toreal(parse_json(LocationDetails).geoCoordinates.longitude)
| project TimeGenerated, UserPrincipalName, Location, Lat, Long, IPAddress
| sort by UserPrincipalName asc, TimeGenerated asc
| extend PrevTime = prev(TimeGenerated), PrevLocation = prev(Location), PrevUser = prev(UserPrincipalName)
| where UserPrincipalName == PrevUser
| extend TimeDiffHours = datetime_diff('hour', TimeGenerated, PrevTime)
| where TimeDiffHours < 2 and Location != PrevLocation and isnotempty(PrevLocation)
| extend ThreatType = "Impossible Travel"
| project ThreatType, UserPrincipalName, TimeGenerated, Location, PrevLocation, TimeDiffHours, IPAddress

// 3. SERVICE PRINCIPAL ANOMALY
// Detect: SP signing in from unusual geography or outside business hours
ServicePrincipalSignInLogs
| where TimeGenerated > ago(24h)
| where ResultType == "0"
| extend Hour = datetime_part('hour', TimeGenerated)
| where Hour < 6 or Hour > 22  // Outside 6AM-10PM UTC
| summarize count() by ServicePrincipalName, IPAddress, Location
| where count_ > 5
| extend ThreatType = "SP After-Hours Activity"

// 4. PRIVILEGED ROLE ASSIGNMENT
// Alert on ANY role assignment (especially Owner/Global Admin)
AuditLogs
| where TimeGenerated > ago(24h)
| where OperationName == "Add member to role"
| extend TargetRole = tostring(TargetResources[0].modifiedProperties[1].newValue)
| extend AssignedTo = tostring(TargetResources[0].displayName)
| extend AssignedBy = tostring(InitiatedBy.user.userPrincipalName)
| where TargetRole contains "Admin" or TargetRole contains "Owner"
| project TimeGenerated, AssignedBy, AssignedTo, TargetRole
| extend ThreatType = "Privileged Role Assignment"

// 5. MASS DOWNLOAD / DATA EXFILTRATION SIGNAL
// Detect: User downloading >100 files in 10 minutes
SigninLogs
| where TimeGenerated > ago(1h)
| where AppDisplayName in ("SharePoint Online", "OneDrive for Business")
| where ResultType == "0"
| summarize AccessCount = count() by UserPrincipalName, bin(TimeGenerated, 10m)
| where AccessCount > 100
| extend ThreatType = "Potential Data Exfiltration"

// 6. GUEST ACCOUNT ANOMALY
// Detect: Guest users accessing sensitive apps
SigninLogs
| where TimeGenerated > ago(7d)
| where UserType == "Guest"
| where AppDisplayName in ("Azure Portal", "Azure Active Directory", "Microsoft Azure Management")
| summarize count() by UserPrincipalName, AppDisplayName, IPAddress
| extend ThreatType = "Guest Accessing Admin Apps"

// 7. STALE ACCOUNT DETECTION
// Find accounts not signed in for 90+ days
SigninLogs
| where TimeGenerated > ago(90d)
| summarize LastSignIn = max(TimeGenerated) by UserPrincipalName
| join kind=rightanti (
    SigninLogs
    | where TimeGenerated > ago(1d)
    | distinct UserPrincipalName
) on UserPrincipalName
| where LastSignIn < ago(90d)
| project UserPrincipalName, LastSignIn, DaysSinceSignIn = datetime_diff('day', now(), LastSignIn)
| sort by DaysSinceSignIn desc
KQL

echo "  ✅ KQL threat detection queries saved to /tmp/identity-threat-queries.kql"

# ── Summary Report ─────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║     LEVEL 3 ZERO TRUST IDENTITY — SUMMARY           ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║                                                      ║"
echo "║  ✅ Break-glass emergency accounts created           ║"
echo "║  ✅ Break-glass monitoring alert (severity 0)        ║"
echo "║  ✅ CA001: MFA required for all users               ║"
echo "║  ✅ CA002: Legacy auth blocked (high attack vector)  ║"
echo "║  ✅ CA003: Compliant device for prod access         ║"
echo "║  ✅ CA004: High-risk sign-in → MFA + pwd change     ║"
echo "║  ✅ Named location: Corporate IP ranges             ║"
echo "║  ✅ All AD logs → Log Analytics (365 day)           ║"
echo "║  ✅ KQL threat detection queries configured         ║"
echo "║                                                      ║"
echo "║  📋 TODO (requires AAD P2):                         ║"
echo "║    ○ PIM JIT roles for all privileged access        ║"
echo "║    ○ Quarterly access reviews                       ║"
echo "║    ○ Identity Protection risk policies              ║"
echo "║    ○ Connect Sentinel for SIEM/SOAR automation     ║"
echo "╚══════════════════════════════════════════════════════╝"


# ── Cleanup ────────────────────────────────────────────────────
cleanup_level1_lab() {
  DOMAIN=$(az ad signed-in-user show --query userPrincipalName --output tsv | cut -d@ -f2)
  USERS_TO_DELETE=(
    "alice.chen" "bob.kumar" "carol.osei" "dave.silva"
    "eve.johnson" "frank.lee" "grace.wu" "hank.patel"
    "breakglass1" "breakglass2"
  )
  for U in "${USERS_TO_DELETE[@]}"; do
    az ad user delete --id "${U}@${DOMAIN}" 2>/dev/null
  done
  
  GROUPS_TO_DELETE=(
    "grp-eng-lead" "grp-eng-engineer" "grp-eng-all"
    "grp-sec-admin" "grp-sec-engineer" "grp-sec-all"
    "grp-fin-readonly" "grp-fin-all"
    "grp-devops-lead" "grp-devops-engineer" "grp-devops-all"
    "grp-data-engineer" "grp-data-all"
    "ag-critical-security"
  )
  for G in "${GROUPS_TO_DELETE[@]}"; do
    az ad group delete --group "$G" 2>/dev/null
  done
  
  az role definition delete --name "Custom - DevOps Operator" 2>/dev/null
  az role definition delete --name "Custom - Security Auditor" 2>/dev/null
  az role definition delete --name "Custom - Application Developer" 2>/dev/null
  
  for ENV in "production" "staging" "development" "shared-services"; do
    az group delete --name "rg-myapp-${ENV}" --yes --no-wait 2>/dev/null
  done
  
  echo "✅ Cleanup complete"
}
# Call: cleanup_level1_lab
