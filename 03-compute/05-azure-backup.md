# Azure Backup & Recovery Services

> 🎯 Exam Weight: Part of 10–15% Monitoring & Backup domain

---

## 🔑 Recovery Services Vault vs Backup Vault

| Vault Type | Protected Workloads |
|------------|---------------------|
| **Recovery Services Vault** | Azure VMs, SQL Server in Azure VMs, SAP HANA, Azure Files, on-prem physical/virtual servers (via MARS/MABS) |
| **Backup Vault** | Azure Disks, Azure Blobs, Azure PostgreSQL, AKS persistent volumes |

---

## 🛡️ Azure VM Backup Architecture

- Agentless snapshot backup via the **VMSnapshot** extension (automatically installed)
- Application-consistent backups for Windows (VSS) and Linux (pre/post scripts)
- **Backup Policies**:
  - Frequency: Daily, Weekly, Hourly
  - Retention: Daily, Weekly, Monthly, Yearly (Grandfather-Father-Son retention)

### Cross-Region Restore (CRR)
- Requires a vault with **Geo-Redundant Storage (GRS)** and **Cross Region Restore** enabled
- Enables restoring backup items in the Azure **secondary paired region** at any time
- Does **NOT** require waiting for Microsoft to declare a regional disaster!

---

## 🔄 Restore Options for Azure VMs

```
Backup Snapshot
    ├── Create New VM (deploys a new VM directly from the restore point)
    ├── Restore Disks (generates VHD disks + deployment template in storage)
    ├── Replace Existing Disk (swaps the OS disk of the live VM)
    └── File / Folder Recovery (Item-Level Recovery)
```

### File / Folder Level Recovery (Item-Level Recovery)
- Allows recovering individual files without restoring the entire multi-gigabyte VM!
- **How it works**:
  1. Click **File Recovery** in the vault for the VM.
  2. Select the recovery point.
  3. Azure generates a download script (`.exe` for Windows, `.sh` for Linux) containing a temporary password.
  4. Run the script on the target machine: it mounts the backup recovery point as a **local iSCSI volume**.
  5. Browse, copy the required files, and unmount the volume.

---

## 💻 On-Premises Backup: MARS Agent vs MABS

| Feature | MARS Agent (Azure Backup Agent) | Azure Backup Server (MABS) |
|---------|--------------------------------|----------------------------|
| **Architecture** | Lightweight agent on each machine | Dedicated on-prem backup server |
| **Local Storage** | ❌ None (backs up directly to Azure) | ✅ Yes (caches backups to local disk first) |
| **Supported Workloads** | Files, folders, Windows System State | Full VMs (Hyper-V, VMware), SQL, Exchange, SharePoint |
| **Linux Support** | ❌ Windows Server only | ✅ Yes |

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Restore single file without full VM restore | **File Recovery** (iSCSI mount script) |
| Restore to secondary paired region | Vault configured with **GRS** + **Cross Region Restore (CRR)** |
| MARS agent local cache requirement | No local backup storage needed (sends direct to Azure vault) |
| Deleting Recovery Services Vault with items | Blocked! Must first stop backup and delete backup data |
| Max backup retention duration | Up to **9,999 days** (~27 years) |
| Azure VM backup snapshot extension | VMSnapshot / VMSnapshotLinux |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: A user accidentally deletes an Excel spreadsheet from a virtual machine named VM1. You need to restore only the deleted spreadsheet with minimal downtime and administrative overhead.**
→ From the Recovery Services Vault, initiate **File Recovery** for VM1, run the generated script to mount the iSCSI drive, copy the spreadsheet back, and unmount the drive.

**Q: You need to ensure you can restore Azure VM backups in the secondary paired region even when the primary region is fully operational, for disaster recovery drill testing.**
→ Configure the Recovery Services Vault with **Geo-Redundant Storage (GRS)** and enable **Cross-Region Restore (CRR)**.

**Q: You attempt to delete a test Recovery Services Vault, but the operation fails with an error stating protected items exist.**
→ You must first navigate to **Backup Items**, select the protected items, click **Stop backup**, select **Delete backup data**, and disable soft-delete before the vault can be deleted.
