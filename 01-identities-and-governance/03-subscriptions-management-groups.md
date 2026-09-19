# Subscriptions & Management Groups

> 🎯 Exam Weight: Part of 15–20% Identity & Governance domain

---

## 🔑 Azure Subscription Hierarchy

```
Azure AD Tenant (Directory)
    └── Root Management Group (auto-created)
           ├── Management Group A
           │      ├── Subscription 1
           │      └── Subscription 2
           └── Management Group B
                  └── Subscription 3
                         ├── Resource Group 1
                         │      ├── VM1
                         │      └── Storage1
                         └── Resource Group 2
```

---

## 🏢 Management Groups

- Containers that organize **subscriptions** into a governance hierarchy
- Apply conditions (Azure Policy, RBAC) at the management group level — **inherited by all child subscriptions**
- **Root Management Group**: Automatically created for each Azure AD directory; all other management groups and subscriptions fold up to it
- **Max depth**: 6 levels (excluding root and subscription level)
- **Max management groups per directory**: 10,000

### Key Management Group Rules
1. **Policy inheritance**: Deny policies at a parent management group **override** Allow policies at child levels
2. **Subscriptions can be moved** between management groups if the user has the required RBAC permissions
3. Global Admin must **elevate access** (toggle "Access management for Azure resources" to Yes) to manage the root management group

> ⚠️ **Exam Gotcha**: Azure Policy assigned at the root management group with a **deny** effect takes precedence over any allow policy at a child management group or subscription. Deny always overrides.

---

## 💳 Azure Subscriptions

### What Is a Subscription?
- A **billing and access control boundary** for Azure resources
- Every Azure resource belongs to exactly **one** subscription
- One Azure AD tenant can have **multiple** subscriptions, but one subscription trusts only **one** Azure AD tenant

### Subscription Types
| Type | Description |
|------|-------------|
| **Free** | $200 credit for 30 days + 12 months of popular free services |
| **Pay-As-You-Go** | Billed monthly for usage |
| **Enterprise Agreement (EA)** | Volume licensing for organizations |
| **CSP (Cloud Solution Provider)** | Partner-managed subscriptions |

### Service Administrator
- The classic administrator account designated to manage a subscription
- To change the Service Administrator:
  1. Sign in as Account Administrator
  2. Open **Cost Management + Billing** > select subscription
  3. Click **Properties** in the left navigation
  4. Click **Service Admin** to change

---

## 🔄 Moving Resources Between Subscriptions & Resource Groups

### What Can Be Moved?
- **Most resources** can be moved between resource groups or subscriptions
- All dependent resources must typically move together (e.g., VM + its NIC + OS Disk)
- The **region does NOT change** when moving a resource — only the resource group or subscription assignment changes

### Resources That CAN Be Moved
| Resource | Move Across RGs | Move Across Subscriptions |
|----------|-----------------|---------------------------|
| Virtual Machines (with all dependent resources) | ✅ | ✅ |
| Storage Accounts | ✅ | ✅ |
| Virtual Networks | ✅ | ✅ |
| Recovery Services Vaults | ✅ | ✅ |
| Managed Disks | ✅ | ✅ |
| App Service Plans (within same geo region) | ✅ | ✅ (with constraints) |

### Key Move Constraints
- **App Service Plans**: Location does NOT change; plan stays in original region
- **Policy**: When a resource moves to a new resource group, the **new resource group's policies** apply
- **Resource locks** on the resource group block moves — must remove the lock first
- **Recovery Services Vault** with active backups: Must stop backup and delete backup data first to delete the vault, but CAN move the vault

> ⚠️ **Exam Gotcha**: Moving a web app to a different resource group does **NOT** move the App Service plan's region. The plan stays in its original region. However, the policies of the **destination** resource group now apply.

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Max management group depth | **6 levels** (excluding root and subscription) |
| Policy at root management group | **Deny overrides** all child allows |
| Subscriptions can be moved between MGs | Yes, if user has required RBAC |
| Moving resource changes region? | **No** — region stays the same |
| Policy after moving resource | **Destination** resource group's policies apply |
| Change Service Admin | **Subscription > Properties > Service Admin** |
| One subscription can trust how many Azure AD tenants? | Exactly **1** |

---

## 🚨 Common Exam Scenarios (from AZ-104 MCQs)

**Q: You have management groups with Azure Policy applied. Virtual networks are denied at the root management group. Can you create a virtual network in a subscription under a child management group that allows it?**
→ **No**. The deny policy at the root management group is inherited and **deny overrides allow**.

**Q: Subscriptions can be moved between management groups.**
→ **Yes**, provided the user has the required RBAC permissions on both the source and destination management groups.

**Q: You need to move VM1, storage1, VNET1, VM1Managed disk, and RVAULT1 to a new subscription. Which can be moved?**
→ **All of them** (VM1, storage1, VNET1, VM1Managed, and RVAULT1) can be moved to a different subscription.

**Q: RG1 (in West Europe) has WebApp1 with Policy1. You move WebApp1 to RG2 (in North Europe) with Policy2. What happens?**
→ The App Service plan **remains in West Europe** (location doesn't change). **Policy2** now applies to WebApp1 (destination RG's policy).

**Q: You need to delete a resource group, but it contains a VM and a VNet with a resource lock. What should you do first?**
→ **Turn off VM1** (or deallocate) and **remove the resource lock** from VNET1. Resource locks prevent deletion of the resource group.

**Q: You need to designate Admin1 as the Service Administrator for the subscription.**
→ Go to **Subscriptions > select subscription > Properties > Service Admin** and change it there.

**Q: You need to ensure that User1 can assign a policy to the tenant root management group.**
→ Assign the **Owner role** for the subscription to User1, then instruct User1 to **configure access management for Azure resources** (elevate access).

---

## 🏪 Azure Marketplace & Programmatic Deployment

When deploying a Marketplace resource via PowerShell or CLI, you may receive:
> *"Legal terms have not been accepted for this item on this subscription."*

**Resolution**: Run the PowerShell cmdlet to accept the terms programmatically:
```powershell
# Accept Marketplace terms for a specific image offer
Set-AzMarketplaceTerms -Publisher "<publisher>" -Product "<offer>" -Name "<plan>" -Accept
```

> 💡 **Exam Tip (Q12)**: If an admin gets the "Legal terms have not been accepted" error when deploying from a template → Run `Set-AzMarketplaceTerms` cmdlet, OR go to the Azure portal and configure programmatic deployment for the Marketplace item manually first.
