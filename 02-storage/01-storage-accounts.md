# Azure Storage Accounts

> 🎯 Exam Weight: Part of 15–20% Storage domain

---

## 🔑 What is a Storage Account?

- A **container** for all Azure Storage data objects: blobs, files, queues, tables, disks
- Every storage object has a **unique URL** based on the storage account name
- Storage account name must be **globally unique**, 3–24 characters, lowercase letters and numbers only

### URL Format
```
Blob:   https://{account}.blob.core.windows.net/{container}/{blob}
File:   https://{account}.file.core.windows.net/{share}/{file}
Queue:  https://{account}.queue.core.windows.net/{queue}
Table:  https://{account}.table.core.windows.net/{table}
```

---

## 📦 Storage Account Types

| Type | Supported Services | Performance | Use Case |
|------|-------------------|-------------|----------|
| **Standard general-purpose v2 (GPv2)** | Blob, File, Queue, Table | Standard (HDD) | Most scenarios — default choice |
| **Premium block blobs** | Block blobs only | Premium (SSD) | High transaction rate, small objects, low latency |
| **Premium file shares** | Azure Files only | Premium (SSD) | High-performance file shares, SMB/NFS |
| **Premium page blobs** | Page blobs only | Premium (SSD) | VM disks (unmanaged) |

> 💡 **Exam Tip**: For new workloads, always choose **General Purpose v2 (GPv2)** unless there's a specific need for Premium performance.

---

## 🔄 Replication / Redundancy Options

| Option | Acronym | Copies | Description | SLA |
|--------|---------|--------|-------------|-----|
| **Locally Redundant Storage** | LRS | 3 copies | Same datacenter, same region | 99.9% |
| **Zone-Redundant Storage** | ZRS | 3 copies | 3 availability zones, same region | 99.9% |
| **Geo-Redundant Storage** | GRS | 6 copies | LRS + async copy to secondary region | 99.9% |
| **Geo-Zone-Redundant Storage** | GZRS | 6 copies | ZRS + async copy to secondary region | 99.9% |
| **Read-Access GRS** | RA-GRS | 6 copies | GRS + read access to secondary | 99.99% |
| **Read-Access GZRS** | RA-GZRS | 6 copies | GZRS + read access to secondary | 99.99% |

> ⚠️ **Exam Gotcha**: With **GRS/GZRS**, data in secondary region is **not readable by default**. You need **RA-GRS/RA-GZRS** for read access. Failover to secondary is **manual** (initiated by Microsoft or you).

### Choosing Redundancy
| Scenario | Recommended |
|----------|------------|
| Lowest cost, data loss acceptable | **LRS** |
| Zone failure protection | **ZRS** |
| Regional disaster recovery, read only | **GRS** |
| Read access to secondary region | **RA-GRS** |
| Maximum availability | **RA-GZRS** |

---

## 🌡️ Access Tiers (Blob Storage)

| Tier | Description | Access Cost | Storage Cost | Min Storage Duration |
|------|-------------|-------------|--------------|---------------------|
| **Hot** | Frequently accessed data | Low | High | None |
| **Cool** | Infrequently accessed | Medium | Medium | **30 days** |
| **Cold** | Rarely accessed | High | Lower | **90 days** |
| **Archive** | Long-term archival, offline | Very High | Lowest | **180 days** |

> ⚠️ **Archive tier**: Data is **offline** — must be **rehydrated** to Hot or Cool before reading. Rehydration can take up to **15 hours**.

> ⚠️ **Early deletion penalty**: Deleting Cool data before 30 days, Cold before 90 days, or Archive before 180 days incurs a penalty.

### Lifecycle Management Policies
- Automatically **move blobs** between tiers or delete them based on rules
- Example: Move to Cool after 30 days, Archive after 90 days, Delete after 365 days

```json
{
  "rules": [{
    "name": "archiveOldBlobs",
    "enabled": true,
    "type": "Lifecycle",
    "definition": {
      "filters": {"blobTypes": ["blockBlob"]},
      "actions": {
        "baseBlob": {
          "tierToCool": {"daysAfterModificationGreaterThan": 30},
          "tierToArchive": {"daysAfterModificationGreaterThan": 90},
          "delete": {"daysAfterModificationGreaterThan": 365}
        }
      }
    }
  }]
}
```

---

## 🔑 Storage Access Keys & Shared Access Signatures

### Access Keys
- Every storage account has **2 access keys** (primary + secondary)
- Full access to the storage account
- Rotate keys periodically without downtime (use secondary while rotating primary)
- **Never share access keys** — use SAS instead for limited access

### Shared Access Signatures (SAS)
- Provides **granular, time-limited** access to storage resources
- Types:
  - **Account SAS**: Access to multiple services/resources in the account
  - **Service SAS**: Access to a specific service (blob, file, queue, table)
  - **User delegation SAS**: Secured with Azure AD credentials (most secure) 

### SAS Parameters
- **Permissions**: Read (r), Write (w), Delete (d), List (l), Add (a), Create (c)
- **Start/Expiry time**: When access is valid
- **IP restrictions**: Limit to specific IPs
- **Protocol**: HTTPS only or HTTP+HTTPS

```bash
# Generate a SAS token for a blob container
az storage container generate-sas \
  --account-name mystorageaccount \
  --name mycontainer \
  --permissions rwdl \
  --expiry 2024-12-31 \
  --https-only
```

> 💡 **Exam Tip**: **User delegation SAS** is more secure than account/service SAS because it uses Azure AD credentials instead of storage account keys.

---

## 🌐 Storage Endpoints & Networking

### Private Endpoints
- Connect storage account to a VNet using a **private IP**
- Traffic stays on the Azure backbone (never touches public internet)
- Used with **Private Link**

### Firewalls & Virtual Networks
- Restrict storage access to specific **VNets, subnets, or IP ranges**
- Default is to allow all networks; can restrict to "Selected networks"
- **Service Endpoints** — enable routing storage traffic through VNet (but still uses public endpoint)

---

## 🛠️ Creating a Storage Account

```bash
# Azure CLI
az storage account create \
  --name mystorageaccount \
  --resource-group myRG \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot

# PowerShell
New-AzStorageAccount -ResourceGroupName "myRG" `
  -Name "mystorageaccount" `
  -Location "EastUS" `
  -SkuName "Standard_LRS" `
  -Kind "StorageV2" `
  -AccessTier "Hot"
```

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Storage account name | Globally unique, 3–24 chars, lowercase + numbers |
| Default storage kind | **GPv2 (General Purpose v2)** |
| Most copies of data | **RA-GZRS** (6 copies, zone + geo redundant) |
| Archive rehydration time | Up to **15 hours** |
| Cool tier min storage | **30 days** |
| Cold tier min storage | **90 days** |
| Archive tier min storage | **180 days** |
| Number of access keys | **2** (primary + secondary) |
| Most secure SAS type | **User delegation SAS** |
| GRS readable by default? | **No** — need RA-GRS |

---

## 🚨 Common Exam Scenarios

**Q: A company needs storage that survives a complete regional outage and allows read access during the outage. What redundancy?**
→ **RA-GRS** (or RA-GZRS for maximum availability)

**Q: You need to provide a vendor temporary read-only access to a specific blob for 24 hours. What do you use?**
→ **SAS token** (Shared Access Signature) with read permission and 24-hour expiry

**Q: An application has infrequently accessed compliance data. It must be retrievable within minutes but should cost as little as possible. What tier?**
→ **Cool** tier (accessible immediately, lower storage cost than Hot)

**Q: Data is needed for 7 years for legal compliance but will never be accessed. What's the most cost-effective tier?**
→ **Archive** tier

**Q: You want to automatically move blobs to Archive after 90 days of inactivity. What do you configure?**
→ **Lifecycle Management Policy**
