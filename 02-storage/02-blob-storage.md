# Azure Blob Storage

> 🎯 Exam Weight: Part of 15–20% Storage domain

---

## 🔑 What is Blob Storage?

- **Binary Large Object** storage — optimized for storing massive amounts of **unstructured data**
- Images, videos, documents, backups, log files, VM disks
- Accessed via HTTP/HTTPS REST API

---

## 📁 Hierarchy

```
Storage Account
    └── Container (like a folder)
            └── Blob (the actual file)
```

### Containers
- Must be lowercase, 3–63 characters
- Public access levels:
  | Level | Description |
  |-------|-------------|
  | **Private** (default) | No anonymous access |
  | **Blob** | Anonymous read access to individual blobs only |
  | **Container** | Anonymous read + list access to all blobs in container |

---

## 📦 Blob Types

| Type | Description | Use Case |
|------|-------------|----------|
| **Block Blob** | Made of blocks, up to ~190 TB | Files, images, videos — most common |
| **Append Blob** | Optimized for append operations | Log files, streaming data |
| **Page Blob** | Random access, 512-byte pages, up to 8 TB | VM OS/data disks (unmanaged disks) |

> ⚠️ **Exam Gotcha**: Once a blob is created, you **cannot change its type**. Page blobs are specifically for **VM disks**.

---

## 🔄 Blob Versioning

- Automatically maintains **previous versions** of blobs when modified or deleted
- Each modification creates a new version with a unique **version ID**
- Requires **versioning enabled** on the storage account
- Versions persist until explicitly deleted

---

## 🗑️ Soft Delete

### Blob Soft Delete
- Retains **deleted blobs** for a configurable period (1–365 days)
- Can recover accidentally deleted blobs
- Applies to all blob types

### Container Soft Delete
- Retains **deleted containers** (and their blobs)
- Recovery window: 1–365 days

> 💡 **Best Practice**: Enable both blob AND container soft delete for comprehensive data protection.

---

## 🔒 Immutable Storage (WORM)

- **Write Once, Read Many** — blobs cannot be modified or deleted for a set period
- Two types of immutability policies:
  | Type | Description |
  |------|-------------|
  | **Time-based retention** | Blobs are locked for a defined number of days |
  | **Legal hold** | Blobs are locked indefinitely until legal hold is removed |
- Common for **compliance** and **regulated industries** (FINRA, SEC, CFTC)

---

## 📋 Object Replication

- Asynchronously copies block blobs between storage accounts
- Source and destination can be in **different regions**
- Use cases: minimizing latency (serve from region closest to users), DR
- Requires **blob versioning** to be enabled on both accounts

---

## 🌡️ Blob Access Tiers (Per-Blob)

- Individual blobs can have their own tier (Hot/Cool/Cold/Archive)
- Can override the account-level default tier
- **Tier changes**: Instantaneous for Hot/Cool/Cold; **rehydration needed for Archive**

### Rehydration from Archive
- **Priority**: Standard (up to 15 hours) or High (within 1 hour, higher cost)
- Two methods:
  1. **Copy to new blob** in Hot/Cool tier
  2. **Change tier** of existing blob to Hot/Cool

---

## 🔗 Blob URLs & Access

### Public URL
```
https://{account}.blob.core.windows.net/{container}/{blob-name}
```

### SAS Token URL
```
https://{account}.blob.core.windows.net/{container}/{blob-name}?sv=2023-01-03&st=...&se=...&sr=b&sp=r&sig=...
```

---

## 📤 Blob Upload Methods & Tools

| Tool | Method | Use Case |
|------|--------|----------|
| **Azure Portal** | GUI upload | Small files, quick uploads |
| **Azure Storage Explorer** | Desktop GUI | Managing blobs visually |
| **AzCopy** | CLI tool | Large data transfers, migration |
| **Azure CLI** | `az storage blob upload` | Scripted uploads |
| **PowerShell** | `Set-AzStorageBlobContent` | Scripted uploads |

### AzCopy Commands
```bash
# Upload a file
azcopy copy "C:\local\file.txt" "https://account.blob.core.windows.net/container/file.txt?{SAS}"

# Upload a directory
azcopy copy "C:\local\folder" "https://account.blob.core.windows.net/container?{SAS}" --recursive

# Copy between storage accounts
azcopy copy "https://sourceaccount.blob.core.windows.net/container?{SAS}" \
            "https://destaccount.blob.core.windows.net/container?{SAS}" \
            --recursive

# Sync (copy only changed/new files)
azcopy sync "C:\local\folder" "https://account.blob.core.windows.net/container?{SAS}"
```

### Azure CLI
```bash
# Upload a blob
az storage blob upload \
  --account-name mystorageaccount \
  --container-name mycontainer \
  --name myblob.txt \
  --file "C:\local\myblob.txt"

# Download a blob
az storage blob download \
  --account-name mystorageaccount \
  --container-name mycontainer \
  --name myblob.txt \
  --file "C:\downloads\myblob.txt"

# List blobs in a container
az storage blob list \
  --account-name mystorageaccount \
  --container-name mycontainer \
  --output table
```

---

## 🔄 Blob Snapshots

- Read-only copy of a blob at a point in time
- Snapshot URI: `https://{account}.blob.core.windows.net/{container}/{blob}?snapshot={datetime}`
- Cannot be deleted if there are snapshots; delete snapshots first (or delete with snapshots flag)

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Most common blob type | **Block blob** |
| VM disk blob type | **Page blob** |
| Log file blob type | **Append blob** |
| Max block blob size | ~190 TB |
| Max page blob size | 8 TB |
| Container name | Lowercase, 3–63 characters |
| Archive rehydration (standard) | Up to **15 hours** |
| Archive rehydration (high priority) | Within **1 hour** |
| WORM storage type | **Immutable storage** |
| Tool for large-scale blob transfers | **AzCopy** |
| Blob versioning requires | Enabled on storage account |

---

## 🚨 Common Exam Scenarios

**Q: You need to prevent blobs from being modified or deleted for 7 years to meet SEC regulations. What do you configure?**
→ **Immutable storage** with a **time-based retention policy** of 7 years

**Q: A developer accidentally deleted an important blob. How do you recover it?**
→ If **soft delete** is enabled, restore the blob from the deleted state within the retention period

**Q: You need to copy 10 TB of on-premises files to Azure Blob storage. What tool?**
→ **AzCopy** — designed for high-speed, large-scale transfers

**Q: An application appends log entries continuously. What blob type should be used?**
→ **Append blob** — optimized for append-only operations

**Q: You want to serve static website content from blob storage with the lowest latency globally. What do you add?**
→ **Azure CDN** in front of blob storage (or Azure Front Door)
