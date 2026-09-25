# 🖥️ Compute — Virtual Machines

> **AWS Parallel:** EC2 → Azure Virtual Machines  
> **GCP Parallel:** Compute Engine → Azure VMs  
> **OCI Parallel:** OCI Compute → Azure VMs

## Azure VM vs EC2 — Key Differences

| Concept | Azure VM | AWS EC2 |
|---|---|---|
| Instance types | VM sizes (Standard_D2s_v3) | Instance types (m5.large) |
| AMI equivalent | Azure Marketplace Image / Custom Image | AMI |
| User data | Custom Script Extension / cloud-init | User data |
| Instance profile | Managed Identity | IAM Instance Profile |
| Key pair | SSH key stored per VM | EC2 key pair (region-level) |
| Auto scaling | VMSS (VM Scale Sets) | Auto Scaling Group |
| Dedicated host | Azure Dedicated Host | EC2 Dedicated Host |
| Spot instances | Azure Spot VMs | EC2 Spot Instances |
| Reserved instances | Azure Reservations | Reserved Instances |
| Hibernate | Hibernation (preview) | EC2 Hibernate |
| Disk | Azure Managed Disks | EBS volumes |
| OS disk | Managed disk (default) | Root EBS volume |
| Temporary disk | Temp disk (ephemeral) | Instance store |
| Snapshots | Disk snapshots | EBS snapshots |

---

## VM Size Naming Convention

```
Standard_D4s_v5
│        │ │  │
│        │ │  └── Version (v3, v4, v5, etc.)
│        │ └───── 's' = Premium SSD support, 'a' = AMD, 'm' = high memory
│        └─────── D = General purpose, E = Memory optimized,
│                 F = Compute optimized, L = Storage optimized,
│                 N = GPU, H = High performance compute
└───────────────── Tier (Standard, Basic [legacy])

Size: D4 = 4 vCPUs
```

---

## Labs in This Section

| Lab | Title | Difficulty |
|---|---|---|
| Lab-01 | Create and Manage VMs | 🟢 |
| Lab-02 | VM Extensions & Custom Script | 🟡 |
| Lab-03 | VM Scale Sets (VMSS) — Auto Scaling | 🟡 |
| Lab-04 | Availability Sets & Availability Zones | 🟡 |
| Lab-05 | Azure Bastion — Secure Remote Access | 🟡 |
| Lab-06 | Managed Disks — Backup & Snapshots | 🟡 |
| Lab-07 | Custom VM Images with Azure Image Builder | 🔴 |
| Lab-08 | Spot VMs & Azure Reservations | 🟡 |
| Lab-09 | VM Performance Monitoring | 🟡 |
