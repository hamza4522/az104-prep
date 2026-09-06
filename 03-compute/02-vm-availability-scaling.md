# VM Availability & Scaling

> 🎯 Exam Weight: Part of 20–25% Compute domain

---

## 🔑 Availability Concepts

### SLA (Service Level Agreement)
| Configuration | SLA |
|--------------|-----|
| Single VM with Premium SSD | **99.9%** |
| VMs in Availability Set | **99.95%** |
| VMs in Availability Zones | **99.99%** |

> ⚠️ A **single VM** does NOT get 99.99% SLA — you need multiple VMs in an Availability Zone or Availability Set.

---

## 🏢 Availability Sets

### What They Are
- Logical grouping of VMs to protect against **hardware failures** and **planned maintenance** within a **single datacenter**
- VMs are distributed across:
  - **Fault Domains (FD)**: Separate physical hardware (power/network/rack). Max 3 FDs.
  - **Update Domains (UD)**: Groups that are updated separately during planned maintenance. Max 20 UDs.

### Key Facts
| Fact | Value |
|------|-------|
| Max fault domains | **3** |
| Max update domains | **20** |
| Default update domains | **5** |
| Protection against | Hardware failures + planned maintenance |
| Does NOT protect against | Datacenter failure, regional outage |
| Cost | No extra cost (just VMs) |

> ⚠️ **Exam Gotcha**: Availability Sets only protect within **one datacenter/building**. They do NOT protect against a datacenter going down.

### Example Layout
```
Availability Set: WebFarm
    FD0 + UD0: VM1
    FD1 + UD1: VM2
    FD2 + UD2: VM3
```
If FD0 (a server rack) fails → only VM1 is affected. VM2 and VM3 are still running.

---

## 🌍 Availability Zones

### What They Are
- **Physically separate datacenters** within a region (different buildings with independent power/cooling/network)
- Typically 3 zones per region (Zone 1, Zone 2, Zone 3)
- VMs deployed across zones = **highest availability SLA (99.99%)**

### Availability Zones vs Availability Sets
| Feature | Availability Set | Availability Zone |
|---------|-----------------|------------------|
| Location | Same datacenter | Different datacenters |
| Protection | Hardware/maintenance | Datacenter failure |
| SLA | 99.95% | **99.99%** |
| Zones required | No (just logical grouping) | Yes (3 zones) |
| Can combine | No | No (mutually exclusive for VMs) |

> 💡 Use **Availability Zones** for highest protection. Use **Availability Sets** in regions that don't support zones.

---

## ⬆️ Virtual Machine Scale Sets (VMSS)

### What They Are
- Deploy and manage a **group of identical VMs**
- Automatically **scale in/out** based on demand or schedule
- Load balancer distributes traffic across instances

### Scaling Types
| Type | Trigger | Response |
|------|---------|----------|
| **Manual scaling** | Admin changes instance count | Immediate |
| **Schedule-based** | Time/date | Scale at specific times |
| **Metric-based (autoscale)** | CPU%, memory, custom metrics | Dynamic scale-out/in |

### Key VMSS Settings
| Setting | Description |
|---------|-------------|
| **Minimum instances** | Floor — never scale below this |
| **Maximum instances** | Ceiling — never scale above this |
| **Default instances** | Starting count |
| **Scale-out rule** | When to add VMs (e.g., CPU > 75%) |
| **Scale-in rule** | When to remove VMs (e.g., CPU < 25%) |
| **Cool-down period** | Time to wait between scaling events (default 5 min) |

### Orchestration Modes
| Mode | Description |
|------|-------------|
| **Uniform** | All VMs identical, good for stateless workloads |
| **Flexible** | Mix of instance types, more flexibility (newer mode) |

### VMSS Update Policies
| Policy | Description |
|--------|-------------|
| **Automatic** | VMs updated automatically as model changes |
| **Rolling** | VMs updated in batches (minimize downtime) |
| **Manual** | Admin manually triggers update |

---

## 🔄 Scaling In/Out vs Up/Down

| Type | Description | Involves |
|------|-------------|---------|
| **Scale Out** | Add more VMs (horizontal) | More instances |
| **Scale In** | Remove VMs (horizontal) | Fewer instances |
| **Scale Up** | Larger VM size (vertical) | Requires restart |
| **Scale Down** | Smaller VM size (vertical) | Requires restart |

> 💡 **Horizontal scaling (out/in)** is preferred for cloud — no downtime. **Vertical scaling (up/down)** requires VM restart.

---

## 🏗️ Azure Dedicated Hosts

- Provision a physical server **exclusively for your VMs**
- No other customers share the physical host
- Use cases:
  - **Compliance requirements** (hardware isolation)
  - **Bring Your Own License (BYOL)** for Windows Server/SQL Server
  - **Maintenance control** — choose when to apply updates

### Components
- **Host Group**: Container for dedicated hosts in one region/zone
- **Host**: Physical server within a host group

---

## 📋 Azure Spot VMs

- Use **unused Azure capacity** at up to **90% discount**
- Can be **evicted** with 30-second notice when Azure needs capacity back
- Use for: batch jobs, dev/test, workloads that can handle interruption
- **NOT suitable for**: production workloads, databases, anything that must always be running

### Eviction Policy Options
| Policy | On Eviction |
|--------|------------|
| **Deallocate** | VM is stopped/deallocated (can restart later) |
| **Delete** | VM and disks are deleted |

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Single VM SLA | **99.9%** (with Premium SSD) |
| Availability Set SLA | **99.95%** |
| Availability Zone SLA | **99.99%** |
| Max fault domains | **3** |
| Max update domains | **20** |
| Availability Zones per region | Typically **3** |
| VMSS max instances | Up to **1,000** (flexible mode) |
| Scale-up/down requires | **VM restart** |
| Scale-out/in | **No restart** needed |
| Spot VM notice before eviction | **30 seconds** |
| Dedicated Host for | Physical server isolation |

---

## 🚨 Common Exam Scenarios

**Q: A company needs 99.99% SLA for their web tier VMs. What do they need?**
→ Deploy VMs across **Availability Zones** (minimum 2 zones, recommended 3)

**Q: A web application experiences spiky traffic. How do you auto-scale VMs?**
→ Use **Virtual Machine Scale Sets** with metric-based autoscaling (e.g., CPU > 70% = add VMs)

**Q: Two VMs must not be on the same physical server to ensure hardware failure doesn't take both down. What do you use?**
→ Place them in an **Availability Set** — they'll be in different fault domains

**Q: You want to run batch processing jobs cheaply, and it's OK if jobs get interrupted. What VM type?**
→ **Azure Spot VMs** — up to 90% discount, handle evictions gracefully

**Q: An application needs to scale from 2 VMs to 20 VMs during business hours, then back to 2 VMs overnight. What do you configure?**
→ **VMSS with schedule-based autoscaling** rules
