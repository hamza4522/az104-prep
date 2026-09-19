# Storage Security

> 🎯 Exam Weight: Part of 15–20% Storage domain

---

## 🔑 Storage Security Overview

Azure Storage employs defense-in-depth across 5 layers:
1. **Network-level**: Storage firewalls, VNet service endpoints, Private Link endpoints
2. **Authentication**: Storage access keys, Shared Access Signatures (SAS), Microsoft Entra ID (Azure AD)
3. **Authorization**: Azure RBAC (Management & Data plane), POSIX ACLs (ADLS Gen2)
4. **Encryption**: Service-Side Encryption (SSE) with Microsoft-Managed Keys (MMK) or Customer-Managed Keys (CMK)
5. **Auditing & Monitoring**: Azure Monitor diagnostic settings & Storage Analytics

---

## 🔐 Authentication & Access Tokens

### 1. Storage Account Access Keys
- **Two 512-bit keys** (key1, key2) provided per account
- Grants full, unrestricted administrative and data access to all services (root access)
- Rotate keys regularly with zero downtime by switching applications between key1 and key2:
  1. Switch clients to key2
  2. Regenerate key1
  3. Switch clients to newly generated key1
  4. Regenerate key2

### 2. Shared Access Signatures (SAS)
A URI string that grants restricted, time-limited access to specific storage resources:

| SAS Type | Scope | Backed By | Instant Revocation? |
|----------|-------|-----------|----------------------|
| **User Delegation SAS** | Blob containers / blobs | **Microsoft Entra ID** | ✅ Yes (revoke user token/role) |
| **Service SAS** | Specific container, blob, or file share | Storage account key | ⚠️ Only if using a **Stored Access Policy** |
| **Account SAS** | Multiple services (blob, file, queue, table) | Storage account key | ❌ No (requires regenerating storage key) |

> 💡 **Best Practice**: **User Delegation SAS** is the most secure because it does not expose storage account keys and relies on Azure AD credentials.

---

## 📋 Stored Access Policies

- Configured on a **Blob Container**, **File Share**, **Queue**, or **Table**
- Groups access constraints (start time, expiry time, permissions: Read, Write, Delete, List)
- Provides **Instant Revocation**:
  - To revoke an active Service SAS associated with a stored access policy, simply **delete the policy**, **rename the policy**, or **change the expiration date to the past**!
  - Does **NOT** require rotating the storage account access keys!
- **Constraint**: Up to **5 stored access policies** per container/share.

```bash
# Azure CLI: Create a Stored Access Policy on a container
az storage container policy create   --name "PolicyReadOnly"   --container-name "invoices"   --account-name "mystorageacct"   --permissions r   --expiry 2026-12-31T23:59:59Z
```

---

## 🌐 Storage Firewall & Virtual Network Rules

```
[Internet / Untrusted Networks] ─── (Blocked if 'Selected networks' is active)
[Allowed Public IPs / CIDRs]   ─── (Allowed through IP firewall)
[VNet1 / Subnet1] ───────────── (Allowed via Service Endpoint 'Microsoft.Storage')
[VNet2 / Private Endpoint] ───── (Allowed via 10.0.x.x private IP)
[Trusted Azure Services] ────── (Bypass firewall if checkbox enabled)
```

### Steps to Restrict Access to a Specific Subnet:
1. In the target Virtual Network, go to **Subnets** > select subnet (e.g. `Subnet1`) > enable **Service Endpoints** for `Microsoft.Storage`.
2. In the Storage Account, go to **Networking** > select **Enabled from selected virtual networks and IP addresses**.
3. Under **Virtual networks**, click **Add existing virtual network** and select `VNet1` / `Subnet1`.
4. (Optional) Check **"Allow Azure services on the trusted services list to access this storage account"** to permit Azure Backup, Azure Monitor, and Defender.

---

## 🛡️ Storage Encryption & Customer-Managed Keys (CMK)

- All Azure Storage accounts are encrypted at rest by default using **256-bit AES encryption** (SSE).
- By default, keys are managed by Microsoft (**Microsoft-Managed Keys**).
- When using **Customer-Managed Keys (CMK)**:
  - Encryption key is stored in **Azure Key Vault**.
  - Key Vault requirements:
    1. Must reside in the **same region** (or cross-region supported) as the storage account.
    2. **Soft Delete** must be enabled (protects against accidental deletion).
    3. **Purge Protection** must be enabled (prevents permanent purge before retention expires).
  - Storage account accesses the key using a **System-Assigned** or **User-Assigned Managed Identity**.

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Revoking Service SAS without rotating keys | Use a **Stored Access Policy** (modify expiry or delete policy) |
| Max Stored Access Policies | **5** per container/share |
| Most secure SAS type | **User Delegation SAS** (backed by Microsoft Entra ID) |
| Restricting storage to subnet prerequisite | Subnet must have **Microsoft.Storage** service endpoint enabled |
| CMK Key Vault requirements | **Soft Delete** + **Purge Protection** enabled |
| Default storage encryption | 256-bit AES (SSE), enabled on all accounts, cannot be disabled |
| Storage firewall trusted services | Must check "Allow Azure services on the trusted services list" |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You need to grant external vendors temporary read access to images in a container named `photos`. You must be able to revoke access immediately if a contract terminates, without invalidating other existing access tokens or rotating storage keys.**
→ Create a **Stored Access Policy** on the `photos` container, and generate a **Service SAS** that references this policy. If the vendor contract terminates, delete or alter the Stored Access Policy.

**Q: You configure a storage account firewall to allow traffic only from "Selected networks". Virtual machines in `Subnet-Web` can no longer access blob data. What must be configured on `Subnet-Web`?**
→ Enable the **Microsoft.Storage** Service Endpoint on `Subnet-Web`, and add `Subnet-Web` to the storage account firewall rules.

**Q: An organization mandates that storage account encryption must use customer-managed keys (CMK) stored in Azure Key Vault. What two settings must be configured on Key Vault before assigning the key?**
→ Enable **Soft Delete** and **Purge Protection** on the Azure Key Vault.

**Q: You need to allow Azure Backup to back up virtual machines and store backups in a storage account protected by firewall rules.**
→ In the storage account networking blade, check the exception: **"Allow Azure services on the trusted services list to access this storage account"**.
