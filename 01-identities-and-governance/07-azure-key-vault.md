# Azure Key Vault

> 🎯 Exam Weight: Part of 15–20% Identity & Governance domain

---

## 🔑 What is Azure Key Vault?

- Cloud service for securely storing and accessing **secrets**, **keys**, and **certificates**
- Centralizes application secrets management, reducing the risk of accidental leaks
- Provides **hardware security module (HSM)** backed key storage at Premium tier

---

## 📦 Key Vault Object Types

| Object Type | Description | Example Use Case |
|-------------|-------------|-----------------|
| **Secrets** | Any string value (passwords, connection strings, API keys) | Database connection strings, storage account keys |
| **Keys** | Cryptographic keys (RSA, EC) for encryption/decryption/signing | Disk encryption, data encryption at rest |
| **Certificates** | X.509 certificates (SSL/TLS) with automatic renewal support | HTTPS endpoints, code signing |

---

## 🛡️ Key Vault Access Models

### Two Access Models

| Model | Description | Recommended? |
|-------|-------------|-------------|
| **Vault Access Policy** | Per-vault permission model; assign get/set/list/delete per secret/key/cert | Legacy model |
| **Azure RBAC** | Uses standard RBAC roles for data plane access | ✅ **Recommended** |

### Key Vault RBAC Roles
| Role | Permissions |
|------|------------|
| **Key Vault Administrator** | Full management of vault + all objects |
| **Key Vault Secrets User** | **Read** secrets only |
| **Key Vault Secrets Officer** | Manage (CRUD) secrets |
| **Key Vault Crypto User** | Perform cryptographic operations with keys |
| **Key Vault Reader** | Read metadata of vaults (not secret values) |

---

## 🔐 Key Vault + ARM Templates (CRITICAL Exam Topic!)

### Storing Passwords for ARM Template Deployments
- ARM templates can reference Key Vault secrets **dynamically** in parameter files
- The password is **never stored in plain text** in the template or parameter file
- **Setup**:
  1. Create an **Azure Key Vault**
  2. Store the secret (e.g., admin password) in the vault
  3. In the ARM template **parameter file**, use a `reference` to the Key Vault secret:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "adminPassword": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{sub-id}/resourceGroups/RG1/providers/Microsoft.KeyVault/vaults/MyVault"
        },
        "secretName": "vmAdminPassword"
      }
    }
  }
}
```

> ⚠️ **Exam Gotcha**: The Key Vault must have **"Enable access to Azure Resource Manager for template deployment"** toggled ON in the Access Policies (or equivalent RBAC) for ARM templates to reference it.

---

## 🔒 Key Vault Protection Features

### Soft Delete
- When enabled, deleted vaults and vault objects are retained for a configurable retention period (**7–90 days**, default 90 days)
- Deleted objects can be **recovered** during the retention period
- **Required** when using Key Vault for Customer-Managed Key (CMK) encryption

### Purge Protection
- When enabled, prevents **permanent deletion** (purge) of a soft-deleted vault or object before the retention period expires
- Even vault administrators cannot bypass purge protection
- **Required** for CMK encryption with Azure Storage

> 💡 **Key Vault for CMK Storage Encryption** requires BOTH:
> 1. **Soft Delete** enabled
> 2. **Purge Protection** enabled

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| ARM template password security | Reference Key Vault secrets in parameter file |
| Key Vault for CMK requirements | **Soft Delete** + **Purge Protection** must be enabled |
| Soft Delete default retention | **90 days** |
| Key Vault Premium tier advantage | HSM-backed keys |
| Best practice for VM with Key Vault | Use **Managed Identity** to access Key Vault (no credentials in code) |
| Key Vault + ARM template toggle | Must enable "Azure Resource Manager for template deployment" access |

---

## 🚨 Common Exam Scenarios (from AZ-104 MCQs)

**Q: You have an ARM template to deploy VMs. You need to ensure the administrative password is not stored in plain text. What components should you create?**
→ Create an **Azure Key Vault** and store the password as a secret. In the ARM template, create a **parameter file that references** the Key Vault secret ID.

**Q: You need to configure Customer-Managed Keys (CMK) for a storage account using Azure Key Vault. What must be configured on the Key Vault?**
→ Enable **Soft Delete** and **Purge Protection** on the Key Vault.

**Q: An app on a VM needs to read secrets from Key Vault without storing credentials in code.**
→ Enable a **managed identity** on the VM, assign **Key Vault Secrets User** role to the managed identity on the Key Vault.
