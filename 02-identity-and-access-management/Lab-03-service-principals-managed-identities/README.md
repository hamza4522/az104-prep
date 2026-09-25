# 🤖 Lab 03 — Service Principals & Managed Identities

**Difficulty:** 🟡 Intermediate  
**Time:** 60 minutes  
**Goal:** Create service principals for automation and managed identities for Azure resources

---

## Background

| Identity Type | Use Case | AWS Equivalent | Credential Management |
|---|---|---|---|
| **User** | Human login | IAM User | Password + MFA |
| **Service Principal** | Applications, CI/CD, Terraform | IAM User with access keys | Client ID + Secret/Certificate |
| **Managed Identity (System)** | Azure resource acting on other Azure resources | EC2 Instance Profile | NONE — Azure manages it |
| **Managed Identity (User-assigned)** | Shared identity across multiple resources | IAM Role (reusable) | NONE — Azure manages it |

**Best Practice:** Use Managed Identities whenever possible (no secrets to manage!)

---

## Part 1 — Service Principals

### Create a Service Principal

```bash
# Method 1: Create SP with auto-generated secret (most common for CI/CD)
az ad sp create-for-rbac \
  --name "sp-terraform-prod" \
  --role Contributor \
  --scopes "/subscriptions/$(az account show --query id --output tsv)" \
  --sdk-auth

# Output (save securely! Secret shown only once):
# {
#   "clientId": "12345678-...",
#   "clientSecret": "abcdef...",
#   "subscriptionId": "...",
#   "tenantId": "..."
# }

# Method 2: Create SP WITHOUT role (assign roles separately)
az ad sp create-for-rbac \
  --name "sp-github-actions" \
  --skip-assignment \
  --years 2

# Method 3: Create SP with certificate (more secure than secret)
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout sp-cert.key \
  -out sp-cert.crt \
  -subj "/CN=sp-myapp"

# Create SP with certificate
az ad sp create-for-rbac \
  --name "sp-cert-based" \
  --cert @sp-cert.crt \
  --skip-assignment
```

### Manage Service Principals

```bash
# List all service principals
az ad sp list --output table

# Get specific SP details
az ad sp show --id "sp-terraform-prod"

# List by name
az ad sp list \
  --display-name "sp-terraform-prod" \
  --query "[].{Name:displayName, AppId:appId, ObjectId:id}" \
  --output table

# Get SP App ID (client ID)
SP_APP_ID=$(az ad sp list --display-name "sp-terraform-prod" --query "[0].appId" --output tsv)
echo "App ID: $SP_APP_ID"

# Get SP Object ID (for role assignments)
SP_OBJECT_ID=$(az ad sp list --display-name "sp-terraform-prod" --query "[0].id" --output tsv)
echo "Object ID: $SP_OBJECT_ID"
```

### Reset SP Credentials

```bash
# Reset secret (generates new secret, old one still works until expiry)
az ad sp credential reset \
  --id "sp-terraform-prod" \
  --append  # --append keeps existing credentials

# Reset and show new credentials
az ad sp credential reset \
  --id "sp-terraform-prod" \
  --years 1

# List current credentials (metadata only, not actual secrets)
az ad sp credential list --id "sp-terraform-prod" --output table

# Delete a specific credential
az ad sp credential delete \
  --id "sp-terraform-prod" \
  --key-id "CREDENTIAL_KEY_ID"
```

### Assign Roles to Service Principals

```bash
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
SP_APP_ID=$(az ad sp list --display-name "sp-github-actions" --query "[0].appId" --output tsv)

# Assign specific roles to specific scopes
# For CI/CD — Contributor on a specific RG only
az group create --name rg-app-deploy --location eastus

az role assignment create \
  --assignee "$SP_APP_ID" \
  --role "Contributor" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/rg-app-deploy"

# For Terraform state — Storage Blob Data Contributor on state storage only
az storage account create \
  --name "sttfstate$(date +%s)" \
  --resource-group rg-app-deploy \
  --location eastus \
  --sku Standard_LRS

TF_STORAGE_ID=$(az storage account list --resource-group rg-app-deploy --query "[0].id" --output tsv)

az role assignment create \
  --assignee "$SP_APP_ID" \
  --role "Storage Blob Data Contributor" \
  --scope "$TF_STORAGE_ID"

# Verify assignments
az role assignment list --assignee "$SP_APP_ID" --all --output table
```

---

## Part 2 — Login as Service Principal

```bash
# Login with client secret
SP_APP_ID="YOUR_APP_ID"
SP_SECRET="YOUR_SECRET"
TENANT_ID=$(az account show --query tenantId --output tsv)

az login --service-principal \
  --username "$SP_APP_ID" \
  --password "$SP_SECRET" \
  --tenant "$TENANT_ID"

# Login with certificate
az login --service-principal \
  --username "$SP_APP_ID" \
  --tenant "$TENANT_ID" \
  --certificate sp-cert.pem

# After testing, log back in as yourself
az login
```

---

## Part 3 — Managed Identities

### System-Assigned Managed Identity

```bash
# Create a VM with system-assigned managed identity
# (Identity is tied to VM lifecycle — deleted when VM is deleted)
az group create --name rg-managed-identity-lab --location eastus

az vm create \
  --resource-group rg-managed-identity-lab \
  --name vm-with-identity \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --assign-identity \
  --size Standard_B1s

# Check that identity was assigned
az vm identity show \
  --resource-group rg-managed-identity-lab \
  --name vm-with-identity

# Get the principal ID of the managed identity
IDENTITY_PRINCIPAL_ID=$(az vm identity show \
  --resource-group rg-managed-identity-lab \
  --name vm-with-identity \
  --query principalId \
  --output tsv)

echo "Managed Identity Principal ID: $IDENTITY_PRINCIPAL_ID"

# Assign role to the managed identity
# Example: Allow VM to read from a Key Vault
az role assignment create \
  --assignee "$IDENTITY_PRINCIPAL_ID" \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/$(az account show --query id --output tsv)"

# Assign role: Allow VM to read from storage
az role assignment create \
  --assignee "$IDENTITY_PRINCIPAL_ID" \
  --role "Storage Blob Data Reader" \
  --scope "/subscriptions/$(az account show --query id --output tsv)/resourceGroups/rg-managed-identity-lab"
```

### Using Managed Identity FROM within a VM

```bash
# SSH into the VM and run these commands:
# (On the VM itself — no credentials needed!)

# Get access token using IMDS (Instance Metadata Service)
# Equivalent to: EC2 instance profile token from http://169.254.169.254/...
TOKEN=$(curl -s -H "Metadata: true" \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

echo "Got token: ${TOKEN:0:20}..."

# Use token to call Azure Resource Manager API
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://management.azure.com/subscriptions/YOUR_SUB_ID/resourceGroups?api-version=2021-04-01" \
  | python3 -m json.tool

# Even easier: az login with managed identity
az login --identity

# Now use az CLI normally — no credentials!
az storage blob list \
  --account-name YOUR_STORAGE_ACCOUNT \
  --container-name mycontainer \
  --auth-mode login

# Access Key Vault secrets
az keyvault secret show \
  --vault-name YOUR_KEY_VAULT \
  --name my-secret \
  --query value \
  --output tsv
```

### User-Assigned Managed Identity (Reusable)

```bash
# Create user-assigned managed identity (like an IAM Role that can be shared)
az identity create \
  --resource-group rg-managed-identity-lab \
  --name mi-app-identity

# Get identity details
az identity show \
  --resource-group rg-managed-identity-lab \
  --name mi-app-identity

IDENTITY_RESOURCE_ID=$(az identity show \
  --resource-group rg-managed-identity-lab \
  --name mi-app-identity \
  --query id \
  --output tsv)

IDENTITY_CLIENT_ID=$(az identity show \
  --resource-group rg-managed-identity-lab \
  --name mi-app-identity \
  --query clientId \
  --output tsv)

IDENTITY_PRINCIPAL_ID=$(az identity show \
  --resource-group rg-managed-identity-lab \
  --name mi-app-identity \
  --query principalId \
  --output tsv)

echo "Resource ID: $IDENTITY_RESOURCE_ID"
echo "Client ID:   $IDENTITY_CLIENT_ID"
echo "Principal ID: $IDENTITY_PRINCIPAL_ID"

# Assign role to the user-assigned identity
az role assignment create \
  --assignee "$IDENTITY_PRINCIPAL_ID" \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$(az account show --query id --output tsv)/resourceGroups/rg-managed-identity-lab"

# Assign user-assigned identity to a VM
az vm create \
  --resource-group rg-managed-identity-lab \
  --name vm-shared-identity \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --assign-identity "$IDENTITY_RESOURCE_ID" \
  --size Standard_B1s

# Assign to another VM (shared identity!)
az vm identity assign \
  --resource-group rg-managed-identity-lab \
  --name vm-with-identity \
  --identities "$IDENTITY_RESOURCE_ID"

# Assign user-assigned identity to App Service
az webapp identity assign \
  --resource-group rg-managed-identity-lab \
  --name my-webapp \
  --identities "$IDENTITY_RESOURCE_ID"

# Assign to Azure Function
az functionapp identity assign \
  --resource-group rg-managed-identity-lab \
  --name my-function \
  --identities "$IDENTITY_RESOURCE_ID"
```

---

## Part 4 — Real-World Scenario: GitHub Actions CI/CD

```bash
# Create a Service Principal for GitHub Actions
# Using federated credentials (OIDC) — NO SECRETS AT ALL!
# Like AWS OIDC Provider for GitHub Actions

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
TENANT_ID=$(az account show --query tenantId --output tsv)

# 1. Create the App Registration
az ad app create \
  --display-name "app-github-actions-oidc"

APP_ID=$(az ad app list --display-name "app-github-actions-oidc" --query "[0].appId" --output tsv)
APP_OBJECT_ID=$(az ad app list --display-name "app-github-actions-oidc" --query "[0].id" --output tsv)

# 2. Create the Service Principal for the app
az ad sp create --id "$APP_ID"
SP_ID=$(az ad sp show --id "$APP_ID" --query id --output tsv)

# 3. Add federated credential for GitHub Actions (replace with your repo)
cat > federated-credential.json << EOF
{
  "name": "github-actions-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:YOUR_GITHUB_ORG/YOUR_REPO:ref:refs/heads/main",
  "description": "GitHub Actions from main branch",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF

az ad app federated-credential create \
  --id "$APP_OBJECT_ID" \
  --parameters federated-credential.json

# For PR environments:
cat > federated-cred-pr.json << EOF
{
  "name": "github-actions-pr",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:YOUR_GITHUB_ORG/YOUR_REPO:pull_request",
  "description": "GitHub Actions from Pull Requests",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF

az ad app federated-credential create \
  --id "$APP_OBJECT_ID" \
  --parameters federated-cred-pr.json

# 4. Assign Contributor role
az role assignment create \
  --assignee "$SP_ID" \
  --role "Contributor" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}"

# 5. Print GitHub Actions secrets to set
echo "=== Set these as GitHub Actions Secrets ==="
echo "AZURE_CLIENT_ID:       $APP_ID"
echo "AZURE_TENANT_ID:       $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
```

### GitHub Actions Workflow (OIDC — no secrets)

```yaml
# .github/workflows/deploy.yml
name: Deploy to Azure

on:
  push:
    branches: [main]

permissions:
  id-token: write    # Required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login (OIDC - no secrets!)
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Deploy Resource
        run: |
          az group list --output table
          # ... your deployment commands
```

---

## Cleanup

```bash
# Delete service principals
az ad sp delete --id "sp-terraform-prod" 2>/dev/null
az ad sp delete --id "sp-github-actions" 2>/dev/null
az ad app delete --id "$APP_ID" 2>/dev/null

# Delete resource groups
az group delete --name rg-managed-identity-lab --yes --no-wait
az group delete --name rg-app-deploy --yes --no-wait

# Delete managed identity
az identity delete \
  --resource-group rg-managed-identity-lab \
  --name mi-app-identity 2>/dev/null
```

---

## ✅ Lab Checklist

- [ ] Created service principal with secret
- [ ] Created service principal with certificate
- [ ] Assigned roles to service principal
- [ ] Logged in as service principal
- [ ] Created VM with system-assigned managed identity
- [ ] Assigned role to managed identity
- [ ] Created user-assigned managed identity
- [ ] Assigned user-assigned identity to multiple VMs
- [ ] Set up GitHub Actions OIDC (federated credential)

---

## 📚 Security Best Practices

1. **Prefer Managed Identities** over service principals (no credentials to leak)
2. **Use certificates** over secrets for service principals (harder to steal)
3. **Use OIDC federation** for GitHub Actions (no secrets stored at all)
4. **Scope to minimum** — don't give Contributor at subscription if RG is enough
5. **Rotate secrets** every 90 days at maximum
6. **Monitor** SP activity via Azure AD Audit Logs
7. **Set expiry** on SP credentials — never create credentials that never expire
