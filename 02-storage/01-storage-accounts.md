# Azure Storage Accounts

> 🎯 Exam Weight: Part of 15–20% Storage domain

---

## 🔑 What is a Storage Account?

- A top-level **ARM resource container** for all Azure Storage data services: Blobs, Files, Queues, Tables, and Disks
- Every storage object has a **unique URL** based on the globally unique account name
- **Naming Constraints**:
  - Globally unique across all of Azure
  - Length: **3 to 24 characters**
  - Allowed characters: **Lowercase letters and numbers only** (no hyphens, underscores, or uppercase)

### Endpoint URLs
```
Blob Service:   https://<account>.blob.core.windows.net/<container>/<blob>
File Service:   https://<account>.file.core.windows.net/<share>/<file>
Queue Service:  https://<account>.queue.core.windows.net/<queue>
Table Service:  https://<account>.table.core.windows.net/<table>
Secondary (RA): https://<account>-secondary.blob.core.windows.net
```

---

## 📦 Storage Account Types & Supported Features

| Account Type | Data Services | Performance Tier | Primary Use Case |
|--------------|---------------|------------------|------------------|
| **General-purpose v2 (GPv2)** | Blob, File, Queue, Table, Data Lake Gen2 | Standard (HDD) | Default recommendation for modern cloud workloads |
| **Premium block blobs** | Block blobs & Append blobs only | Premium (SSD) | High transactions, consistent low latency (analytics) |
| **Premium file shares** | Azure Files (SMB / NFS) only | Premium (SSD) | Enterprise file shares, low-latency IOPS workloads |
| **Premium page blobs** | Page blobs only | Premium (SSD) | Unmanaged VM OS & data disks |

> 💡 **Upgrading from GPv1 to GPv2**:
> - Can be upgraded in-place via the portal, CLI, or PowerShell without downtime.
> - **Cannot be downgraded**: The upgrade is **permanent and irreversible**.

---

## 🔄 Replication & Redundancy Mechanics

| Replication | Copies | Zone Resilient? | Region Resilient? | Durability | Read Secondary? |
|-------------|--------|-----------------|-------------------|------------|-----------------|
| **LRS** (Locally Redundant) | 3 | ❌ No (1 DC) | ❌ No | 11 9s (99.999999999%) | ❌ No |
| **ZRS** (Zone Redundant) | 3 | ✅ Yes (3 AZs) | ❌ No | 12 9s (99.9999999999%) | ❌ No |
| **GRS** (Geo Redundant) | 6 | ❌ No (LRS in primary + LRS in secondary) | ✅ Yes | 16 9s | ❌ No |
| **GZRS** (Geo-Zone Redundant) | 6 | ✅ Yes (ZRS in primary + LRS in secondary) | ✅ Yes | 16 9s | ❌ No |
| **RA-GRS** | 6 | ❌ No | ✅ Yes | 16 9s | ✅ **Yes** (`-secondary` URL) |
| **RA-GZRS** | 6 | ✅ Yes (3 AZs) | ✅ Yes | 16 9s | ✅ **Yes** (`-secondary` URL) |

---

## ⚠️ Customer-Initiated Account Failover

- Supported on **GRS**, **RA-GRS**, **GZRS**, and **RA-GZRS** accounts
- Used when the primary region experiences a catastrophic disaster or extended outage
- **Failover Behavior**:
  1. Primary endpoint DNS records are updated to point to the secondary region.
  2. The secondary region becomes the **new primary**.
  3. The storage account redundancy is automatically **converted to Locally Redundant Storage (LRS)**!
  4. Any writes not yet replicated to the secondary region prior to failover are **permanently lost** (check **Last Sync Time** to evaluate RPO).
  5. After failover completes, you must manually re-configure the account to GRS or GZRS to resume geo-replication.

```bash
# Azure CLI: Initiate customer failover
az storage account failover --name "mystorageacct" --resource-group "RG1"
```

---

## 🔒 Account Configuration & Security Baselines

| Setting | Default / Recommended | Exam Consideration |
|---------|-----------------------|--------------------|
| **Minimum TLS Version** | **TLS 1.2** | Blocks legacy TLS 1.0/1.1 client connections |
| **Secure Transfer Required** | Enabled (`httpsOnly = true`) | Enforces HTTPS on all REST API calls |
| **Allow Blob Public Access** | Disabled by default | Can prevent anonymous public read access tenant-wide |
| **Allowed Copy Scope** | Same Azure AD tenant / Same VNet | Prevents copying data outside corporate perimeter |
| **Default Network Access** | Enabled from all networks | Can restrict to "Selected networks" (VNets & IP ranges) |

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Storage account name rules | 3–24 characters, numbers and lowercase letters only |
| Redundancy after customer failover | Automatically converted to **LRS** |
| Data loss during failover | Any data not replicated before primary failure is lost |
| Secondary read access endpoint | `<accountname>-secondary.blob.core.windows.net` |
| Upgrading GPv1 to GPv2 | In-place, zero downtime, **cannot be reversed** |
| Minimum durability of LRS | 11 nines (99.999999999%) |
| Minimum durability of GRS/GZRS | 16 nines (99.99999999999999%) |
| Premium file shares protocol | Supports both SMB and NFS |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You need to design an Azure Storage account that provides 99.99% read availability for blob data even during a total datacenter and regional outage, while minimizing costs.**
→ Deploy a General-purpose v2 storage account with **Read-Access Geo-Redundant Storage (RA-GRS)**.

**Q: A customer triggers an account failover for a storage account configured with GRS after a primary region failure. After the failover completes, what is the new replication type of the storage account?**
→ The account is converted to **Locally Redundant Storage (LRS)**. To re-establish geo-replication, the administrator must explicitly change the replication setting back to GRS.

**Q: You have an application that reads blobs from the secondary endpoint `storage1-secondary.blob.core.windows.net`. Can the application write new blobs directly to this endpoint?**
→ **No**. The secondary endpoint is strictly **read-only**. Write requests are rejected until an account failover is completed.

**Q: You need to migrate an existing GPv1 storage account to GPv2 to take advantage of lifecycle management policies and blob tiering without moving data.**
→ In the Azure portal, navigate to the storage account **Configuration** blade and click **Upgrade to General-purpose v2**.
