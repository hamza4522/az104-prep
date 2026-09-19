# Azure Files & Azure File Sync

> 🎯 Exam Weight: Part of 15–20% Storage domain — HIGH FREQUENCY FILE SYNC QUESTIONS!

---

## 🗂️ Azure Files Overview

Azure Files provides **fully managed file shares** in the cloud accessible via the **SMB (Server Message Block)** protocol and **NFS** protocol.

| Feature | Detail |
|---------|--------|
| Protocol | **SMB 3.0/3.1.1** (Windows/Linux/macOS) and **NFS 4.1** (Linux) |
| Port | **TCP port 445** (SMB) — must be open outbound from client |
| UNC Path format | `\\<storage-account-name>.file.core.windows.net\<share-name>` |
| Max share size (standard) | **5 TB** per share |
| Max share size (premium/large) | **100 TiB** with large file shares enabled |
| Premium file shares account type | **FileStorage** (special-purpose storage account) |

> ⚠️ **Exam Gotcha**: Premium Azure file shares require a **FileStorage** account type. Standard GPv2/GPv1 accounts cannot host premium file shares.

---

## 🔌 Connecting to Azure Files

### UNC Path Construction
```
\\<storage-account-name>.file.core.windows.net\<share-name>
```

**Example**: Storage account = `contosostorage`, share = `data`:
```
\\contosostorage.file.core.windows.net\data
```

### Mounting on Windows
```powershell
# Map drive using net use (requires port 445 open)
net use Z: \\contosostorage.file.core.windows.net\data /u:Azure\contosostorage <access-key>
```

> ⚠️ **Exam Gotcha (Port 445 ISP Blocking)**: Many ISPs block outbound TCP port 445. Workaround options:
> 1. **Azure File Sync** — files sync to a local server endpoint; no port 445 needed from user machines
> 2. **VPN/ExpressRoute** — traffic goes through private channel, not blocked by ISP

---

## 🔄 Azure File Sync

Azure File Sync transforms a Windows Server into a **quick cache** of your Azure file share. It enables multi-site sync, cloud tiering, and seamless branch office file access.

### Core Concepts

| Concept | Definition |
|---------|-----------|
| **Storage Sync Service** | Top-level Azure resource for File Sync (must be in same subscription) |
| **Sync Group** | Defines the sync topology — one cloud endpoint + one or more server endpoints |
| **Cloud Endpoint** | The Azure file share (exactly **one** per sync group) |
| **Server Endpoint** | A path on a registered Windows Server (can have **multiple** per sync group) |
| **Registered Server** | A Windows Server that has a trust relationship with the Storage Sync Service |

> ⚠️ **Critical Exam Rule**: A sync group can have **ONLY ONE cloud endpoint**, but can have **MULTIPLE server endpoints**.

---

## 📋 Azure File Sync Deployment Steps (Exam Favorite!)

The **7-step deployment sequence** tested heavily on the exam:

| Step | Action | Location |
|------|--------|----------|
| 1 | Create a **Storage Sync Service** resource | Azure Portal |
| 2 | Install the **Azure File Sync agent** on Windows Server | On-premises Server |
| 3 | **Register** the Windows Server with the Storage Sync Service | On-premises Server / Portal |
| 4 | Create a **Sync Group** | Azure Portal |
| 5 | Add the Azure file share as the **Cloud Endpoint** | Azure Portal |
| 6 | Add the server folder path as a **Server Endpoint** | Azure Portal |
| 7 | Wait for initial sync | Automatic |

### Common 3-Step Exam Sequences

**Q: You have a Storage Sync Service and sync group already created. What 3 steps do you perform to sync Server1?**
→ (C) **Install Azure File Sync agent** on Server1 → (B) **Register Server1** → (E) **Create a server endpoint** (add server folder to sync group)

**Q: You have an Azure file share and on-premises Server1. What 2 Azure subscription actions do you perform first?**
→ (1) **Create a Storage Sync Service** → (2) **Install the Azure File Sync agent** on Server1

---

## ☁️ Cloud Tiering

Cloud tiering allows infrequently accessed files to be **tiered to Azure** while maintaining a stub (placeholder) file on-premises.

| Concept | Detail |
|---------|--------|
| **Purpose** | Frees up local disk space by moving cold files to the cloud |
| **Stub file** | A placeholder file with `FILE_ATTRIBUTE_OFFLINE` attribute (`O`) — looks like a normal file |
| **Volume Free Space policy** | Keeps a specified % of local volume free (e.g., 20%) |
| **Date policy** | Tiers files not accessed in N days (e.g., last 30 days) |
| **Cloud tiering scope** | Per **server endpoint** (not per sync group) |

> 💡 **How it works**: When a tiered file is accessed, File Sync automatically recalls the full file from Azure. Users see no difference in behavior.

### Cloud Tiering Exam Scenario

**Q: A sync group has Endpoint1 (tiering OFF), Endpoint2 (tiering OFF), Endpoint3 (tiering ON). A file is added to Endpoint1. Where will it appear within 24 hours?**

| Situation | Result |
|-----------|--------|
| File added to **Endpoint1** (cloud tiering OFF) | File syncs to cloud → **Endpoint3 only** receives the file as a tiered stub |
| File added to **Endpoint2** (cloud tiering OFF) | File syncs to cloud → **Endpoint1, Endpoint2, and Endpoint3** all have the file |

> Explanation: When a file is at a server endpoint with tiering OFF, it goes to the cloud endpoint. Other server endpoints with tiering OFF get the full file; endpoints with tiering ON may receive a stub.

---

## 🔄 File Sync Behavior Rules

| Rule | Explanation |
|------|-------------|
| **One cloud endpoint per sync group** | Cannot add a second Azure file share to the same sync group |
| **Files merge on endpoint add** | Adding a file share with existing files → files **merge** with existing sync group files |
| **Server must be registered first** | Only registered servers can have server endpoints added |
| **Unregistered server = no endpoint** | Files on a server not registered to the sync service will NOT sync |
| **Immediate cloud change detection** | Run `Invoke-AzStorageSyncChangeDetection` PowerShell cmdlet to force immediate detection of changes in the cloud endpoint |

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------| 
| Port for Azure Files (SMB) | **TCP 445** |
| UNC path format | `\\<account>.file.core.windows.net\<share>` |
| Premium file share account type | **FileStorage** account |
| Cloud endpoints per sync group | **Exactly 1** |
| Server endpoints per sync group | **Multiple allowed** |
| Cloud tiering stub attribute | `FILE_ATTRIBUTE_OFFLINE` (`O`) |
| Immediate cloud change detection | `Invoke-AzStorageSyncChangeDetection` |
| ISP blocks port 445 workaround | Use **Azure File Sync** or **VPN** |
| Lifecycle management rules apply to | **GPv2, BlobStorage, BlockBlobStorage** — NOT GPv1 |
| Premium file share hosting | **FileStorage** account (not GPv2) |
| Azure Backup for file shares | Recovery vault must be in the **same region** as the storage account |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: Users at home need to map a drive to an Azure file share, but TCP port 445 is blocked by their ISP. What is the best solution?**
→ Deploy **Azure File Sync** and add the servers as server endpoints. Users access files from a local server endpoint — no port 445 required from home PCs.

**Q: You have a Storage Sync Service named Sync1 and sync group Group1 with share1 as the cloud endpoint. You register Server1 and Server2. Can you add share2 as another cloud endpoint to Group1?**
→ **No.** A sync group can have only **one cloud endpoint**.

**Q: You add share1 as the cloud endpoint and D:\\Folder1 on Server1 as a server endpoint to Group1. Can you add D:\\Folder1 on Server2 as another server endpoint to Group1?**
→ **Yes.** Multiple server endpoints are allowed per sync group, even on different registered servers.

**Q: Files exist in an Azure file share added as a cloud endpoint to a sync group that already has files on server endpoints. What happens?**
→ The existing cloud files **merge** with the files already present on the server endpoints. No files are deleted.

**Q: Data3 is on Server3 which is NOT registered to Sync1. Will data3 sync to Group1?**
→ **No.** Only servers registered to the Storage Sync Service can have server endpoints added to sync groups.

**Q: You create a storage account named contosostorage and a file share named data. What UNC path do you use in a script to reference files from data?**
→ `\\contosostorage.file.core.windows.net\data`

**Q: Which storage accounts support lifecycle management rules for hot/cool/archive tiering?**
→ **GPv2, BlobStorage, and BlockBlobStorage** accounts. GPv1 does NOT support lifecycle management.

**Q: Premium Azure file shares are hosted in which account type?**
→ **FileStorage** account (a special-purpose account kind).

---

## 📁 Azure File Share Backup

Azure Backup supports backing up **Azure file shares** directly through Recovery Services vaults.

| Rule | Detail |
|------|--------|
| Vault region | Must be in the **same region** as the storage account |
| Storage account scope | Only storage accounts in the **same region** as the vault are discovered |
| Supported | Azure file shares (share1 in a storage account in West US → Vault in West US) |
| NOT supported | Blob containers cannot be backed up to Recovery Services vaults |

> 💡 **Example**: Vault1 is in East US, Vault2 is in West US. Storage1 (West US) contains share1 and blob1.
> - Vault1 can back up: Nothing from storage1 (different region)
> - Vault2 can back up: **share1 only** (blob containers not supported by vault backup)
