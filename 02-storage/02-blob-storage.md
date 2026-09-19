# Blob Storage

> 🎯 Exam Weight: Part of 15–20% Storage domain

---

## 🔑 Blob Types

| Blob Type | Use Case | Supports Tiering? |
|-----------|----------|-------------------|
| **Block Blob** | Files, images, videos, documents — most common | ✅ Yes (Hot, Cool, Archive) |
| **Append Blob** | Log files, streaming data — optimized for append operations | ❌ No |
| **Page Blob** | VHD files for Azure VMs (unmanaged disks) — random read/write | ❌ No |

> 💡 **Unmanaged VM disks** use **Page Blobs**. Managed disks are separate Azure resources and don't use blob storage directly.

---

## 🌡️ Access Tiers

| Tier | Optimized For | Min Storage Duration | Access Latency | Storage Cost | Access Cost |
|------|--------------|---------------------|----------------|--------------|-------------|
| **Hot** | Frequently accessed data | None | Milliseconds | Highest | Lowest |
| **Cool** | Infrequently accessed data | **30 days** | Milliseconds | Lower | Higher |
| **Archive** | Rarely accessed data (backup, compliance) | **180 days** | **Hours** (rehydration required) | Lowest | Highest |

### Key Tiering Rules
- Tiers can be set at the **account level** (default) or at the **individual blob level**
- **Only GPv2 and BlobStorage** accounts support access tiers (GPv1 does NOT)
- **Archive tier**: Blob is offline — must be **rehydrated** (moved to Hot or Cool) before reading data
- Early deletion penalty: Deleting a Cool blob before 30 days or Archive blob before 180 days incurs early deletion charges

> ⚠️ **Exam Gotcha**: To reduce storage costs for data that is rarely accessed, change the **Access tier** (not the replication or performance settings).

---

## 📋 Lifecycle Management Rules

Automate tier transitions and blob deletion based on age:

```json
{
  "rules": [
    {
      "name": "moveToCool",
      "type": "Lifecycle",
      "definition": {
        "actions": {
          "baseBlob": {
            "tierToCool": { "daysAfterModificationGreaterThan": 30 },
            "tierToArchive": { "daysAfterModificationGreaterThan": 90 },
            "delete": { "daysAfterModificationGreaterThan": 365 }
          }
        },
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["container1/"]
        }
      }
    }
  ]
}
```

### Lifecycle Management Applicability
- Supported on **GPv2**, **BlobStorage**, and **BlockBlobStorage** accounts
- **NOT supported** on GPv1 or Premium storage accounts
- Applies to **block blobs** only (not page blobs or append blobs)

---

## 🔒 Immutable Blob Storage (WORM)

- **Write Once, Read Many (WORM)** — prevents modification and deletion
- Two policy types:
  - **Time-based retention**: Prevents modification/deletion for a specified period
  - **Legal hold**: Prevents modification/deletion until the hold is removed (no time limit)
- Applied at the **container level**
- Used for regulatory compliance (SEC 17a-4, CFTC, FINRA)

> 💡 **Exam Question Pattern**: "Prevent new content from being modified for one year" → Configure a **time-based retention policy** (immutable storage / access policy).

---

## 📦 Container Access Levels

| Access Level | Anonymous Read Access |
|-------------|----------------------|
| **Private** (default) | No anonymous access — authentication required |
| **Blob** | Anonymous read access for **blobs only** (not container listing) |
| **Container** | Anonymous read access for **container and blobs** (can list all blobs) |

---

## 📤 Uploading & Managing Blobs

### Create a Blob Container
```bash
# Azure CLI
az storage container create --name vmimages --account-name storage1

# PowerShell
New-AzStorageContainer -Name "vmimages" -Context $ctx
```

### Azure Storage Explorer
- Free cross-platform GUI tool for managing blobs, files, queues, tables
- Upload/download blobs, browse containers, manage access policies

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Default access tier | Set at account level (Hot or Cool) |
| Archive blob access | **Offline** — must rehydrate before reading |
| Cool tier minimum retention | **30 days** |
| Archive tier minimum retention | **180 days** |
| Lifecycle management support | GPv2, BlobStorage, BlockBlobStorage |
| Page Blob use case | **VHD files** for unmanaged VM disks |
| Immutable storage scope | Applied at **container** level |
| Prevent modification for 1 year | **Time-based retention policy** |
| WORM = Write Once Read Many | **Immutable blob storage** |

---

## 🚨 Common Exam Scenarios (from AZ-104 MCQs)

**Q: You need to prevent new content added to container1 from being modified for one year. What should you configure?**
→ Configure a **time-based retention policy** (immutable storage / access policy) on the container.

**Q: You create lifecycle management rules. After uploading Blob1 3 days ago and Blob2 14 days ago, which blobs are affected by a "move to Cool after 10 days" rule?**
→ Only **Blob2** (14 days > 10 days threshold). Blob1 has not reached the threshold yet.

**Q: LRS stores how many copies? What should you change to reduce costs for infrequently accessed data?**
→ LRS stores **3 copies**. Change the **Access tier** from Hot to Cool.

**Q: You need to store VM VHD images in a blob container. Which blob type?**
→ **Page Blobs** for VHD files (used by unmanaged disks).

**Q: Premium file shares are hosted in which storage account kind?**
→ **FileStorage** account kind.

**Q: Which storage accounts can have lifecycle management rules applied?**
→ **GPv2**, **BlobStorage**, and **BlockBlobStorage** (NOT GPv1 or Premium-only accounts).
