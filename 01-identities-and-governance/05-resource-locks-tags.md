# Resource Locks & Tags

> 🎯 Exam Weight: Part of 15–20% Identity & Governance domain

---

## 🔒 Resource Locks

### What Are Resource Locks?
- Prevent accidental **deletion or modification** of critical Azure resources
- Applied at: **Resource**, **Resource Group**, or **Subscription** level
- Inherited by child resources
- Override RBAC — even **Owners** cannot delete a locked resource without removing the lock first

### Lock Types

| Lock Type | Description | Can Read? | Can Modify? | Can Delete? |
|-----------|-------------|-----------|-------------|-------------|
| **CanNotDelete** | Can manage but cannot delete | ✅ Yes | ✅ Yes | ❌ No |
| **ReadOnly** | Can read but cannot modify or delete | ✅ Yes | ❌ No | ❌ No |

> ⚠️ **ReadOnly lock** acts like assigning **Reader** role to everyone — even Owners can't make changes while lock is in place.

> ⚠️ **Exam Gotcha**: **ReadOnly** lock on a Storage Account prevents **listing storage keys** (this is a POST operation, treated as a write). Users won't be able to access storage data.

### Lock Inheritance
```
Subscription Lock
    ↓ (inherited)
    Resource Group Lock
        ↓ (inherited)
        Resource Lock (most restrictive wins)
```

### Creating Locks

```bash
# Azure CLI
# Create a CanNotDelete lock on a resource group
az lock create \
  --name "DoNotDelete" \
  --lock-type CanNotDelete \
  --resource-group "myRG"

# Create a ReadOnly lock on a specific resource
az lock create \
  --name "ReadOnlyLock" \
  --lock-type ReadOnly \
  --resource-group "myRG" \
  --resource-name "myVM" \
  --resource-type "Microsoft.Compute/virtualMachines"
```

```powershell
# PowerShell
New-AzResourceLock -LockName "DoNotDelete" `
  -LockLevel CanNotDelete `
  -ResourceGroupName "myRG"

# Remove a lock
Remove-AzResourceLock -LockName "DoNotDelete" `
  -ResourceGroupName "myRG"
```

### Who Can Manage Locks?
- **Owner** and **User Access Administrator** roles can create/delete locks
- Specific permission needed: `Microsoft.Authorization/locks/*`
- Locks are separate from RBAC permissions — you need explicit lock permissions

---

## 🏷️ Resource Tags

### What Are Tags?
- **Name-value pairs** (metadata) attached to Azure resources
- Used for: organization, cost management, automation, searching/filtering
- Tags do NOT affect resource functionality

### Tag Rules
| Rule | Detail |
|------|--------|
| Max tags per resource | **50** |
| Max tag name length | **512 characters** (128 for storage accounts) |
| Max tag value length | **256 characters** |
| Case sensitivity | Tag names are **case-insensitive**, values are **case-sensitive** |
| Resource groups/subscriptions | Can be tagged (up to 50 tags) |
| Tag inheritance | Tags do **NOT** automatically inherit to child resources |

> ⚠️ **Tag Inheritance**: Tags on a resource group do **NOT** inherit to resources inside it by default. You must use **Azure Policy** to enforce tag inheritance.

### Common Tag Strategies

| Tag Name | Example Value | Purpose |
|----------|--------------|---------|
| Environment | Production, Dev, Test | Environment identification |
| Department | IT, Finance, HR | Cost allocation |
| CostCenter | CC-1234 | Billing/chargeback |
| Owner | john@contoso.com | Accountability |
| Project | ProjectX | Project tracking |
| ApplicationName | WebApp-Portal | Application tracking |

### Managing Tags

```bash
# Azure CLI
# Add tags to a resource group
az group update --name "myRG" --tags "Environment=Production" "Department=IT"

# Add tags to a resource
az resource tag \
  --tags "Environment=Production" "Owner=john@contoso.com" \
  --resource-group "myRG" \
  --resource-type "Microsoft.Compute/virtualMachines" \
  --name "myVM"

# List all resources with a specific tag
az resource list --tag "Environment=Production" --output table

# List tag values for a tag name
az tag list --output table
```

```powershell
# PowerShell
# Add tags to resource group
$tags = @{"Environment"="Production"; "Department"="IT"}
Set-AzResourceGroup -Name "myRG" -Tag $tags

# Add tags to a resource (replaces all tags)
$resource = Get-AzResource -ResourceGroupName "myRG" -Name "myVM"
Set-AzResource -ResourceId $resource.Id -Tag $tags -Force

# Update tags (add without removing existing)
$resource = Get-AzResource -ResourceGroupName "myRG" -Name "myVM"
$resource.Tags.Add("NewTag", "NewValue")
Set-AzResource -ResourceId $resource.Id -Tag $resource.Tags -Force
```

---

## 🔄 Tags + Policy Integration

### Enforce Tags with Azure Policy
- **Require a tag**: Deny resources without specific tag
- **Inherit tag from resource group**: Automatically copy RG tags to resources
- **Require tag value pattern**: Validate tag value format

### Example: Inherit tags from resource group
```json
{
  "effect": "Modify",
  "details": {
    "roleDefinitionIds": ["...contributor-role-id..."],
    "operations": [{
      "operation": "addOrReplace",
      "field": "tags['Environment']",
      "value": "[resourceGroup().tags['Environment']]"
    }]
  }
}
```

---

## 📊 Cost Management with Tags

- Tags enable **cost allocation** by department/project/environment
- View costs filtered by tags in **Azure Cost Management**
- Create **budgets** per tag combination

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Lock types | **CanNotDelete** and **ReadOnly** |
| ReadOnly lock prevents | Modify AND delete |
| CanNotDelete lock prevents | Delete only |
| Locks override | Even Owner role |
| Who can create locks | Needs `Microsoft.Authorization/locks/*` permission |
| Max tags per resource | **50** |
| Tag name max length | **512 chars** (128 for storage) |
| Tag inheritance | Does **NOT** inherit automatically |
| To enforce tag inheritance | Use **Azure Policy** with Modify effect |
| Tags affect resource behavior | **No** |

---

## 🚨 Common Exam Scenarios

**Q: A storage account has a ReadOnly lock. An admin with Owner permissions tries to add a new blob container. What happens?**
→ **Blocked** — ReadOnly lock prevents any modification, regardless of RBAC role

**Q: A developer accidentally deleted a production resource group. How do you prevent this in the future?**
→ Apply a **CanNotDelete** lock to the resource group

**Q: You want all resources in a resource group to automatically get the same "Environment" tag as the resource group. What do you configure?**
→ **Azure Policy** with effect **Modify** or **Append** to inherit tags from resource group

**Q: A manager wants to see the monthly cost for the "Finance" department only. What should have been set up?**
→ **Tags** on all finance resources with "Department=Finance", then filter in Cost Management

**Q: Can an Owner delete a resource that has a CanNotDelete lock on its resource group?**
→ **No** — they must first **remove the lock**, then delete. Both actions require lock management permission.
