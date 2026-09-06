# Azure Key Vault

> 🎯 Exam Weight: Spans Identity/Security domain — HIGH FREQUENCY in exam!

---

## 🔑 What is Azure Key Vault?

- Managed cloud service for **securely storing and accessing secrets, keys, and certificates**
- Eliminates the need to store sensitive information in code or config files
- Centralized secret management with access control and audit logging
- Backed by **HSM (Hardware Security Modules)** at the Premium tier

---

## 📦 What Key Vault Stores

| Type | Examples | Use Case |
|------|---------|---------|
| **Secrets** | Passwords, connection strings, API keys, tokens | App configuration |
| **Keys** | Encryption keys (RSA, EC) | Data encryption (CMK for storage, disks) |
| **Certificates** | SSL/TLS certificates | HTTPS for apps, services |

---

## 🏗️ Key Vault Tiers

| Tier | Key Protection | HSM Backed |
|------|---------------|------------|
| **Standard** | Software-protected | No |
| **Premium** | HSM-protected (FIPS 140-2 Level 2) | Yes |

> 💡 Use **Premium** when regulatory requirements demand HSM-protected keys.

---

## 🔐 Access Control Models

### 1. Access Policies (Legacy)
- Set per identity (user, group, service principal, managed identity)
- Granular permissions for Secrets, Keys, Certificates separately
- Permission examples for Secrets: Get, List, Set, Delete, Backup, Restore

```bash
# Grant a managed identity access to get secrets
az keyvault set-policy \
  --name myKeyVault \
  --object-id {managed-identity-principal-id} \
  --secret-permissions get list
```

### 2. Azure RBAC (Recommended — newer model)
- Use standard Azure RBAC roles for Key Vault data plane
- Better integration with Azure AD, Conditional Access, PIM

| RBAC Role | Permissions |
|-----------|-------------|
| **Key Vault Administrator** | Full access to all objects |
| **Key Vault Secrets Officer** | Create, read, update, delete secrets |
| **Key Vault Secrets User** | Read secrets only (most common for apps) |
| **Key Vault Crypto Officer** | Create, read, update, delete keys |
| **Key Vault Crypto User** | Use keys for cryptographic operations |
| **Key Vault Certificate Officer** | Manage certificates |
| **Key Vault Reader** | Read metadata only |

> ⚠️ **Cannot mix both models** on the same vault — pick one. RBAC is recommended for new deployments.

---

## 🛡️ Security Features

### Soft Delete
- Deleted Key Vault objects (secrets, keys, certs, and the vault itself) are **retained for 7–90 days** (default 90 days)
- Can **recover** or **purge** deleted objects within retention period
- **Enabled by default** on all new vaults (cannot be disabled once enabled)

### Purge Protection
- Prevents **permanent deletion** during soft-delete retention period
- Even vault owner cannot purge — must wait for retention period to expire
- Required for **Customer-Managed Key (CMK)** scenarios
- Once enabled, **cannot be disabled**

> ⚠️ Exam gotcha: Soft delete alone allows admins to purge immediately. **Purge protection** prevents this.

### Firewall & Virtual Networks
- Restrict access to specific IP ranges or VNets
- **Trusted Microsoft Services** bypass — allows Azure services to access even with firewall enabled
- Private Endpoint support for fully private access

---

## 🔄 Key Rotation

### Manual Rotation
- Update key/secret version, update all apps to use new version

### Automatic Rotation (Azure Key Vault + Azure Automation)
- Set a rotation policy on keys
- Event Grid + Azure Functions can trigger rotation automatically
- Storage Account CMK automatically picks up new key version

```bash
# Set key rotation policy
az keyvault key rotation-policy update \
  --vault-name myKeyVault \
  --name myKey \
  --value @rotation-policy.json
```

---

## 🔗 Referencing Key Vault from App Service

Instead of storing connection strings in App Settings, reference Key Vault:

```
App Setting Value: @Microsoft.KeyVault(SecretUri=https://myVault.vault.azure.net/secrets/mySecret/version)
OR
App Setting Value: @Microsoft.KeyVault(VaultName=myVault;SecretName=mySecret)
```

**Requires**: App Service must have a managed identity with **Key Vault Secrets User** role on the vault.

---

## 📊 Key Vault Monitoring

### Diagnostic Logs
Enable to capture:
- **AuditEvent**: Who accessed what and when
- **AzurePolicyEvaluationDetails**: Policy compliance events

```bash
# Enable diagnostic logging to Log Analytics
az monitor diagnostic-settings create \
  --name myKVDiag \
  --resource {keyvault-resource-id} \
  --workspace {workspace-resource-id} \
  --logs '[{"category":"AuditEvent","enabled":true}]'
```

---

## 🛠️ Common Operations

```bash
# Create a Key Vault
az keyvault create \
  --resource-group myRG \
  --name myKeyVault \
  --location eastus \
  --sku standard \
  --enable-rbac-authorization true

# Create a secret
az keyvault secret set \
  --vault-name myKeyVault \
  --name "DBPassword" \
  --value "P@ssw0rd123!"

# Retrieve a secret
az keyvault secret show \
  --vault-name myKeyVault \
  --name "DBPassword" \
  --query value -o tsv

# List secrets
az keyvault secret list --vault-name myKeyVault

# Delete a secret (soft delete)
az keyvault secret delete --vault-name myKeyVault --name "DBPassword"

# Recover a deleted secret
az keyvault secret recover --vault-name myKeyVault --name "DBPassword"

# Import a certificate
az keyvault certificate import \
  --vault-name myKeyVault \
  --name myCert \
  --file certificate.pfx \
  --password "CertPassword"
```

---

## 🔑 Key Vault + Disk Encryption

### Azure Disk Encryption (ADE)
- Uses Key Vault to store **BitLocker keys** (Windows) / **passphrase** (Linux)
- Key Vault must have **disk encryption enabled** policy

### Customer-Managed Keys (CMK)
- Your own encryption keys in Key Vault for Storage, SQL, Cosmos DB, etc.
- Gives you full control: create, rotate, revoke, delete
- Revoking the key = data becomes inaccessible

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Key Vault stores | Secrets, Keys, Certificates |
| Standard vs Premium | Premium = **HSM-protected** keys |
| Soft delete default | **Enabled** by default, 90-day retention |
| Purge protection | Prevents permanent deletion; **cannot be disabled** |
| Access models | Access Policies (legacy) or **Azure RBAC** (recommended) |
| App Service reference | `@Microsoft.KeyVault(...)` syntax |
| Requires managed identity | For App Service to access Key Vault |
| Audit logging | Enable **AuditEvent** diagnostic category |
| Key rotation | Manual or automatic via rotation policy |
| Private endpoint | Fully private access (no public endpoint needed) |

---

## 🚨 Common Exam Scenarios

**Q: A Key Vault was accidentally deleted. How do you recover it?**
→ If **soft delete** is enabled (it is by default), use `az keyvault recover` within the retention period

**Q: A Key Vault must never have secrets permanently deleted, even by administrators. What do you enable?**
→ **Purge protection** — prevents purging during soft delete retention period

**Q: An App Service needs database passwords without storing them in code. What's the recommended approach?**
→ Store passwords as **Key Vault secrets**, reference them using the `@Microsoft.KeyVault(...)` syntax in App Settings, use **managed identity** for authentication

**Q: You revoked a Customer-Managed Key in Key Vault used for storage encryption. What happens?**
→ The storage account becomes **inaccessible** — data is encrypted and the key is gone

**Q: Which Key Vault tier should you use for FIPS 140-2 Level 2 compliance?**
→ **Premium** tier (HSM-protected keys)
