# Azure Blob Storage

> 🎯 Exam Weight: Part of 15–20% Storage domain

---

## 🔑 What is Blob Storage?

- **Binary Large Object** storage optimized for storing massive volumes of **unstructured data** (media, documents, VM disks, backups, logs)
- Global HTTP/HTTPS REST endpoint accessibility
- Flat namespace organized into **Storage Account > Container > Blob**

---

## 📁 Container Public Access Levels

| Level | Anonymous Read on Blobs? | Anonymous List Container Contents? |
|-------|--------------------------|------------------------------------|
| **Private** (default) | ❌ No (Authentication required) | ❌ No |
| **Blob** | ✅ **Yes** (if exact blob URL is known) | ❌ No |
| **Container** | ✅ **Yes** | ✅ **Yes** (can browse entire container contents) |

> ⚠️ **Exam Gotcha**: The storage account setting **"Allow Blob public access"** acts as a master switch. If disabled at the storage account level, all containers are enforced as Private regardless of their individual container setting.

---

## 📦 Blob Types & Constraints

| Blob Type | Structure | Max Size | Primary Use Case |
|-----------|-----------|----------|------------------|
| **Block Blob** | Blocks (up to 4,000 MB per block) | ~190 TB | Documents, images, media streaming, backups |
| **Append Blob** | Append-only blocks (optimized for logging) | ~195 GB | Application logs, audit trails, telemetry |
| **Page Blob** | 512-byte random-access pages | 8 TB | Unmanaged VM OS and data disks (VHDs) |

> ⚠️ **Rule**: Blob types **cannot be converted** after creation. To convert a page blob to a block blob, you must copy or re-upload it.

---

## 🔒 Immutability (WORM: Write Once, Read Many)

Immutability policies protect business-critical data from being deleted or overwritten.

```
Container Immutability
  ├── Time-Based Retention Policy (locks blobs for X days)
  │     ├── Unlocked (can be deleted or extended, for testing)
  │     └── Locked (strictly non-reversible, meets FINRA/SEC 17a-4)
  └── Legal Hold (locks blobs indefinitely with custom case tags)
```

| Immutability Policy | Duration | Modification / Deletion | Removal / Release |
|---------------------|----------|-------------------------|-------------------|
| **Time-based Retention** | Configured in days (e.g. 365 days) | ❌ Cannot modify or delete during retention period | Cleared automatically after expiration |
| **Legal Hold** | Indefinite (no expiration) | ❌ Cannot modify or delete while active | Cleared by users with permission removing the tag |

> 💡 **Exam Question Pattern**:
> - If the requirement is: *"Prevent content from being modified or deleted for exactly 1 year"* ➔ **Time-based retention policy**.
> - If the requirement is: *"Prevent deletion during ongoing litigation or until an audit is complete"* ➔ **Legal hold**.

---

## 🌡️ Access Tiers & Lifecycle Management

| Access Tier | Availability | Min Retention | Storage Cost | Retrieval Cost | Rehydration |
|-------------|--------------|---------------|--------------|----------------|-------------|
| **Hot** | 99.9% | None | Highest | Lowest | Instantaneous |
| **Cool** | 99.0% | **30 days** | Lower | Higher | Instantaneous |
| **Cold** | 99.0% | **90 days** | Very Low | Higher | Instantaneous |
| **Archive** | Offline | **180 days** | Lowest | Highest | **Requires rehydration** (up to 15 hrs) |

### Archive Rehydration Options
1. **Change Tier in-place**: Modifies the blob tier to Hot/Cool. Blob remains offline until rehydrated.
2. **Copy to New Blob**: Issues an asynchronous `Copy Blob` command from the archived blob to a new blob in the Hot/Cool tier, keeping the original intact.
- **Priority**:
  - **Standard Priority**: Up to 15 hours.
  - **High Priority**: Under 1 hour for blobs < 10 GB (incurs higher priority fee).

### Lifecycle Management JSON Rules
```json
{
  "rules": [
    {
      "name": "MoveToArchiveAndDelete",
      "enabled": true,
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["logs/"]
        },
        "actions": {
          "baseBlob": {
            "tierToCool": { "daysAfterModificationGreaterThan": 30 },
            "tierToArchive": { "daysAfterModificationGreaterThan": 90 },
            "delete": { "daysAfterModificationGreaterThan": 365 }
          },
          "snapshot": {
            "delete": { "daysAfterCreationGreaterThan": 90 }
          }
        }
      }
    }
  ]
}
```

---

## ⚡ Data Transfer Tools: AzCopy & Azure Import/Export

### AzCopy v10 CLI Syntax
AzCopy is a high-performance command-line utility for copying data to/from Azure Blob Storage and Azure Files.

```bash
# Upload local folder to Blob container recursively
azcopy copy "D:\Folder1" "https://mystorage.blob.core.windows.net/mycontainer?<SAS-Token>" --recursive=true

# Copy single file from local to blob
azcopy copy "C:\data\report.pdf" "https://mystorage.blob.core.windows.net/mycontainer/report.pdf?<SAS-Token>"

# Sync directories (one-way synchronization; copies missing/modified files)
azcopy sync "D:\Backup" "https://mystorage.blob.core.windows.net/mycontainer?<SAS-Token>" --recursive=true --delete-destination=prompt
```

### Azure Import/Export Service
Used when network bandwidth is too slow to upload/download terabytes or petabytes of data:
- Supported hardware: **2.5-inch or 3.5-inch SATA II/III internal HDD/SSD**
- File system: **NTFS**, encrypted with **BitLocker**
- Prepared using the **WAImportExport** tool on-premises
- **Service Capabilities**:
  - **Import**: Supports copying data to **Azure Blob Storage** AND **Azure Files**
  - **Export**: Supports copying data from **Azure Blob Storage ONLY** (cannot export Azure Files via Import/Export!)

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Prevent modifications for fixed period | **Time-based retention policy** (immutability) |
| Prevent deletion indefinitely during audits | **Legal hold** (immutability) |
| AzCopy supported services | Azure Blob Storage & Azure Files (NOT Queues or Tables) |
| Import/Export export capability | **Azure Blob Storage only** |
| Import/Export drive requirement | SATA II/III internal drives, NTFS, BitLocker encrypted |
| Archive early deletion penalty | Charged for full 180 days if deleted or moved before 180 days |
| Cool early deletion penalty | Charged for full 30 days |
| Rehydration high priority duration | Under 1 hour for blobs < 10 GB |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You need to prevent new content added to a blob container named `container1` from being modified or deleted for one year.**
→ Configure a **Time-based retention policy** with a retention period of 365 days on `container1`.

**Q: An on-premises server has a directory `D:\Folder1` with 2 TB of files. You need to copy the entire directory into an Azure Blob container named `public` with minimal administrative effort.**
→ Install and run **AzCopy v10**:
`azcopy copy "D:\Folder1" "https://storage1.blob.core.windows.net/public?<SAS>" --recursive=true`.

**Q: You plan to use the Azure Import/Export service to export data from Azure to physical hard drives shipped to your office. Which Azure storage services can be exported?**
→ **Azure Blob Storage only** (Azure Files, Tables, and Queues cannot be exported using the Import/Export service).

**Q: An administrator needs to access an archived blob urgently within the next 45 minutes.**
→ Initiate a blob rehydration with **High Priority** (or copy to a new blob with high priority).

**Q: You want to automatically move blobs in the `archive/` folder to cool storage after 30 days, to archive tier after 90 days, and delete them after 3 years.**
→ Create an **Azure Storage Lifecycle Management rule** targeting block blobs with prefix match `archive/`.
