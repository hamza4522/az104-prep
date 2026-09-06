# Azure Virtual Machines

> 🎯 Exam Weight: Part of 20–25% Compute domain

---

## 🔑 What are Azure Virtual Machines?

- IaaS (Infrastructure as a Service) — full control over OS, software, configuration
- You manage: OS patches, middleware, applications
- Azure manages: physical hardware, virtualization, datacenter

---

## 🏗️ VM Components

When you create a VM, Azure creates several resources:

| Resource | Description |
|----------|-------------|
| **Virtual Machine** | The compute resource itself |
| **OS Disk** | Managed disk with the operating system |
| **Virtual Network (VNet)** | Network the VM is connected to |
| **Network Interface (NIC)** | Connects VM to VNet |
| **Public IP address** | (Optional) For internet access |
| **Network Security Group (NSG)** | Firewall rules |

---

## 💾 VM Disk Types

### Disk Roles
| Disk | Description |
|------|-------------|
| **OS Disk** | Contains the operating system, typically C:\ |
| **Temporary Disk** | Local SSD, fast but **ephemeral** (data lost on resize/reboot) |
| **Data Disk** | Additional storage for application data |

> ⚠️ **Temp disk is ephemeral** — never store important data there. It's typically D:\ on Windows, /dev/sdb on Linux.

### Managed Disk Types
| Disk Type | Use Case | Max IOPS | Max Throughput |
|-----------|----------|----------|----------------|
| **Standard HDD** | Dev/test, low I/O | 500 | 60 MB/s |
| **Standard SSD** | Web servers, light production | 6,000 | 750 MB/s |
| **Premium SSD** | Production workloads | 20,000 | 900 MB/s |
| **Premium SSD v2** | Performance-intensive workloads | 80,000 | 1,200 MB/s |
| **Ultra Disk** | Latency-sensitive (DB, SAP) | 160,000 | 4,000 MB/s |

> 💡 **Premium SSD** requires VM sizes that support premium storage (DS, ES, FS series).

### Disk Encryption
| Method | Description |
|--------|-------------|
| **Azure Disk Encryption (ADE)** | Uses BitLocker (Windows) / DM-Crypt (Linux), keys in Key Vault |
| **Server-Side Encryption (SSE)** | Default — data encrypted at rest automatically |
| **Encryption at host** | End-to-end encryption including temp disk and cache |

---

## 📐 VM Sizes

### Size Families
| Series | Purpose |
|--------|---------|
| **B** (Burstable) | Dev/test, low sustained CPU, burstable workloads |
| **D** (General Purpose) | Most workloads, balanced CPU/memory |
| **E** (Memory Optimized) | In-memory DBs, caching (high memory-to-CPU ratio) |
| **F** (Compute Optimized) | CPU-intensive workloads (high CPU-to-memory ratio) |
| **G/M** (Memory & Storage) | Very large memory workloads, SAP HANA |
| **L** (Storage Optimized) | High disk I/O, NoSQL databases |
| **N** (GPU) | Machine learning, graphics rendering |
| **H** (HPC) | High-performance computing simulations |

### Size Name Format
```
Standard_D2s_v3
         ↑ ↑ ↑
         | | └── Version (v3)
         | └──── s = Premium Storage support
         └────── 2 = number of vCPUs
```

> 💡 **Exam Tip**: If a VM size has an **"s"** in the name (e.g., D2**s**v3), it supports **Premium SSD**.

---

## 🔌 VM Connectivity

### Windows VMs
- **RDP** (Remote Desktop Protocol) — Port **3389**
- Azure Bastion for RDP without public IP

### Linux VMs
- **SSH** — Port **22**
- Azure Bastion for SSH without public IP

### Azure Bastion
- Managed PaaS service for **secure RDP/SSH without public IP**
- Deployed in the VNet, accessed via Azure Portal browser
- Requires **AzureBastionSubnet** subnet (/26 or larger)
- Eliminates need to expose port 22/3389 to internet

### Just-in-Time (JIT) VM Access
- Opens RDP/SSH ports **only when needed**, for specified IP/time
- Part of **Microsoft Defender for Cloud**
- Reduces attack surface vs always-open ports

---

## 🔄 VM States & Costs

| State | Description | Compute Billed? | Storage Billed? |
|-------|-------------|-----------------|-----------------|
| **Running** | VM is on | ✅ Yes | ✅ Yes |
| **Stopped** | Stopped inside OS (shutdown command) | ✅ Yes | ✅ Yes |
| **Deallocated** | Stopped via Azure (Stop in portal) | ❌ No | ✅ Yes |
| **Deleted** | VM removed | ❌ No | ❌ No (if managed disks deleted) |

> ⚠️ **Exam Gotcha**: Shutting down a VM from within the OS ("Stop" command in OS) = **Stopped state** — you are **still charged** for compute! You must **Stop (Deallocate)** from the Azure Portal/CLI to avoid compute charges.

---

## 📸 VM Images & Extensions

### VM Images
- Template for VM OS and configuration
- Marketplace images: Windows Server, Ubuntu, RHEL, etc.
- **Custom images**: Create from existing VM using **Azure Compute Gallery** (formerly Shared Image Gallery)
- **Azure Compute Gallery**: Store, version, and share VM images across subscriptions/regions

### VM Extensions
- Small applications that provide **post-deployment configuration**
- Examples:
  | Extension | Purpose |
  |-----------|---------|
  | **Custom Script Extension** | Run scripts during/after deployment |
  | **DSC Extension** | PowerShell Desired State Configuration |
  | **Log Analytics Agent** | Connect VM to Log Analytics workspace |
  | **Azure Monitor Agent** | Modern replacement for Log Analytics agent |
  | **Antimalware Extension** | Microsoft Antimalware for Azure |

---

## 🛠️ Creating VMs

```bash
# Azure CLI
az vm create \
  --resource-group myRG \
  --name myVM \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --location eastus

# PowerShell (simplified)
New-AzVM -ResourceGroupName "myRG" -Name "myVM" -Location "EastUS" -Image "Win2022Datacenter"
```

---

## 🔧 VM Operations

```bash
# Start, Stop, Restart, Deallocate
az vm start --resource-group myRG --name myVM
az vm stop --resource-group myRG --name myVM          # Stopped (still billed!)
az vm deallocate --resource-group myRG --name myVM    # Deallocated (not billed)
az vm restart --resource-group myRG --name myVM

# Resize VM
az vm resize --resource-group myRG --name myVM --size Standard_D4s_v3

# Add a data disk
az vm disk attach --resource-group myRG --vm-name myVM --name myDisk --new --size-gb 128 --sku Premium_LRS
```

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| RDP port | **3389** |
| SSH port | **22** |
| Temp disk data | **Lost** on reboot/resize/redeployment |
| Stopped (OS) vs Deallocated | OS Stop = still billed; Deallocated = not billed |
| Premium SSD requires | VM size with 's' (Premium storage support) |
| Azure Bastion subnet | **AzureBastionSubnet** (/26 min) |
| JIT VM Access requires | Microsoft Defender for Cloud |
| Azure Compute Gallery | Store/share custom VM images |
| Managed disk SSE | **Always on**, cannot disable |

---

## 🚨 Common Exam Scenarios

**Q: A company is running a VM but wants to stop paying for compute. They stopped the VM from within Windows. Are they still being charged?**
→ **Yes** — stopping from within the OS = "Stopped" state, compute is still billed. They need to **Deallocate** from Azure.

**Q: A VM needs to access Azure Key Vault without storing any credentials. What do you configure?**
→ **System-assigned Managed Identity** on the VM, then grant it Key Vault access

**Q: A team needs to connect to Linux VMs via SSH without exposing port 22 to the internet. What do you use?**
→ **Azure Bastion** or **JIT VM Access**

**Q: You need to run a PowerShell script on 50 VMs after deployment. What do you use?**
→ **Custom Script Extension** or **Azure Automation Run Command**

**Q: A VM's OS disk is 30 GB but the application needs 500 GB. How do you add storage?**
→ Add a **data disk** (managed disk) to the VM and format it within the OS
