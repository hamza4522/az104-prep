# Subscriptions & Management Groups

> 🎯 Exam Weight: Part of 15–20% Identity & Governance domain

---

## 🔑 Azure Hierarchy Overview

```
Azure Account (Enterprise / MCA / Direct)
    └── Azure AD Tenant (Identity Boundary)
            └── Management Groups  ← Policy & RBAC inheritance boundary
                    └── Subscriptions  ← Billing & Quota boundary
                            └── Resource Groups  ← Lifecycle & Management boundary
                                    └── Resources  ← Individual Azure services
```

---

## 🏢 Management Groups

### What They Are
- Containers that help **manage access, policy, and compliance** across multiple subscriptions
- Policies and RBAC applied to a management group **inherit** to all child management groups and subscriptions

### Key Facts & Architecture Rules
| Fact | Value / Rule |
|------|--------------|
| Root Management Group | **Tenant Root Group** (auto-created for every tenant) |
| Max Depth of Hierarchy | **6 levels** (excluding the Root group) |
| Max Management Groups | Up to **10,000** in a single directory |
| Subscription Membership | Each subscription can belong to **only one** management group at a time |
| Direct Resource Placement | Resources **cannot** be placed directly inside a management group (only other MGs or Subscriptions) |
| New Subscriptions Placement | Automatically placed under the **Tenant Root Group** (unless a default MG is explicitly configured) |

```bash
# Azure CLI: Create a management group
az account management-group create --name "ProdMG" --display-name "Production"

# Azure CLI: Move a subscription into a management group
az account management-group subscription add \
  --name "ProdMG" \
  --subscription "00000000-0000-0000-0000-000000000000"

# PowerShell: Move a subscription to a management group
New-AzManagementGroupSubscription -GroupId "ProdMG" -SubscriptionId "00000000-0000-0000-0000-000000000000"
```

---

## 💳 Azure Subscriptions

### What They Are
- **Billing boundary**: Invoices, payment methods, and cost tracking occur at the subscription level
- **Quota & Limit boundary**: Resource limits (vCPU cores, VMs, IPs) are allocated per subscription
- A subscription is always associated with **exactly one Azure AD tenant** at any given time

### Transferring Subscriptions to a Different Tenant
When ownership of a subscription is transferred to a different Azure AD tenant:
- ✅ **Resources remain running**: VMs, databases, and storage accounts continue functioning without downtime
- ❌ **RBAC role assignments are removed**: All role assignments in the source tenant are dropped
- ❌ **Custom roles are not transferred**: They remain in the original tenant directory
- ⚠️ **Key Vault access must be reconfigured**: Key Vaults remain associated with the old tenant ID until explicitly updated via CLI/PowerShell (`az keyvault update --name <kv> --resource-group <rg> --subscription <sub-id>`)
- ⚠️ **User access**: Source tenant users lose all access until roles are assigned in the new tenant

---

## 📦 Resource Groups

### Key Characteristics
- **Logical container** for resources sharing the same lifecycle (deployed, updated, and deleted together)
- Every resource must exist in **exactly one** resource group
- **Region Independence**: The resource group location specifies where its *metadata* is stored; resources inside the group can be in **different regions**
- **Deleting a Resource Group**: Deleting an RG initiates cascading deletion of **all** resources inside it

### Moving Resources Between Groups or Subscriptions
```bash
# CLI: Move resources to a different resource group
az resource move --destination-group "TargetRG" --ids <resource-ids>

# PowerShell: Move resources to a different subscription
Move-AzResource -DestinationSubscriptionId "11111111-1111-1111-1111-111111111111" -DestinationResourceGroupName "TargetRG" -ResourceId <resource-ids>
```

> ⚠️ **Resource Move Rules**:
> 1. Source and target resource groups are **locked** during the move operation.
> 2. You cannot move resources that have specific dependencies (e.g., VPN Gateways, Recovery Services Vaults with backed-up items, or certain App Service certificates without moving the plan).
> 3. Moving a VM requires moving all its associated disks and network interfaces together.

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Hierarchy depth limit | 6 levels (excluding root) |
| Max management groups per directory | 10,000 |
| Subscription-to-tenant relationship | 1 subscription trusts 1 tenant (1 tenant can have many subscriptions) |
| Moving subscription to new tenant | All RBAC role assignments are deleted |
| Resource group metadata vs resource region | Resource group location is metadata-only; resources can reside in different regions |
| Deleting resource group | Permanently deletes all child resources |
| Soft limit increases | Request through Azure Support portal (e.g., regional vCPU quota increases) |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You need to apply a corporate compliance policy and assign permissions across 12 subscriptions managed by different departments.**
→ Create a **Management Group**, place the 12 subscriptions inside the group, and assign the policy and RBAC roles at the **Management Group scope**.

**Q: An organization transfers an Azure subscription containing virtual machines and storage accounts to a new Azure AD directory. What happens to existing RBAC permissions?**
→ All existing RBAC role assignments are **removed**. Administrators in the target tenant must re-assign roles to users and groups in the new directory.

**Q: A developer cannot deploy more than 20 vCPUs in the East US region in a new Pay-As-You-Go subscription. What should you do?**
→ Create a **Support Request** in the Azure portal to request a quota increase for vCPU cores in that region.

**Q: You have resources deployed in West Europe inside a resource group whose location is set to North Europe. If North Europe experiences a regional outage, what is the effect?**
→ The resources in West Europe continue to **run normally**. Only management operations (reading resource group metadata or deploying new resources into that RG) may be temporarily impacted.
