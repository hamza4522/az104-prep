# Role-Based Access Control (RBAC)

> 🎯 Exam Weight: Part of 15–20% Identity & Governance domain

---

## 🔑 What is RBAC?

- **Authorization system** built on Azure Resource Manager (ARM)
- Controls **who** (identity) can do **what** (role) on **which resources** (scope)
- Uses **role assignments** and **deny assignments** (Azure Blueprints / managed apps)

> ⚠️ **Key Principle**: RBAC uses an **allow model** — access is denied unless explicitly allowed.
>
> 💡 **NotActions is NOT Deny**: `NotActions` simply subtracts permissions from `Actions` within the same role definition. If another role assignment grants the permission excluded in `NotActions`, the user **will still have access**! Only explicit Azure **Deny assignments** override role assignments.

---

## 🏗️ RBAC Components

### Role Assignment = Security Principal + Role Definition + Scope

```
[WHO]               [WHAT]              [WHERE]
Security Principal  +  Role Definition  +  Scope
(User/Group/SP/MI)     (set of perms)      (resource boundary)
```

---

## 👤 Security Principals & Directory vs Azure Roles

| Directory Role (Entra ID) | Scope | What it Manages |
|---------------------------|-------|-----------------|
| **Global Administrator** | Tenant-wide | All directory settings, users, licenses |
| **User Administrator** | Tenant-wide | Users, groups, SSPR (cannot reset Global Admins) |
| **Billing Administrator** | Tenant-wide | Purchases, subscriptions, billing tickets |

| Azure Resource Role (RBAC) | Scope | What it Manages |
|----------------------------|-------|-----------------|
| **Owner** | ARM Scope | Full access to resources + can grant access to others |
| **Contributor** | ARM Scope | Full access to resources, **cannot** grant access |
| **Reader** | ARM Scope | View-only access |
| **User Access Administrator** | ARM Scope | Manage user access to resources (cannot modify resources) |

> ⚠️ **Exam Gotcha**:
> - Directory roles manage **Azure AD objects** (users, groups, domains).
> - Azure RBAC roles manage **Azure resources** (VMs, VNets, Storage).
> - Global Admin does not have access to Azure resources until **Access management for Azure resources** is elevated in Entra ID properties.

---

## 📋 Specialized Built-in Roles Tested on Exam

| Role | Permissions & Exam Details |
|------|----------------------------|
| **Virtual Machine Contributor** | Can manage VMs (start, restart, resize), but **cannot** create VNets or manage storage accounts directly |
| **Network Contributor** | Can manage VNets, subnets, NSGs, and IP configurations |
| **Storage Account Contributor** | Manages storage accounts, keys, and networking, but does not provide blob data plane access by default |
| **Storage Blob Data Contributor** | Full read/write access to **blob data containers** (data plane) |
| **Security Admin** | Views and edits security policies in Defender for Cloud |
| **Support Request Contributor** | Creates and manages Azure support tickets |

> 💡 **Deploying VMs with Custom/Limited Roles**: To deploy a VM, a user must have write permissions on the VM (`Microsoft.Compute/virtualMachines/*`) **AND** `Microsoft.Network/virtualNetworks/subnets/join/action` on the target subnet!

---

## 🌍 Scope Levels & Inheritance

```
Management Group (Root: Tenant Root Group)
    └── Management Group (Child)
            └── Subscription
                    └── Resource Group
                            └── Individual Resource
```

- Roles assigned at a **higher scope** are **automatically inherited** by all child scopes
- Inherited permissions **cannot** be removed at a lower scope; they can only be overridden by a Deny assignment
- **Resource Moves**: When moving a resource between subscriptions, previous **role assignments do not move** with the resource. You must recreate them in the destination scope.

---

## 🛠️ Managing Role Assignments

### Azure CLI
```bash
# List role assignments for a user
az role assignment list --assignee user1@contoso.com --all

# Assign Contributor role at Resource Group scope
az role assignment create \
  --assignee user1@contoso.com \
  --role "Contributor" \
  --resource-group RG1

# Assign role at Subscription scope
az role assignment create \
  --assignee "IT-Engineers" \
  --role "Reader" \
  --scope "/subscriptions/00000000-0000-0000-0000-000000000000"
```

### PowerShell
```powershell
# List role assignments
Get-AzRoleAssignment -SignInName user1@contoso.com

# Assign role
New-AzRoleAssignment -SignInName user1@contoso.com `
  -RoleDefinitionName "Contributor" `
  -ResourceGroupName "RG1"

# Remove role assignment
Remove-AzRoleAssignment -SignInName user1@contoso.com `
  -RoleDefinitionName "Contributor" `
  -ResourceGroupName "RG1"
```

---

## 🔧 Custom Roles

- Created when built-in roles do not fit least-privilege needs
- Can be defined using JSON or PowerShell / Azure CLI
- Available in **all Azure AD tiers** (no Premium license required)

### Custom Role JSON Structure
```json
{
  "Name": "Custom VM Operator",
  "IsCustom": true,
  "Description": "Can monitor, restart, and deallocate VMs without modifying network or storage",
  "Actions": [
    "Microsoft.Compute/*/read",
    "Microsoft.Compute/virtualMachines/start/action",
    "Microsoft.Compute/virtualMachines/restart/action",
    "Microsoft.Compute/virtualMachines/deallocate/action"
  ],
  "NotActions": [
    "Microsoft.Compute/virtualMachines/delete"
  ],
  "DataActions": [],
  "NotDataActions": [],
  "AssignableScopes": [
    "/subscriptions/11111111-1111-1111-1111-111111111111",
    "/providers/Microsoft.Management/managementGroups/EngineeringMG"
  ]
}
```

> ⚠️ **Custom Role Rules**:
> 1. `AssignableScopes` can contain Management Groups, Subscriptions, or Resource Groups.
> 2. You **cannot** set wildcards `*` in `AssignableScopes`.
> 3. Limit: Up to **5,000 custom roles** per directory.

---

## 🔒 Privileged Identity Management (PIM)

- Requires **Azure AD Premium P2**
- Provides **Just-in-Time (JIT)** privileged access
- Users are assigned as **Eligible** (not permanently active)
- Requires multi-factor authentication (MFA), justification, and optional approver approval to activate
- Automatically logs and audits role activation history

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Owner vs Contributor | Contributor has full resource rights but **cannot grant access** or delegate roles |
| User Access Administrator | Manages role assignments; cannot manage resource configs directly |
| Maximum role assignments per subscription | **2,000** |
| Maximum custom roles per tenant | **5,000** |
| Custom role licensing | Free (available in all Azure tiers) |
| Moving resources across subscriptions | Existing role assignments are **not** preserved or moved |
| NotActions behavior | Subtraction from Actions; does NOT override a grant from another role assignment |
| Subnet join requirement | VM deployment requires `Microsoft.Network/virtualNetworks/subnets/join/action` |
| Marketplace programmatic deployment | Requires accepting legal terms (`Set-AzMarketplaceTerms`) before deployment |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You need to allow a user to deploy Azure Virtual Machines into an existing subnet in VNet1, following least privilege.**
→ Assign **Virtual Machine Contributor** on the target resource group, AND assign a custom role with `Microsoft.Network/virtualNetworks/subnets/join/action` (or **Network Contributor**) on `VNet1` / the subnet.

**Q: A custom role has `Microsoft.Compute/virtualMachines/*` in Actions and `Microsoft.Compute/virtualMachines/delete` in NotActions. A user is assigned this custom role AND the built-in Contributor role on the same resource group. Can the user delete virtual machines?**
→ **Yes**. `NotActions` is not an explicit deny. The user's Contributor role explicitly grants delete permissions.

**Q: An administrator attempts to deploy a third-party Marketplace template in a new subscription and receives a legal terms failure.**
→ The user must accept the programmatic deployment terms for the Marketplace image using the Azure portal or PowerShell `Set-AzMarketplaceTerms`.

**Q: You need to create a custom RBAC role that can be assigned across three distinct subscriptions within the "Sales" management group.**
→ Set the `AssignableScopes` in the custom role definition to the management group URI: `"/providers/Microsoft.Management/managementGroups/Sales"`.

**Q: Which role is required to manage and assign Azure Resource Locks without granting full resource ownership?**
→ **User Access Administrator** (or any role with `Microsoft.Authorization/*` permissions at that scope).
