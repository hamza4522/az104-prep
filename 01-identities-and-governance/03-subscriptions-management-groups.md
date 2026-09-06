# Subscriptions & Management Groups

> 🎯 Exam Weight: Part of 15–20% Identity & Governance domain

---

## 🔑 Azure Hierarchy Overview

```
Azure Account (root)
    └── Azure AD Tenant
            └── Management Groups  ← organize subscriptions
                    └── Subscriptions  ← billing boundary
                            └── Resource Groups  ← logical containers
                                    └── Resources  ← actual services
```

---

## 🏢 Management Groups

### What They Are
- Containers that help **manage access, policy, and compliance** across multiple subscriptions
- Used when organizations have **many subscriptions**
- Policies and RBAC applied to a management group **inherit** to all child subscriptions

### Key Facts
| Fact | Value |
|------|-------|
| Default root management group | **Tenant Root Group** (auto-created) |
| Max depth of hierarchy | **6 levels** (not counting root) |
| Max management groups in a directory | **10,000** |
| Each subscription can be in | **Only 1 management group** |
| Management groups can be nested | Yes |

### Management Group Use Cases
- Apply a **policy** requiring all subscriptions to use specific regions
- Assign **RBAC roles** across all subscriptions at once
- Provide a **unified view** across the entire Azure estate

```bash
# CLI: Create a management group
az account management-group create --name "ProdMG" --display-name "Production"

# CLI: Move a subscription to a management group
az account management-group subscription add \
  --name "ProdMG" \
  --subscription "00000000-0000-0000-0000-000000000000"
```

---

## 💳 Azure Subscriptions

### What They Are
- **Billing boundary** — each subscription has its own invoice
- **Access control boundary** — RBAC is applied per subscription
- A subscription is always tied to **one Azure AD tenant**

### Types of Subscriptions
| Type | Description |
|------|-------------|
| **Free** | $200 credit for 30 days, then limited free services |
| **Pay-As-You-Go** | Charged monthly for what you use |
| **Enterprise Agreement (EA)** | Large org, committed spend, discounted rates |
| **CSP (Cloud Solution Provider)** | Purchased through a Microsoft partner |

### Subscription Limits (Soft Limits — can be increased)
| Resource | Default Limit |
|----------|--------------|
| VMs per region | 25,000 |
| VNets per region | 1,000 |
| Resource Groups | 980 |
| vCPU per region | 20 (default) |

> ⚠️ **Exam Gotcha**: Subscription limits are **soft limits** that can be increased by contacting Microsoft support. **Hard limits** cannot be increased.

### Moving Subscriptions
- Subscriptions can be moved to a **different management group**
- Subscriptions can be transferred to a **different Azure AD tenant**
- Resources can be moved between resource groups or subscriptions using **Move-AzResource**

---

## 📦 Resource Groups

### What They Are
- **Logical containers** for Azure resources
- Resources in a group are typically deployed, managed, and deleted together
- A resource can only be in **one resource group** at a time

### Key Rules
| Rule | Detail |
|------|--------|
| Location of resource group | Metadata storage location — resources can be in different regions |
| Deleting a resource group | Deletes **all** resources inside it |
| Moving resources | Resources can be moved between resource groups |
| Resource group can span regions | Yes — group has one location but can contain resources in many regions |
| Resources can communicate across groups | Yes, across groups and even subscriptions |

### Moving Resources Between Groups/Subscriptions
```powershell
# PowerShell
Move-AzResource -ResourceId $resource.ResourceId `
  -DestinationResourceGroupName "NewRG" `
  -DestinationSubscriptionId "new-sub-id"
```

```bash
# Azure CLI
az resource move \
  --destination-group "NewRG" \
  --ids "/subscriptions/{sub}/resourceGroups/OldRG/providers/..."
```

> ⚠️ **Not all resources can be moved!** Some resources like Azure Active Directory Domain Services, Recovery Services vaults with VMs, VNets with certain resources have restrictions.

---

## 💰 Cost Management

### Azure Cost Management + Billing
- Tool for **monitoring, allocating, and optimizing** Azure costs
- View costs by: subscription, resource group, resource, tag, time period

### Budgets
- Set spending thresholds and get **alerts** when approaching/exceeding
- Can set alerts at **actual cost** or **forecasted cost**
- Alerts do NOT automatically stop resources (you need automation for that)

### Cost Optimization Features
| Feature | Description |
|---------|-------------|
| **Azure Reservations** | Pre-pay 1 or 3 years → up to 72% savings |
| **Azure Hybrid Benefit** | Use existing Windows Server/SQL licenses → up to 49% savings |
| **Spot Instances** | Unused Azure capacity at up to 90% discount; can be evicted |
| **Dev/Test Pricing** | Lower rates for non-production workloads |

---

## 🏷️ Tagging

(See also: [Resource Locks & Tags](./05-resource-locks-tags.md))

- Tags are **name-value pairs** applied to resources, resource groups, or subscriptions
- Used for: cost allocation, automation, organization, searching

```bash
# CLI: Add tag to resource group
az group update --name "myRG" --tags "Environment=Production" "Department=IT"

# CLI: List resources by tag
az resource list --tag "Environment=Production"
```

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Tenant Root Group | Auto-created, cannot be deleted or moved |
| Management group hierarchy depth | 6 levels max (below root) |
| Subscriptions per management group | Unlimited |
| One subscription belongs to | ONE management group |
| Resource group can span | Multiple regions |
| Resource group deletion | Deletes ALL resources inside |
| Resource can be in | ONE resource group only |
| Budget alerts stop resources? | **No** — alerts only, no automatic stopping |

---

## 🚨 Common Exam Scenarios

**Q: A company has 50 subscriptions. They want to enforce a policy that all resources must be in US regions only. What's the most efficient approach?**
→ Create a **Management Group**, move all subscriptions into it, apply an **Azure Policy** at the management group level

**Q: A developer accidentally deleted a resource group with important VMs. What happened?**
→ All resources in that resource group were deleted. No automatic recovery unless **Azure Backup** was configured.

**Q: You need to track which team owns each Azure resource for billing purposes. What do you implement?**
→ **Tags** — apply a "Team" or "CostCenter" tag to all resources

**Q: An organization wants to move a subscription from one tenant to another. Is this possible?**
→ **Yes**, subscriptions can be transferred to a different Azure AD tenant, but all role assignments are lost during transfer.
