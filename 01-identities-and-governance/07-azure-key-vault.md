# Azure Key Vault

> 🎯 Exam Weight: Spans Identity, Compute, and Storage domains — HIGH FREQUENCY in exam!

---

## 🔑 What is Azure Key Vault?

- Cloud service for securely storing and managing **secrets, encryption keys, and certificates**
- Eliminates hardcoded credentials and connection strings from source code, scripts, and ARM templates
- Centralized access control, audit logging, and automated versioning
- Available in two service tiers:
  - **Standard**: Software-protected keys, secrets, and certificates
  - **Premium**: HSM-protected keys (FIPS 140-2 Level 2 validated Hardware Security Modules)

---

## 📦 Key Vault Object Types

| Object Type | Examples | Primary Use Cases |
|-------------|---------|-------------------|
| **Secrets** | Passwords, database connection strings, API tokens | Application configuration, ARM template parameters |
| **Keys** | RSA and Elliptic Curve (EC) cryptographic keys | Customer-Managed Keys (CMK) for Storage, Azure Disk Encryption |
| **Certificates** | X.509 SSL/TLS certificates | App Service HTTPS, Application Gateway SSL termination |

---

## ⚙️ Key Vault Access Policies & Advanced Access Flags

In addition to the authorization model (Vault Access Policy vs Azure RBAC), Key Vault has **three critical feature flags** tested on the exam:

```
[Azure Key Vault]
  ├── Azure Resource Manager for template deployment (--enabled-for-template-deployment)
  ├── Azure Virtual Machines for deployment (--enabled-for-deployment)
  └── Azure Disk Encryption for volume encryption (--enabled-for-disk-encryption)
```

| Advanced Access Setting | CLI Flag | Purpose / Tested Exam Scenario |
|-------------------------|----------|--------------------------------|
| **ARM Template Deployment** | `--enabled-for-template-deployment true` | Allows Azure Resource Manager to retrieve secrets during template execution |
| **VM Deployment** | `--enabled-for-deployment true` | Allows VMs to retrieve certificates stored as secrets from the vault |
| **Disk Encryption** | `--enabled-for-disk-encryption true` | Allows Azure Disk Encryption (BitLocker / dm-crypt) to retrieve keys/secrets |

```bash
# Azure CLI: Enable Key Vault for ARM template deployments
az keyvault update \
  --name "KV-Prod-01" \
  --resource-group "RG1" \
  --enabled-for-template-deployment true
```

---

## 📄 Referencing Key Vault Secrets in ARM Templates

Instead of hardcoding sensitive credentials in `azuredeploy.parameters.json`, reference the Key Vault secret dynamically:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "adminPassword": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{sub-id}/resourceGroups/RG1/providers/Microsoft.KeyVault/vaults/KV-Prod-01"
        },
        "secretName": "vmAdminPassword"
      }
    }
  }
}
```

> ⚠️ **ARM Requirement**: The Key Vault **must** have `--enabled-for-template-deployment true` enabled, otherwise ARM template validation will fail with an authorization error.

---

## 🛡️ Soft Delete & Purge Protection

| Feature | Behavior | Configurable Range |
|---------|----------|--------------------|
| **Soft Delete** | Deleted vaults and objects are kept in a recoverable state | **7 to 90 days** (default is 90 days) |
| **Purge Protection** | Prevents permanent deletion of vaults and objects until the retention period elapses | Mandatory for Customer-Managed Keys (CMK) |

> 💡 **Exam Gotcha**: Once **Purge Protection** is enabled, it **cannot be disabled**! Even Subscription Owners or Global Admins cannot purge secrets before the retention window expires.

---

## 🔐 Access Control Models

### 1. Vault Access Policies (Traditional)
- Specific permissions for Keys, Secrets, and Certificates configured inside the Key Vault
- Maximum 1,024 access policy entries per vault

### 2. Azure RBAC Model (Modern)
- Uses standard Azure role definitions at the Key Vault scope:
  - **Key Vault Administrator**: Full management of data and control planes
  - **Key Vault Secrets Officer**: Create, read, update, delete secrets
  - **Key Vault Secrets User**: Read/Get secret contents only (recommended for applications and VMs)
  - **Key Vault Crypto Officer**: Manage keys (create, rotate)
  - **Key Vault Crypto User**: Perform encryption/decryption operations

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Storing ARM template VM passwords securely | Store in Key Vault and use dynamic parameter `reference` |
| Key Vault requirement for ARM templates | `--enabled-for-template-deployment true` |
| Key Vault requirement for Azure Disk Encryption | `--enabled-for-disk-encryption true` |
| Soft delete retention default | 90 days (range 7–90 days) |
| Purge protection behavior | Cannot be toggled off once enabled; protects against ransomware/accidental purge |
| Least privilege role for an app reading secrets | **Key Vault Secrets User** |
| Moving subscription impact on Key Vault | Key Vault tenant ID must be updated manually after tenant migration |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You deploy multiple virtual machines using ARM templates. You need to ensure administrative passwords are not stored in clear text within parameter files.**
→ Store the administrator password as a **Secret** in Azure Key Vault, configure the Key Vault with `--enabled-for-template-deployment true`, and use the `reference` object in the parameters JSON file to retrieve the secret at deployment time.

**Q: You configure Azure Disk Encryption on an existing Windows VM. What permission/setting must be enabled on the Key Vault holding the encryption key?**
→ The Key Vault must have **Azure Disk Encryption for volume encryption** enabled (`--enabled-for-disk-encryption true`).

**Q: A secret was accidentally deleted 10 days ago from a production Key Vault. Can it be restored?**
→ **Yes**. Because Soft Delete is enabled by default (90-day retention), the administrator can recover the deleted secret from the **Deleted Secrets** section before 90 days elapse.

**Q: An organization requires customer-managed keys (CMK) for encrypting Azure Storage blob data. What two settings are mandatory on the Key Vault?**
→ Both **Soft Delete** and **Purge Protection** must be enabled on the Key Vault.
