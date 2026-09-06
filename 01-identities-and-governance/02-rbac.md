# Role-Based Access Control (RBAC)

> 🎯 Exam Weight: Part of 15–20% Identity & Governance domain

---

## 🔑 What is RBAC?

- **Authorization system** built on Azure Resource Manager
- Controls **who** (identity) can do **what** (role) on **which resources** (scope)
- Uses **deny assignments** and **role assignments**

> ⚠️ **Key Principle**: RBAC uses **allow model** — access is denied unless explicitly allowed. However, **deny assignments override role assignments**.

---

## 🏗️ RBAC Components

### Role Assignment = Security Principal + Role Definition + Scope

```
[WHO]               [WHAT]              [WHERE]
Security Principal  +  Role Definition  +  Scope
(User/Group/SP/MI)     (set of perms)      (resource boundary)
```

---

## 👤 Security Principals

| Type | Description |
|------|-------------|
| **User** | Individual Azure AD account |
| **Group** | Set of users — assign role to group, all members inherit it |
| **Service Principal** | Identity for an application |
| **Managed Identity** | Auto-managed identity for Azure services (no credential management) |

> 💡 **Best Practice**: Assign roles to **Groups**, not individual users. Easier to manage.

---

## 📋 Built-in Roles

### The 4 Fundamental Roles
| Role | Permissions |
|------|-------------|
| **Owner** | Full access + can grant access to others |
| **Contributor** | Full access to manage resources but **cannot grant access** |
| **Reader** | View-only access |
| **User Access Administrator** | Manage user access to Azure resources (not the resources themselves) |

### Other Important Built-in Roles
| Role | What it Does |
|------|-------------|
| **Virtual Machine Contributor** | Manage VMs (not VNet or Storage) |
| **Network Contributor** | Manage networking (not access) |
| **Storage Account Contributor** | Manage storage accounts |
| **Key Vault Administrator** | Full access to Key Vault |
| **Backup Contributor** | Manage backup except deleting vaults |
| **Monitoring Contributor** | Read monitoring data + edit settings |
| **Security Admin** | View + update security policies |

> ⚠️ **Exam Gotcha**: **Contributor** cannot assign roles. **Owner** can. **User Access Administrator** can manage access but NOT manage resources themselves.

---

## 🌍 Scope Levels (Hierarchy)

```
Management Group
    └── Subscription
            └── Resource Group
                    └── Individual Resource
```

- Roles assigned at a **higher scope** are **inherited** by lower scopes
- Role at **Management Group** → inherited by all subscriptions below it
- Role at **Subscription** → inherited by all resource groups and resources
- Role at **Resource Group** → inherited by all resources in that group

> 💡 **Exam Tip**: Assign at the **highest applicable scope** for simplicity. Use narrower scopes for least-privilege.

---

## 🛠️ Managing Role Assignments

### Azure CLI
```bash
# List role assignments for a user
az role assignment list --assignee john@contoso.com

# Assign a role
az role assignment create \
  --assignee john@contoso.com \
  --role "Contributor" \
  --scope "/subscriptions/{sub-id}/resourceGroups/myRG"

# Remove a role assignment
az role assignment delete \
  --assignee john@contoso.com \
  --role "Contributor" \
  --resource-group myRG
```

### PowerShell
```powershell
# List role assignments
Get-AzRoleAssignment -SignInName john@contoso.com

# Assign a role
New-AzRoleAssignment -SignInName john@contoso.com `
  -RoleDefinitionName "Contributor" `
  -ResourceGroupName "myRG"

# Remove a role assignment
Remove-AzRoleAssignment -SignInName john@contoso.com `
  -RoleDefinitionName "Contributor" `
  -ResourceGroupName "myRG"
```

---

## 🔧 Custom Roles

- When built-in roles don't meet requirements
- Defined with JSON and contain:
  - `Actions` — allowed management operations
  - `NotActions` — excluded operations (from Actions, not a deny)
  - `DataActions` — allowed data operations (e.g., read blob data)
  - `NotDataActions` — excluded data operations
  - `AssignableScopes` — where the role can be assigned

```json
{
  "Name": "VM Operator",
  "Description": "Can start/stop/restart VMs but not create or delete",
  "Actions": [
    "Microsoft.Compute/virtualMachines/start/action",
    "Microsoft.Compute/virtualMachines/deallocate/action",
    "Microsoft.Compute/virtualMachines/restart/action",
    "Microsoft.Compute/virtualMachines/read"
  ],
  "NotActions": [],
  "DataActions": [],
  "NotDataActions": [],
  "AssignableScopes": ["/subscriptions/{subscription-id}"]
}
```

> ⚠️ **Custom roles require Azure AD Premium P1** — False! Custom roles are available in all Azure AD tiers. Premium P1 is needed for dynamic groups, not custom roles.

---

## 🔒 Privileged Identity Management (PIM)

- Requires **Azure AD Premium P2**
- Provides **Just-in-Time (JIT)** privileged access
- Users request elevated access for a **limited time**
- Requires **approval** and **justification**
- Sends **alerts** for privileged role activations

### PIM vs Direct Role Assignment
| Feature | Direct Assignment | PIM |
|---------|------------------|-----|
| Access | Always active | On-demand, time-limited |
| Audit | Basic | Detailed audit trail |
| Approval | No | Yes (optional) |
| MFA on activation | No | Yes (configurable) |
| License | Free | Azure AD Premium P2 |

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Owner can | Manage resources + grant access |
| Contributor can | Manage resources, **cannot** grant access |
| Reader can | View only, no changes |
| User Access Admin can | Grant access, **cannot** manage resources |
| Custom roles require | No special license (available in all tiers) |
| PIM requires | Azure AD Premium P2 |
| Role inheritance | Flows DOWN the scope hierarchy |
| Max role assignments per subscription | 2,000 |
| Max custom roles per directory | 5,000 |

---

## 🚨 Common Exam Scenarios

**Q: A developer needs to deploy resources to a resource group but should NOT be able to assign permissions. What role?**
→ **Contributor** at the resource group scope

**Q: A manager needs to see all resources in a subscription but make no changes. What role?**
→ **Reader** at the subscription scope

**Q: An app running in an Azure VM needs to access Key Vault. No passwords should be stored. What should you use?**
→ **Managed Identity** — assign it a Key Vault role

**Q: A user needs temporary admin access only when needed. What do you implement?**
→ **Azure AD PIM** (Privileged Identity Management)

**Q: You need to give a team access to resources in 5 subscriptions easily. What's the best approach?**
→ Create a **Management Group**, put subscriptions in it, assign role at management group level
