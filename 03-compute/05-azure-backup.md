# Azure Backup

> 🎯 Exam Weight: Part of 20–25% Compute domain

---

## 🔑 What is Azure Backup?

- Built-in Azure service to **back up and restore** data
- Protects: VMs, Azure Files, SQL in VMs, SAP HANA, on-premises (MARS agent)
- Stores backups in **Recovery Services Vaults** or **Backup Vaults**

---

## 🏛️ Recovery Services Vault

### What It Is
- Centralized storage for backups and recovery points
- Must be in the **same region** as the resource being backed up
- Can have its own **redundancy settings** (LRS, ZRS, GRS)

### Vault Redundancy Options
| Option | Description |
|--------|-------------|
| **LRS** | 3 copies in same datacenter |
| **ZRS** | 3 copies across availability zones |
| **GRS (default)** | 6 copies, primary + secondary region |

> ⚠️ Vault redundancy setting can only be changed **before the first backup** is configured.

### Soft Delete
- **14-day soft delete** for backup data by default
- Deleted backup data retained for 14 days, can be restored
- Can be disabled but recommended to keep enabled

---

## 💻 Azure VM Backup

### How It Works
- **Application-consistent snapshots** (uses VSS on Windows, pre/post scripts on Linux)
- Backup data stored in Recovery Services Vault
- First backup is a **full backup**, subsequent are **incremental**

### VM Backup Process
1. Azure triggers a **snapshot** of the VM disks
2. Snapshot is transferred to the **Recovery Services Vault**
3. Recovery points are created in the vault

### Backup Policy
- Define: **frequency** (daily) and **retention** (how long to keep)
- Retention options: daily, weekly, monthly, yearly retention points

| Retention Period | Max Duration |
|-----------------|-------------|
| Daily | 180 days |
| Weekly | 520 weeks (~10 years) |
| Monthly | 120 months (10 years) |
| Yearly | 99 years |

### Enabling VM Backup
```bash
# Enable backup for a VM
az backup protection enable-for-vm \
  --resource-group myRG \
  --vault-name myVault \
  --vm myVM \
  --policy-name DefaultPolicy

# Trigger an on-demand backup
az backup protection backup-now \
  --resource-group myRG \
  --vault-name myVault \
  --item-name myVM \
  --container-name myVM \
  --backup-management-type AzureIaasVM
```

---

## 🔄 VM Restore Options

| Restore Type | Description | Use Case |
|-------------|-------------|----------|
| **Create new VM** | Deploy a new VM from backup | Full recovery |
| **Restore disk** | Restore managed disk, attach later | Custom recovery |
| **File recovery** | Mount recovery point, browse and copy files | Single file/folder |
| **Replace existing disk** | Swap OS disk on existing VM | In-place recovery |

---

## 📁 Azure Files Backup

- Backs up **Azure File Shares** snapshots
- Stored in the storage account (not Recovery Services Vault)
- Schedule: daily snapshots
- Retention: up to 200 snapshots
- Restore: full share, specific folder, or individual files

---

## 🖥️ On-Premises Backup

### MARS Agent (Microsoft Azure Recovery Services)
- Install on **Windows machines** (on-premises or Azure VMs)
- Backs up **files, folders, and system state** to Recovery Services Vault
- Does NOT back up full VM (files/folders only)

### Azure Backup Server (MABS)
- More comprehensive on-premises backup
- Backs up workloads: Hyper-V, VMware, SQL Server, SharePoint
- Requires Windows Server + DPM (Data Protection Manager) license or standalone MABS

### Comparison
| Solution | What It Backs Up | Platform |
|---------|-----------------|---------|
| **MARS Agent** | Files, folders, system state | Windows (on-prem or VM) |
| **MABS** | VMs, workloads (SQL, SharePoint) | Windows Server |
| **DPM** | Full enterprise workloads | Windows Server + System Center |

---

## 🔒 Azure Site Recovery (ASR)

### What is ASR?
- **Disaster recovery** service — replicates workloads to a secondary location
- Continuous replication, failover, failback
- NOT a backup solution — it's for **business continuity/DR**

### Key Concepts
| Term | Description |
|------|-------------|
| **Primary site** | Where VMs are currently running |
| **Secondary site** | DR target (another Azure region or on-prem) |
| **RPO** | Recovery Point Objective — max data loss (typically 30-60 seconds) |
| **RTO** | Recovery Time Objective — max downtime (typically 2 hours) |
| **Replication** | Continuous async replication to secondary |
| **Test failover** | Test DR without impacting production |
| **Failover** | Switch to secondary site |
| **Failback** | Return to primary after recovery |

### Azure-to-Azure Replication
- Replicate Azure VMs between regions
- Uses **cache storage account** for staging
- Near-zero RPO (seconds to minutes)

> 💡 **ASR vs Azure Backup**:
> - **Azure Backup** = Protect against data loss (files, corruption)
> - **Azure Site Recovery** = Protect against site failure (DR, business continuity)

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Backup vault type | **Recovery Services Vault** |
| Default vault redundancy | **GRS** |
| VM backup type | **Incremental** after first full |
| Soft delete retention | **14 days** |
| MARS agent backs up | **Files and folders** (not full VM) |
| ASR RPO | ~**30 seconds** for Azure-to-Azure |
| Backup vs ASR | Backup = data protection; ASR = DR |
| Vault redundancy change | Only before **first backup** |

---

## 🚨 Common Exam Scenarios

**Q: A company needs to recover individual files from a VM backup taken 3 days ago. What restore type?**
→ **File recovery** — mount the recovery point and copy specific files

**Q: You need to ensure VMs can failover to another Azure region within minutes if the primary region goes down. What do you use?**
→ **Azure Site Recovery** (not Azure Backup — ASR is for DR/failover)

**Q: An on-premises Windows Server needs to back up specific folders to Azure. What's the simplest solution?**
→ Install the **MARS agent** and configure file backup to a Recovery Services Vault

**Q: A company needs to protect against accidental deletion of backup data. What feature?**
→ **Soft delete** — deleted backups are retained for 14 days for recovery

**Q: You deleted a VM. The OS disk was also deleted. You need to recover the VM to its state 2 days ago. What do you use?**
→ **Azure Backup** — restore from the 2-day-old recovery point (create new VM or restore disk)
