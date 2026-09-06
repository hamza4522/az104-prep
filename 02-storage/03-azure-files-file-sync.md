# Azure Files & Azure File Sync

> 🎯 Exam Weight: Part of 15–20% Storage domain

---

## 🔑 Azure Files

### What is Azure Files?
- Fully managed **file shares in the cloud** accessible via **SMB** (Server Message Block) and **NFS** protocols
- Can be mounted on Windows, Linux, and macOS
- Perfect replacement for on-premises file servers

### Key Differences: Azure Files vs Blob Storage
| Feature | Azure Files | Blob Storage |
|---------|------------|-------------|
| **Protocol** | SMB / NFS | HTTP/HTTPS REST |
| **Use Case** | File shares (lift & shift) | Unstructured data, web |
| **Access** | Mount as drive | URL/API |
| **Hierarchy** | Real directory structure | Virtual paths via / |

---

## 📦 Azure Files Tiers

| Tier | Performance | Min Size | Use Case |
|------|-------------|----------|----------|
| **Transaction Optimized** | Standard (HDD) | None | General-purpose workloads, high transactions |
| **Hot** | Standard (HDD) | None | Active file shares |
| **Cool** | Standard (HDD) | None | Archives, backups — lower cost |
| **Premium** | SSD | **100 GiB** | Latency-sensitive workloads, databases |

> ⚠️ **Premium file shares** have a **minimum provisioned size of 100 GiB**.

---

## 🔌 Mounting Azure Files

### Windows
```cmd
# Map a drive (persistent)
net use Z: \\{account}.file.core.windows.net\{share} /u:{account} {access-key} /persistent:yes

# PowerShell
$connectTestResult = Test-NetConnection -ComputerName {account}.file.core.windows.net -Port 445
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\{account}.file.core.windows.net\{share}" -Persist
```

> ⚠️ Azure Files uses **port 445** (SMB). Many ISPs/corporate firewalls block port 445. Check connectivity first!

### Linux
```bash
# Install cifs-utils
sudo apt install cifs-utils

# Mount
sudo mount -t cifs //{account}.file.core.windows.net/{share} /mnt/myshare \
  -o vers=3.0,username={account},password={access-key},dir_mode=0777,file_mode=0777
```

---

## 📸 Snapshots

- **Point-in-time copies** of file shares
- Read-only, incremental (only changed data stored)
- Can browse and restore individual files from a snapshot
- Max **200 snapshots** per file share
- Retained until manually deleted (or through lifecycle policy)

---

## 🔒 Azure Files Authentication

| Method | Description |
|--------|-------------|
| **Storage account key** | Full access, not user-specific |
| **Azure AD Domain Services (AAD DS)** | SMB authentication using Azure AD identities |
| **On-premises AD DS** | Kerberos authentication with on-prem Active Directory |
| **SAS tokens** | For REST API access only (not SMB) |

---

## 🔄 Azure File Sync

### What is Azure File Sync?
- Synchronizes **on-premises file servers** with **Azure Files**
- Enables **multi-site sync** — multiple servers share the same file share
- **Cloud tiering** — keep only frequently accessed files on-prem, rest in Azure

### Key Components
| Component | Description |
|-----------|-------------|
| **Storage Sync Service** | Top-level Azure resource for File Sync |
| **Sync Group** | Defines sync topology (one cloud endpoint + server endpoints) |
| **Cloud Endpoint** | The Azure File share |
| **Server Endpoint** | A path on a Windows Server |
| **Azure File Sync Agent** | Installed on Windows Server |

### File Sync Architecture
```
Azure File Share (cloud endpoint)
        ↕ sync
On-Premises Windows Server (server endpoint)
        ↕ sync (optional)
Another Windows Server (server endpoint)
```

### Cloud Tiering
- **Automatically moves** infrequently accessed files to Azure Files
- On-prem shows a **stub file** (placeholder) — transparent to users
- Files are recalled automatically when accessed (or use `Invoke-StorageSyncFileRecall`)
- Configure tiering policies:
  - **Volume free space**: Keep X% of local disk free
  - **Date policy**: Tier files not accessed in N days

> 💡 **Use Azure File Sync** when you want to:
> - Replace aging on-premises file servers
> - Have the same files accessible from multiple servers
> - Reduce local storage while keeping cloud backup

---

## 📋 File Sync Setup Steps

1. Deploy **Storage Sync Service** in Azure
2. Create a **Sync Group** with Azure File share as cloud endpoint
3. Install **Azure File Sync agent** on Windows Server
4. **Register** the server with Storage Sync Service
5. Add **server endpoint** to the sync group
6. Wait for initial **sync to complete**

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Azure Files protocol | **SMB** (Windows) and **NFS** (Linux) |
| SMB port | **445** |
| Premium file share min size | **100 GiB** |
| Max snapshots per share | **200** |
| File Sync agent installs on | **Windows Server** |
| Components in File Sync | Storage Sync Service, Sync Group, Cloud Endpoint, Server Endpoint |
| Cloud tiering keeps | Stubs on-prem, data in Azure |
| Max sync groups per Storage Sync Service | **100** |
| Max servers per sync group | **50** (actually per cloud endpoint) |

---

## 🚨 Common Exam Scenarios

**Q: A company wants to replace their on-premises file server but some users must access files locally via mapped drives. What solution?**
→ **Azure File Sync** — sync on-prem server with Azure Files, users still use mapped drives

**Q: Port 445 is blocked by the corporate firewall. How can Windows VMs in Azure still access Azure Files?**
→ Traffic between Azure VMs and Azure storage stays on the Azure backbone — port 445 isn't blocked within Azure. The issue is only for on-premises clients.

**Q: A file share needs to support multiple Windows Servers as a DFS-like solution. What Azure service?**
→ **Azure File Sync** with multiple server endpoints in the same sync group

**Q: A team needs a file share that can be mounted on both Windows (SMB) and Linux (NFS). What do you use?**
→ **Azure Files** — supports both SMB and NFS protocols (NFS requires Premium tier)

**Q: You want to keep only the last 30 days of files on-prem but have 5 years of data in Azure. What feature?**
→ **Cloud tiering** in Azure File Sync with a date policy (tier files older than 30 days)
