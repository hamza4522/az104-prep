# Managed Identities

> 🎯 Exam Weight: Part of 15–20% Identity & Governance domain — VERY FREQUENTLY TESTED!

---

## 🔑 What are Managed Identities?

- An **automatically managed identity** in Azure AD for Azure services
- Eliminates the need to store credentials (passwords, keys, secrets) in code or config
- Azure handles **creation, rotation, and deletion** of credentials automatically
- Your app just says "I am this VM/App Service/etc." and Azure gives it a token

> 💡 **The #1 use case**: App running in Azure needs to access Azure Key Vault, Storage, SQL, etc. — use Managed Identity instead of storing connection strings.

---

## 📦 Types of Managed Identities

| Type | Description | Lifecycle | Sharing |
|------|-------------|-----------|---------|
| **System-assigned** | Tied to ONE specific Azure resource | Created/deleted with the resource | Cannot be shared |
| **User-assigned** | Standalone identity created independently | Independent lifecycle | Can be shared across multiple resources |

### System-Assigned Managed Identity
```
[VM Created] → [System-assigned MI auto-created in Azure AD] → [Assign RBAC roles to MI]
[VM Deleted] → [System-assigned MI auto-deleted]
```
- One-to-one relationship with the resource
- Automatically cleaned up when resource is deleted

### User-Assigned Managed Identity
```
[Create MI separately] → [Assign to multiple VMs/Apps] → [Assign RBAC roles to MI]
[Delete resource] → [MI still exists, assigned to other resources]
```
- One-to-many relationship (one MI → many resources)
- Must be manually deleted when no longer needed
- Great for sharing identity across multiple resources

---

## 🔄 How Managed Identity Works (Under the Hood)

```
1. App on VM requests token from Instance Metadata Service (IMDS)
   GET http://169.254.169.254/metadata/identity/oauth2/token

2. Azure AD returns an access token for the requested resource

3. App uses token to authenticate to Azure service (Key Vault, Storage, etc.)

4. No credentials ever stored anywhere!
```

---

## 🆚 System-Assigned vs User-Assigned

| Scenario | Recommended Type |
|----------|-----------------|
| Single resource needs identity | **System-assigned** |
| Multiple resources share same permissions | **User-assigned** |
| Resource recreated frequently (scaling) | **User-assigned** (permissions preserved) |
| Need to pre-configure permissions before resource is created | **User-assigned** |
| Simplest setup | **System-assigned** |

---

## 🛠️ Creating and Using Managed Identities

### Enable System-Assigned on VM
```bash
# Enable during VM creation
az vm create \
  --resource-group myRG \
  --name myVM \
  --image Ubuntu2204 \
  --assign-identity \
  --admin-username azureuser

# Enable on existing VM
az vm identity assign \
  --resource-group myRG \
  --name myVM

# Check identity
az vm identity show --resource-group myRG --name myVM
```

### Create and Assign User-Assigned Identity
```bash
# Create user-assigned identity
az identity create \
  --resource-group myRG \
  --name myUserIdentity

# Assign to a VM
az vm identity assign \
  --resource-group myRG \
  --name myVM \
  --identities myUserIdentity

# Assign to App Service
az webapp identity assign \
  --resource-group myRG \
  --name myWebApp \
  --identities myUserIdentity
```

### Grant Identity Access to a Resource
```bash
# Get the identity's principal ID
PRINCIPAL_ID=$(az identity show --resource-group myRG --name myUserIdentity --query principalId -o tsv)

# Assign Storage Blob Data Reader role
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Storage Blob Data Reader" \
  --scope "/subscriptions/{sub-id}/resourceGroups/myRG/providers/Microsoft.Storage/storageAccounts/myStorage"

# Assign Key Vault Secrets User role
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/{sub-id}/resourceGroups/myRG/providers/Microsoft.KeyVault/vaults/myVault"
```

---

## 🏢 Services That Support Managed Identities

| Service | Can USE (have MI) | Can BE ACCESSED (via MI) |
|---------|------------------|--------------------------|
| Virtual Machines | ✅ | - |
| App Service / Functions | ✅ | - |
| AKS | ✅ | - |
| Azure Container Instances | ✅ | - |
| Logic Apps | ✅ | - |
| Azure Key Vault | - | ✅ |
| Azure Storage | - | ✅ |
| Azure SQL | - | ✅ |
| Azure Service Bus | - | ✅ |
| Azure Event Hubs | - | ✅ |

---

## 🔐 Managed Identity + Key Vault (Most Common Exam Pattern)

```
VM (with System-assigned MI)
    → Request secret from Key Vault
    → Key Vault checks: "Does this MI have Key Vault Secrets User role?"
    → Yes → Returns secret
    → No → 403 Forbidden
```

**Setup Steps:**
1. Enable managed identity on VM
2. Assign "Key Vault Secrets User" role to the MI on the Key Vault
3. In code: use `DefaultAzureCredential()` — no secrets needed in code!

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| System-assigned MI | Tied to ONE resource, auto-deleted with resource |
| User-assigned MI | Independent, can assign to MANY resources |
| Credentials managed by | **Azure** — no manual rotation needed |
| IMDS endpoint | **169.254.169.254** (link-local, internal only) |
| Requires storing credentials | **NO** — that's the whole point! |
| Role assignment needed | **Yes** — MI must be granted RBAC roles |
| Use for shared identity | **User-assigned** |
| Use for simple single resource | **System-assigned** |

---

## 🚨 Common Exam Scenarios

**Q: An app running on a VM needs to read secrets from Key Vault without storing any credentials. What's the best solution?**
→ Enable **system-assigned managed identity** on the VM, then assign **Key Vault Secrets User** role to it on the Key Vault

**Q: 10 VMs all need identical access to the same storage account. You want to manage permissions centrally. What do you use?**
→ Create a **user-assigned managed identity**, assign it to all 10 VMs, then grant the MI access to storage

**Q: A VM's managed identity needs to be preserved even if the VM is rebuilt. What type should you use?**
→ **User-assigned managed identity** — it exists independently of the VM

**Q: A developer asks why they can't find a managed identity password to rotate. What do you tell them?**
→ Managed identities **have no passwords** — Azure manages the credentials automatically. No rotation needed.

**Q: An App Service needs to query an Azure SQL database without a connection string. What do you configure?**
→ Enable **managed identity** on App Service, then add the MI as a database user in SQL with appropriate permissions
