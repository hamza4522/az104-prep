# Storage Accounts

> 🎯 Exam Weight: Part of 15–20% Storage domain

---

## 🔑 Storage Account Types

| Account Type | Supported Services | Performance | Access Tiers | Replication Options |
|--------------|--------------------|-------------|-------------|---------------------|
| **General Purpose v2 (GPv2)** | Blob, File, Queue, Table, Data Lake | Standard / Premium | Hot, Cool, Archive | LRS, ZRS, GRS, RA-GRS, GZRS, RA-GZRS |
| **General Purpose v1 (GPv1)** | Blob, File, Queue, Table | Standard / Premium | ❌ No tiering | LRS, GRS, RA-GRS |
| **BlobStorage** | Block blobs only | Standard | Hot, Cool, Archive | LRS, GRS, RA-GRS |
| **BlockBlobStorage** | Block blobs, Append blobs | **Premium** only | ❌ No tiering | LRS, ZRS |
| **FileStorage** | Azure Files only | **Premium** only | ❌ No tiering | LRS, ZRS |

> ⚠️ **Exam Gotcha**: **BlockBlobStorage** requires **Premium** performance tier. If your settings show Standard performance, you must change to Premium **first** before selecting BlockBlobStorage as the account kind.

> 💡 **GPv2 is recommended** for most scenarios — it supports all latest features at the lowest per-GB pricing.

---

## 🔄 Storage Redundancy Options

| Redundancy | Copies | Scope | Sync/Async | Secondary Read? |
|-----------|--------|-------|------------|-----------------|
| **LRS** (Locally Redundant) | **3** copies | Single datacenter | Synchronous | ❌ |
| **ZRS** (Zone Redundant) | **3** copies | 3 availability zones in 1 region | Synchronous | ❌ |
| **GRS** (Geo Redundant) | **6** copies | 2 regions (primary + secondary paired) | Async (cross-region) | ❌ |
| **RA-GRS** (Read-Access Geo) | **6** copies | 2 regions | Async (cross-region) | ✅ **Read-only** secondary |
| **GZRS** (Geo-Zone Redundant) | **6** copies | 3 zones in primary + 1 secondary region | Sync (within zones), Async (cross-region) | ❌ |
| **RA-GZRS** (Read-Access Geo-Zone) | **6** copies | 3 zones + 1 secondary | Sync + Async | ✅ **Read-only** secondary |

### Key Redundancy Rules
- **LRS**: 3 copies within a single datacenter — cheapest but no zone/region protection
- **ZRS**: Replicates **synchronously** across 3 availability zones — survives single datacenter failure
- **GRS**: Provides region-level protection — secondary region is **NOT readable** unless failover
- **RA-GRS**: Like GRS but with **read-only access to secondary endpoint** — use when you need read availability even if primary region fails
- **Live migration to ZRS**: Supported only for **Standard GPv2** accounts currently using **LRS**. If using GRS/RA-GRS, must first change to LRS, then request live migration.

> ⚠️ **Exam Gotcha (Q12 from Mixed)**: If data must be stored on nodes in separate geographic locations AND be readable from the secondary location → Answer is **RA-GRS** (Read-Access Geo-Redundant Storage).

---

## 📤 Data Transfer Tools

### AzCopy
- Command-line utility for copying data **to/from** storage accounts
- Supports **Blob storage** and **Azure Files** only (NOT Table or Queue)
- Authentication:
  - **Blob storage**: Azure AD or SAS token
  - **File storage**: SAS token only (Azure AD not supported)

```bash
# Copy a local folder to blob storage (recursive)
azcopy copy "D:\folder1" "https://contosodata.blob.core.windows.net/public" --recursive

# Sync a local folder with blob storage
azcopy sync "D:\folder1" "https://contosodata.blob.core.windows.net/public"
```

> 💡 **azcopy copy vs azcopy sync**: `copy` always uploads all files. `sync` skips files if the destination has a more recent last-modified time.

### Azure Storage Explorer
- Free GUI tool (Windows, macOS, Linux)
- Upload/download/manage blobs, files, queues, and tables
- Good for copying files over the internet (e.g., blueprint files to Blob storage)

### Azure Import/Export Service
- Physical disk shipping service for **massive** data transfers (terabytes)
- **Import destinations**: Azure Blob Storage and Azure Files
- **Export sources**: Azure Blob Storage only (cannot export Azure Files, Table, or Queue)
- Import steps:
  1. Attach external disk to server and run **WAImportExport.exe** (encrypts with BitLocker)
  2. Create import job in Azure portal
  3. Ship disks to Azure datacenter
  4. Update tracking in portal
- Requires **dataset CSV** and **driveset CSV** files before preparing drives

---

## 🔧 Upgrading & Changing Storage Accounts

- **GPv1 → GPv2 upgrade**: Supported and recommended. Must upgrade FIRST before changing to ZRS or enabling access tiers
- **Changing replication**: Can be done in the portal (Replication setting)
- **Live migration to ZRS prerequisites**:
  - Account must be **Standard GPv2**
  - Account must currently use **LRS** (not GRS/RA-GRS)
  - Premium accounts must be migrated manually

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Recommended account type | **General Purpose v2 (GPv2)** |
| LRS replica count | **3 copies** in a single datacenter |
| ZRS replication | **Synchronous** across 3 availability zones |
| RA-GRS unique feature | **Read-only access** to secondary region |
| AzCopy supported services | **Blob and File** only (not Table/Queue) |
| AzCopy auth for File storage | **SAS token only** (no Azure AD) |
| Import/Export supported export | **Azure Blob storage only** |
| Import/Export required files | **dataset CSV** and **driveset CSV** |
| BlockBlobStorage prerequisite | Must use **Premium** performance tier |
| Live migration to ZRS | Only from **LRS** on **Standard GPv2** accounts |
| Reducing storage costs (infrequent access) | Change **Access tier** from Hot to Cool |
| SMB port for Azure Files | **TCP port 445** |

---

## 🚨 Common Exam Scenarios (from AZ-104 MCQs)

**Q: You need storage redundancy that replicates synchronously and survives a single datacenter failure in the region. What should you configure?**
→ Use **Zone-Redundant Storage (ZRS)** with a **StorageV2 (GPv2)** account.

**Q: Data must be stored on separate geographic nodes and be readable from the secondary location. Which redundancy option?**
→ **Read-Access Geo-Redundant Storage (RA-GRS)**.

**Q: You want to set Account kind to BlockBlobStorage but settings show Standard performance. What must you change first?**
→ Change **Performance** to **Premium** first, then you can select BlockBlobStorage.

**Q: Which storage accounts support lifecycle management rules (hot/cool/archive tiering)?**
→ **GPv2**, **BlobStorage**, and **BlockBlobStorage** accounts support lifecycle management. GPv1 does NOT.

**Q: You have a GPv1 account with LRS. You need zone-level protection. What do you do first?**
→ **Upgrade the account to General Purpose v2** first, then change replication to ZRS.

**Q: You need to copy on-premises files to a public blob container. Which command?**
→ `azcopy copy D:\folder1 https://contosodata.blob.core.windows.net/public --recursive`

**Q: You need to map a drive to an Azure file share from home Windows 10 computers. Which port must be open?**
→ **TCP port 445** (SMB protocol).
