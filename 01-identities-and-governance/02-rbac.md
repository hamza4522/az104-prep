# RBAC (Role-Based Access Control)

> 🎯 Exam Weight: Part of 15–20% Identity & Governance domain

---

## 🔑 What is Azure RBAC?

- Azure's **authorization system** built on Azure Resource Manager
- Controls **who** can do **what** on **which** Azure resources
- Grants access by assigning **roles** to **security principals** at a particular **scope**

---

## 🧩 RBAC Components

### Security Principals (Who)
| Principal | Description |
|-----------|-------------|
| **User** | An individual Azure AD account |
| **Group** | A set of users; role applies to all members |
| **Service Principal** | An identity for applications/services |
| **Managed Identity** | System-assigned or user-assigned identity for Azure services |

### Role Definitions (What)
A collection of permissions (Actions, NotActions, DataActions, NotDataActions).

### Scope (Where)
```
Management Group
    └── Subscription
           └── Resource Group
                  └── Resource
```
> 💡 **Inheritance**: Roles assigned at a parent scope are inherited by child scopes. A role assigned at a Subscription applies to ALL resource groups and resources within it.

---

## 🛡️ Key Built-In Roles (Exam Favorites!)

| Role | Permissions | Key Limitation |
|------|-------------|----------------|
| **Owner** | Full access to all resources + can assign roles to others | - |
| **Contributor** | Full access to all resources | **Cannot assign roles** (no `Microsoft.Authorization/*` permissions) |
| **Reader** | View all resources | Cannot modify anything |
| **User Access Administrator** | Manage user access to Azure resources | Can assign roles but cannot manage resources themselves |

### Common Service-Specific Roles

| Role | What It Can Do |
|------|----------------|
| **Virtual Machine Contributor** | Manage VMs but not access to them, and not the VNet or storage they connect to |
| **Network Contributor** | Manage networks (VNets, subnets, NSGs, load balancers) but not access them |
| **Storage Blob Data Reader** | Read blob data (data plane access) |
| **Storage Blob Data Contributor** | Read, write, delete blob data |
| **Logic App Contributor** | Manage logic apps (create, edit, update) but not access to them |
| **Logic App Operator** | Read, enable, disable logic apps but **cannot create or edit** |
| **DevTest Labs User** | Connect, start, restart, shutdown VMs in DevTest Labs only |
| **Security Admin** | View/edit security policies, view security states, alerts and recommendations in Security Center |
| **Billing Reader** | Read-only access to billing information |

> ⚠️ **Exam Gotcha**: `Contributor` role can manage all resources (create, modify, delete) but **cannot** assign RBAC roles to other users. Only `Owner` or `User Access Administrator` can delegate access.

---

## 🔄 Role Assignment Process

1. **Identify the security principal** (user, group, service principal, managed identity)
2. **Select the role definition** (built-in or custom)
3. **Determine the scope** (management group, subscription, resource group, or resource)
4. **Create the role assignment** via Portal, CLI, PowerShell, or ARM template

```bash
# Azure CLI: Assign Contributor role to a user at resource group scope
az role assignment create \
  --assignee "user@contoso.com" \
  --role "Contributor" \
  --resource-group "RG1"

# PowerShell: Assign Reader role at subscription scope
New-AzRoleAssignment `
  -SignInName "user@contoso.com" `
  -RoleDefinitionName "Reader" `
  -Scope "/subscriptions/{sub-id}"
```

---

## 🛠️ Custom RBAC Roles

When built-in roles don't meet your needs, you can create **custom roles**:

```json
{
  "Name": "Custom Resource Operator",
  "Description": "Can view, create, modify, and delete resources but cannot manage access",
  "Actions": [
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Resources/subscriptions/resourceGroups/resources/*"
  ],
  "NotActions": [
    "Microsoft.Authorization/*/Write",
    "Microsoft.Authorization/*/Delete"
  ],
  "AssignableScopes": [
    "/subscriptions/c276fc76-9cd4-44c9-99a7-4fd71546436e"
  ]
}
```

### AssignableScopes
- Defines **where** the custom role can be assigned
- Can be set to a subscription (`/subscriptions/{id}`), resource group, or management group
- Does **NOT** grant access — just limits where the role appears for assignment

> ⚠️ **Exam Gotcha**: `AssignableScopes` restricts where the role CAN be assigned, not where it HAS effect. The scope specified in the role assignment determines the effective scope.

---

## 🔐 Owner Role & Elevating Global Admin Access

- A **Global Administrator** in Azure AD does **NOT** automatically have access to Azure subscription resources
- To gain access, the Global Admin must:
  1. Navigate to **Microsoft Entra ID > Properties**
  2. Set **Access management for Azure resources** to **Yes**
  3. This grants them the **User Access Administrator** role at the root management group (`/`) scope
- Only the **Owner** of a subscription can assign the Owner role to other users

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Who can assign roles to other users | **Owner** or **User Access Administrator** |
| Contributor vs Owner difference | Contributor **cannot** assign roles |
| RBAC scope inheritance | Parent scope roles inherited by all children |
| Custom role AssignableScopes | Limits where the role **appears** for assignment |
| Role needed to delegate access | **User Access Administrator** (for access delegation only) |
| Role for managing VMs (least privilege) | **Virtual Machine Contributor** |
| Role for managing networks (least privilege) | **Network Contributor** |
| Service Admin change location | **Subscription > Properties > Service Admin** |
| Enable Traffic Analytics role requirement | Owner, Contributor, Reader, or Network Contributor at subscription scope |

---

## 🚨 Common Exam Scenarios (from AZ-104 MCQs)

**Q: You need to ensure that User1 can assign the Reader role for VNet1 to other users. What role should you assign to User1?**
→ Assign the **User Access Administrator** role for VNet1 to User1. The Contributor role does NOT include role assignment permissions.

**Q: You need to provide the Developers group with the ability to create Azure logic apps in the Dev resource group. Solution: Assign the DevTest Labs User role. Does this meet the goal?**
→ **No**. DevTest Labs User only manages VMs in DevTest Labs. You need the **Logic App Contributor** role or the **Contributor** role on the resource group.

**Q: An administrator named Admin1 needs to manage internal and public load balancers. Which role should you assign following least privilege?**
→ Assign the **Network Contributor** role. It manages networks including load balancers, but does not grant access to them.

**Q: You need to create a custom RBAC role that can only be assigned to resource groups in a specific subscription, allows viewing/creating/modifying/deleting resources, but prevents managing access permissions.**
→ Set `AssignableScopes` to the subscription ID. Set `Actions` to `"*"` and `NotActions` to `"Microsoft.Authorization/*/Write"` and `"Microsoft.Authorization/*/Delete"`.

**Q: User1 needs to deploy VMs and manage virtual networks. Which RBAC role uses least privilege?**
→ **Virtual Machine Contributor** — it manages VMs but not access, VNet, or storage.

**Q: Only the subscription Owner (Admin3) can assign ownership. A Global Admin (Admin1) who elevated access cannot assign Owner to other users on the subscription unless Admin3 does it.**
→ Only the **Owner** of the subscription can assign the Owner role to others.
