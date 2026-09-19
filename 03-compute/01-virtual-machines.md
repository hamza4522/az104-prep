# Azure Virtual Machines

> 🎯 Exam Weight: Part of 20–25% Compute domain — HIGH EXAM WEIGHT!

---

## 🔑 Core Architecture

- **Infrastructure as a Service (IaaS)** providing scalable compute capacity
- Core VM dependencies:
  - **OS Disk**: Managed disk (Standard HDD, Standard SSD, Premium SSD, Ultra Disk)
  - **Network Interface (NIC)**: Connected to a subnet in an Azure Virtual Network
  - **Temporary Disk (D: drive)**: Fast ephemeral storage directly on host hardware; **data is wiped upon restart, resize, or redeploy**!

---

## 🔄 VM Lifecycle & Troubleshooting Operations

| Operation | State | Compute Billing | Host Hardware | Ephemeral Data (D: Drive) | Public IP |
|-----------|-------|-----------------|---------------|---------------------------|-----------|
| **Stop (Guest OS shutdown)** | Stopped | ✅ **Still billed** | Same host | Preserved | Preserved |
| **Deallocate (Portal/CLI)** | Stopped (Deallocated) | ❌ **Compute halted** | Released | **Wiped** | Changes (if dynamic) |
| **Restart** | Running | ✅ Billed | Same host | Preserved | Preserved |
| **Redeploy** | Running | ✅ Billed | **Moved to new host** | **Wiped** | Changes (if dynamic) |

### 🚨 VM Maintenance & The Redeploy Action (Frequent Exam Question!)
- When Azure plans physical hardware maintenance on an underlying host, administrators receive a **Planned Maintenance Notification**.
- **Requirement**: You need to move VM1 to a different physical Azure host **immediately** to avoid disruption during scheduled maintenance hours.
- **Solution**: Navigate to the VM blade > **Support + troubleshooting** > click **Redeploy**.
  - Redeploy shuts down the VM, provisions it on fresh hardware in the same datacenter, and boots it back up.
  - Temporary disk (D:) is erased. Static public IPs and managed disks are preserved.

### 📐 Resizing Virtual Machines
- Resizing changes CPU cores and RAM (e.g. from `Standard_D2s_v3` to `Standard_D4s_v3`).
- **Exam Gotcha**: If the desired VM size is not supported on the physical hardware cluster currently hosting the VM, the resize operation fails or the size appears greyed out.
- **Resolution**: **Deallocate** the VM first (`Stop-AzVM`), perform the resize, and start the VM again. Deallocating allows Azure to move the VM to a hardware cluster supporting the new size.

---

## ⚙️ Automated Deployment & Configuration Tools

| Tool | OS | Execution Point | Key Requirement |
|------|----|-----------------|-----------------|
| **cloud-init** | **Linux only** | First boot initialization | Passed via `--custom-data` parameter during creation |
| **Custom Script Extension** | Windows / Linux | Post-deployment extension | Requires network/storage access to download script (timeout: 90 min) |
| **Run Command** | Windows / Linux | On-demand management | Uses VM Agent directly; **no inbound network ports required** |

```bash
# Azure CLI: Deploy Ubuntu VM with cloud-init configuration
az vm create   --resource-group "RG1"   --name "UbuntuVM1"   --image "Ubuntu2204"   --admin-username "azureuser"   --generate-ssh-keys   --custom-data @cloud-init.txt
```

---

## 💾 Disks & Host Caching Rules

### Disk Caching Options
| Caching Option | Reads | Writes | Recommended Workload |
|----------------|-------|--------|----------------------|
| **None** | Direct to disk | Direct to disk | **Write-heavy workloads**, SQL Server log files (`.ldf`) |
| **ReadOnly** | Cached from host RAM/SSD | Direct to disk | **Read-heavy workloads**, SQL Server data files (`.mdf`), OS disks |
| **Read/Write** | Cached | Cached | Default for OS disks; general desktop/web workloads |

> ⚠️ **SQL Server Best Practice**: Database transaction log files (`.ldf`) must have host caching set to **None** to prevent data loss or corruption during abrupt power failures.

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Move VM to new physical host immediately | **Redeploy** |
| Avoid charges while VM is stopped | Must be in **Stopped (Deallocated)** status |
| Ephemeral D: drive behavior | Data erased whenever VM moves hosts or deallocates |
| Linux bootstrapping tool | **cloud-init** via `--custom-data` |
| Execute script without opening inbound ports | **Run Command** |
| Generation 2 VM advantages | UEFI boot, OS disks > 2 TB, Trusted Launch |
| Caching for database log files | **None** |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You receive an Azure notification that a host running VM1 will undergo planned hardware maintenance over the weekend. You need to move VM1 to a different host immediately.**
→ From the VM blade, select **Redeploy**.

**Q: You attempt to resize VM1 to a larger GPU-enabled series, but the desired size is unavailable in the dropdown.**
→ Stop and **Deallocate** VM1 first. Then change the VM size and start the VM.

**Q: You need to automate the installation of NGINX on a new Ubuntu Linux VM at deployment time with minimal administrative overhead.**
→ Create a `cloud-init.txt` configuration file and pass it using the `--custom-data` parameter when executing `az vm create`.

**Q: You attach a new 1 TB managed data disk to VM1 for storing transaction logs for a high-performance database. Which host cache setting should you choose?**
→ Set Host Caching to **None**.
