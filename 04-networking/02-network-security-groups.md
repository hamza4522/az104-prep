# Network Security Groups (NSGs) & ASGs

> 🎯 Exam Weight: Part of 25–30% Networking domain

---

## 🔑 What are Network Security Groups?

- **Stateful packet filtering firewalls** (Layer 3/4) that control inbound and outbound traffic
- Applied at two levels:
  1. **Subnet level**: Filters traffic for all NICs connected to that subnet
  2. **Network Interface (NIC) level**: Filters traffic for a specific VM

---

## ⚡ NSG Rule Evaluation Order

```
INBOUND TRAFFIC:
[Packet Arrives] ──➔ [Subnet NSG] (Evaluated 1st) ──➔ [NIC NSG] (Evaluated 2nd) ──➔ [VM]
(Must be ALLOWED by Subnet NSG AND ALLOWED by NIC NSG)

OUTBOUND TRAFFIC:
[VM] ──➔ [NIC NSG] (Evaluated 1st) ──➔ [Subnet NSG] (Evaluated 2nd) ──➔ [Destination]
(Must be ALLOWED by NIC NSG AND ALLOWED by Subnet NSG)
```

> ⚠️ **Evaluation Principle**:
> - Rules are processed in **priority order** (100 to 4096).
> - **Lower numbers have higher priority**! (Rule with priority 100 beats rule with priority 500).
> - As soon as a packet matches a rule, processing **stops** (first match wins).

---

## 🛡️ Default NSG Rules (Cannot be deleted!)

### Default Inbound Rules
| Priority | Rule Name | Source | Destination | Protocol | Action |
|----------|-----------|--------|-------------|----------|--------|
| **65000** | `AllowVnetInBound` | `VirtualNetwork` | `VirtualNetwork` | Any | **Allow** |
| **65001** | `AllowAzureLoadBalancerInBound` | `AzureLoadBalancer` | Any | Any | **Allow** |
| **65500** | `DenyAllInBound` | Any | Any | Any | **Deny** |

### Default Outbound Rules
| Priority | Rule Name | Source | Destination | Protocol | Action |
|----------|-----------|--------|-------------|----------|--------|
| **65000** | `AllowVnetOutBound` | `VirtualNetwork` | `VirtualNetwork` | Any | **Allow** |
| **65001** | `AllowInternetOutBound` | Any | `Internet` | Any | **Allow** |
| **65500** | `DenyAllOutBound` | Any | Any | Any | **Deny** |

---

## 🏷️ Application Security Groups (ASGs)

- Logical grouping of network interfaces (NICs) based on workload function (e.g. `Web-ASG`, `Database-ASG`)
- Allows writing clean NSG rules based on application tier rather than hardcoded IP addresses:
  - *Allow Inbound Port 443 from Internet to `Web-ASG`*
  - *Allow Inbound Port 1433 from `Web-ASG` to `Database-ASG`*
  - *Deny Inbound from Internet to `Database-ASG`*

> ⚠️ **CRITICAL ASG Limitation**: All network interfaces assigned to an ASG **must exist within the same Virtual Network**! An ASG cannot span across multiple VNets.

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| NSG Rule Priority Range | **100 to 4096** |
| Rule processing order | Lower number = higher priority; first match wins |
| Subnet vs NIC NSG evaluation | Inbound: Subnet first, NIC second. Outbound: NIC first, Subnet second |
| Default rules editable? | Cannot be deleted or modified; can be overridden with higher-priority rules |
| Default inter-subnet communication | Allowed by default within the same VNet (`AllowVnetInBound` 65000) |
| ASG cross-VNet constraint | NICs in an ASG must reside in the same VNet |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You need to establish RDP connections (port 3389) from the internet to VM1. Subnet1 has an NSG named NSG-Subnet1. VM1 has an NSG named NSG-VM1. What rules must you configure?**
→ You must create an inbound allow rule for port 3389 in **BOTH** `NSG-Subnet1` and `NSG-VM1` (or remove `NSG-VM1` and configure `NSG-Subnet1` to allow 3389). If either NSG blocks port 3389, traffic is dropped.

**Q: An administrator creates an inbound rule with priority 500 allowing HTTPS (port 443) from any source. However, users still cannot connect over HTTPS. You find an existing inbound rule with priority 400 that denies all TCP traffic. How do you resolve this?**
→ Change the priority of the HTTPS allow rule to a number **lower than 400** (e.g., priority 350) so it evaluates before the deny rule.

**Q: You need to group 5 web server VMs located across 3 different subnets in VNet1 so that an NSG can manage their access with a single rule.**
→ Create an **Application Security Group (ASG)** named `Web-ASG`, associate the network interfaces of all 5 VMs to `Web-ASG`, and use `Web-ASG` as the target destination in the NSG rule.
