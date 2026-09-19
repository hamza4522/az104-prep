# Azure Files & Azure File Sync

> 🎯 Exam Weight: Part of 15–20% Storage domain

---

## 🔑 Azure Files Overview

- Fully managed **cloud file shares** accessible via industry-standard **SMB** (Server Message Block 3.0) and **NFS 4.1** protocols
- Concurrently mountable by cloud VMs and on-premises Windows, Linux, and macOS clients
- Replaces traditional on-premises file servers (NAS/SAN) without requiring VM management

### Protocol & Port Requirements
- **SMB 3.0**: Requires **Port 445 outbound**
- **ISP Port 445 Blocking**: Many residential ISPs and public networks block port 445:
  - **Workaround 1**: Establish a **VPN connection** (P2S or S2S) or **ExpressRoute** to Azure, then mount over private IP.
  - **Workaround 2**: Deploy **Azure File Sync** on an on-premises server; local clients access the local server over LAN SMB, and the server syncs to Azure over HTTPS (Port 443).

---

## 📦 Storage Tiers & Capacities

| Tier | Drive Type | Billing Model | Minimum Size | Primary Use Case |
|------|------------|---------------|--------------|------------------|
| **Premium** | SSD | Provisioned | 100 GiB | High IOPS, latency-sensitive, databases |
| **Transaction Optimized** | HDD | Pay-as-you-go | None | Heavy transaction workloads, standard shares |
| **Hot** | HDD | Pay-as-you-go | None | General team file shares, regular access |
| **Cool** | HDD | Pay-as-you-go | None | Archive, backup shares, infrequent access |

> 💡 **Large File Shares**: Standard storage accounts support up to **100 TiB** per file share (requires the **Large file shares** feature to be enabled on the storage account; cannot be disabled once turned on).

---

## 🔌 Mounting Azure File Shares

```cmd
# Windows command prompt: Persistent drive mapping
net use Z: \\mystorageacct.file.core.windows.net\myshare /u:AZURE\mystorageacct <StorageAccountKey> /persistent:yes
```

```powershell
# PowerShell: Test port 445 and map drive
$connectTest = Test-NetConnection -ComputerName mystorageacct.file.core.windows.net -Port 445
if ($connectTest.TcpTestSucceeded) {
    New-PSDrive -Name Z -PSProvider FileSystem -Root "\\mystorageacct.file.core.windows.net\myshare" -Persist
} else {
    Write-Error "Port 445 is blocked. Route traffic through VPN or deploy Azure File Sync."
}
```

---

## 🔄 Azure File Sync Architecture & Step-by-Step Deployment

Azure File Sync centralizes file shares in Azure Files while retaining the flexibility, performance, and compatibility of an on-premises Windows file server.

```
[Azure Files: Cloud Endpoint]
            ▲
            │ HTTPS (Port 443) Sync
            ▼
[Storage Sync Service] ── Sync Group
            ▲
            │ HTTPS (Port 443)
            ▼
[Registered Server 1 (Local Folder: D:\Data)] ── Server Endpoint (Cloud Tiering Enabled)
```

### 🛠️ Mandatory Deployment Steps (Tested on Exam!)
1. **Create a Storage Sync Service** in Azure within the desired region.
2. **Prepare On-Premises Server**: Ensure Windows Server runs NTFS (ReFS and FAT are NOT supported for server endpoints).
3. **Install the Azure File Sync Agent** on the Windows Server.
4. **Register the Server** with the Storage Sync Service using Azure credentials.
5. **Create a Sync Group** inside the Storage Sync Service.
6. **Add a Cloud Endpoint**: Select the storage account and Azure file share (each sync group has **exactly one** Cloud Endpoint).
7. **Add a Server Endpoint**: Select the registered server, specify the local path (e.g., `D:\DepartmentShare`), and configure Cloud Tiering.

---

## ☁️ Cloud Tiering Mechanics

Cloud Tiering splits files between local server storage and Azure Files:
- **Frequently accessed files** remain cached locally on the Windows Server.
- **Infrequently accessed files** are tiered to Azure Files; the local file is converted into a **pointer/stub (reparse point)** with the offline attribute `FILE_ATTRIBUTE_OFFLINE` (displayed with an `O` or an "X" in File Explorer).
- When a user opens a tiered file, Azure File Sync seamlessly recalls the data from Azure in real-time.

### Cloud Tiering Policies
1. **Volume Free Space Policy**: Sets the minimum percentage of free space to keep on the local disk volume (e.g., *Always keep 20% free space*).
2. **Date Policy**: Caches files accessed within a specific number of days (e.g., *Cache files accessed within the last 14 days*).

> ⚠️ **Cloud Change Detection Gotcha**: If files are added or modified directly in the Azure File Share (via Portal or AzCopy), Azure File Sync does not detect them immediately. The cloud change detection job runs only **once every 24 hours**.
>
> 💡 **Immediate Sync Fix**: To force immediate detection of changes in the cloud share, run:
> ```powershell
> Invoke-AzStorageSyncChangeDetection -ResourceGroupName "RG1" `
>   -StorageSyncServiceName "SyncService1" `
>   -SyncGroupName "SyncGroup1" `
>   -Path "subfolder/path"
> ```

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Azure Files SMB outbound port | **Port 445** (TCP) |
| Azure File Sync communication port | **Port 443** (HTTPS) |
| Cloud endpoints per Sync Group | Exactly **1** Cloud Endpoint |
| Supported local filesystem for Server Endpoint | **NTFS only** (FAT, FAT32, ReFS are NOT supported) |
| Tiered file attribute | Offline attribute (`O` / `FILE_ATTRIBUTE_OFFLINE`) |
| Cloud change detection interval | Automatically runs every 24 hours |
| Manual cloud change scan command | `Invoke-AzStorageSyncChangeDetection` |
| Maximum snapshots per file share | **200 snapshots** |
| Max standard file share capacity | Up to **100 TiB** (with large file shares enabled) |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: Users on an on-premises network cannot map an Azure file share directly using `net use`. Network diagnostics show outbound port 445 is blocked by their Internet Service Provider (ISP). How can users access the files?**
→ Either establish a **Point-to-Site (P2S) VPN** to Azure to bypass ISP port 445 blocking, OR deploy **Azure File Sync** on a local Windows Server so clients connect over LAN SMB.

**Q: You need to deploy Azure File Sync. In which sequence should you perform the administrative tasks?**
→ 
1. Create a Storage Sync Service.
2. Install the Azure File Sync agent on the Windows Server.
3. Register the server with the Storage Sync Service.
4. Create a Sync Group and add a Cloud Endpoint.
5. Add a Server Endpoint with Cloud Tiering enabled.

**Q: An administrator uploads 500 files directly to an Azure File share using Azure Storage Explorer. Two hours later, users accessing the synced on-premises file server cannot see the new files. What should you do?**
→ Azure File Sync detects cloud changes only once every 24 hours. To make the files available immediately on-premises, run the `Invoke-AzStorageSyncChangeDetection` PowerShell cmdlet.

**Q: Server1 has a 1 TB volume hosting a synced file share with Cloud Tiering enabled. The volume free space policy is set to 25%. What happens when disk usage reaches 80% (only 20% free space left)?**
→ Azure File Sync automatically tiers the least recently accessed files to Azure Files until free space on the volume reaches 25%.
