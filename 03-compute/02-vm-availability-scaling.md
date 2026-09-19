# VM Availability & Scaling

> 🎯 Exam Weight: Part of 20–25% Compute domain

---

## 🔑 High Availability Building Blocks

```
Datacenter Scope ───────── Availability Set (Fault & Update Domains)
Datacenter Scope ───────── Proximity Placement Group (Ultra-low network latency)
Regional Scope ─────────── Availability Zones (1, 2, 3 independent datacenters)
Auto-scaling Cluster ───── Virtual Machine Scale Sets (VMSS)
```

---

## 🛡️ Availability Sets (Within 1 Datacenter)

Protects against hardware failures and host maintenance within a single datacenter:
- **Fault Domains (FD)**: Share common power source and physical network switch (rack level). **Default: 2 or 3 FDs**.
- **Update Domains (UD)**: Group of VMs that are rebooted together during platform updates. **Default: 5 UDs (up to 20 UDs)**.
- **Aligned Managed Disks**: Managed disks automatically align with compute fault domains so disk failures correspond to VM fault domains.

> ⚠️ **Exam Gotcha**: You **cannot move an existing VM into an Availability Set** after it is created! The VM must be deleted and recreated with the availability set specified.

---

## ⚡ Proximity Placement Groups (PPG)

- A logical grouping capability used to ensure that Azure compute resources are **physically located as close as possible to each other** (same datacenter/building).
- **Primary Goal**: Achieve the **lowest possible network latency** between VMs.
- **Supported Resources in a PPG**:
  - Virtual Machines
  - Availability Sets
  - Virtual Machine Scale Sets (VMSS)

> 💡 **Exam Question Pattern**: When an exam question requires *"sub-millisecond network latency between application tier and database tier VMs"*, the answer is **Proximity Placement Group**.

```bash
# Azure CLI: Create PPG and deploy VM inside it
az ppg create --name "MyPPG" --resource-group "RG1" --location "eastus"
az vm create --resource-group "RG1" --name "AppVM1" --ppg "MyPPG" ...
```

---

## 📈 Virtual Machine Scale Sets (VMSS)

- Deploys and manages a group of identical, load-balanced VMs
- Scales automatically based on demand metrics or a schedule

### Upgrade Policies
| Policy | Behavior |
|--------|----------|
| **Manual** | VM instances do not update until explicitly triggered by the admin |
| **Rolling** | Updates instances in batches with gradual rollout to maintain uptime |
| **Automatic** | All instances update immediately when a new model/image is applied |

### Autoscale Rules Architecture
- **Scale Out**: Increases instance count (e.g. *Add 2 instances when average CPU > 75% for 10 minutes*).
- **Scale In**: Reduces instance count (e.g. *Remove 1 instance when average CPU < 25% for 15 minutes*).
- **Cool Down**: Waiting period after a scale event before evaluating metrics again (prevents rapid flapping).

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Availability Set Max Fault Domains | **3** (or 2 depending on region) |
| Availability Set Max Update Domains | **20** (default is 5) |
| Moving existing VM to Availability Set | Not supported; must recreate VM |
| Ultra-low network latency between VMs | Deploy inside a **Proximity Placement Group (PPG)** |
| Scale Set Upgrade Policies | Manual, Rolling, Automatic |
| Availability Zones in a region | **3** physically separate zones with independent power/cooling |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You have a mission-critical multi-tier application. You need to ensure the lowest possible network latency between the web tier and the database tier VMs.**
→ Create a **Proximity Placement Group (PPG)** and deploy both the web and database tier VMs (or their Availability Sets) into the same PPG.

**Q: You configure a Virtual Machine Scale Set (VMSS). When you update the base OS image in the scale set model, existing VM instances are not updating. What is the cause?**
→ The scale set upgrade policy is configured as **Manual**. You must either trigger an instance upgrade manually or set the upgrade policy to **Automatic** or **Rolling**.

**Q: You have an existing production VM named VM1. Your manager asks you to add VM1 to an existing Availability Set named AS1.**
→ You cannot add an existing VM to an Availability Set. You must **delete VM1 while keeping its OS disk**, and recreate VM1 referencing AS1.
