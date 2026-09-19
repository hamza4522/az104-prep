# Resource Locks & Tags

> 🎯 Exam Weight: Part of 15–20% Identity & Governance domain

---

## 🔒 Resource Locks

### What Are Resource Locks?
- Built-in ARM feature to prevent accidental **deletion or modification** of critical Azure resources
- Applied at: **Subscription**, **Resource Group**, or **Individual Resource** level
- **Inherited down the hierarchy**: A lock on a subscription or resource group applies to all child resources within it
- **Overrides RBAC**: Even a **Subscription Owner** cannot delete or modify a locked resource without first explicitly removing the lock

---

### Lock Types & Operational Impact

| Lock Type | Can Read? | Can Modify / Update? | Can Start / Stop VM? | Can Delete? | Operational Restrictions |
|-----------|-----------|----------------------|----------------------|-------------|--------------------------|
| **CanNotDelete** | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No | Cannot delete resource or child resources |
| **ReadOnly** | ✅ Yes | ❌ No | ❌ **No** | ❌ No | Cannot modify configs, cannot start/stop VMs, cannot list storage keys |

> ⚠️ **CRITICAL Exam Gotchas for ReadOnly Locks**:
> 1. **Virtual Machines**: A `ReadOnly` lock **prevents starting, stopping, or restarting** the VM because power actions issue `POST` requests that alter the resource's runtime state.
> 2. **Storage Accounts**: A `ReadOnly` lock **prevents listing account access keys** (`POST /listKeys/action`), which blocks data plane tools (Storage Explorer, scripts) from connecting.
> 3. **Virtual Networks**: A `ReadOnly` lock prevents adding a new subnet, modifying address spaces, or attaching new NICs.
> 4. **Precedence**: If both `ReadOnly` and `CanNotDelete` locks are applied (e.g., via inheritance), the **most restrictive lock (`ReadOnly`) wins**.

---

### Lock Inheritance Flow

```
Subscription Lock (e.g. ReadOnly)
    ↓ (inherited)
Resource Group Lock (e.g. CanNotDelete)
    ↓ (inherited)
Individual Resource (Effective lock = ReadOnly)
```

### Managing Locks via CLI & PowerShell

```bash
# Azure CLI: Create a CanNotDelete lock on a Resource Group
az lock create \
  --name "PreventDeleteRG" \
  --lock-type CanNotDelete \
  --resource-group "RG1"

# Azure CLI: Delete a lock
az lock delete --name "PreventDeleteRG" --resource-group "RG1"
```

```powershell
# PowerShell: Create a ReadOnly lock on a specific VM
New-AzResourceLock -LockName "VMReadOnly" `
  -LockLevel ReadOnly `
  -ResourceName "VM1" `
  -ResourceType "Microsoft.Compute/virtualMachines" `
  -ResourceGroupName "RG1"

# PowerShell: Remove a resource lock
Remove-AzResourceLock -LockName "VMReadOnly" -ResourceGroupName "RG1"
```

### Who Can Manage Locks?
- Requires permissions: `Microsoft.Authorization/*` or `Microsoft.Authorization/locks/*`
- Built-in roles with this permission: **Owner** and **User Access Administrator**
- **Contributor** CANNOT create or delete locks!

---

## 🏷️ Resource Tags

### What Are Tags?
- **Key-Value pairs** (metadata) assigned to resources, resource groups, and subscriptions
- Used for:
  - **Cost Allocation & Department Tracking**: Filter billing data in Azure Cost Management
  - **Operations & Automation**: Target specific environments (e.g., `Env: Prod`) in automation scripts
  - **Resource Organization & Inventory**: Grouping resources without moving them

### Core Tagging Rules & Limitations
| Property | Rule / Limit |
|----------|--------------|
| Max tags per resource | **50** tags |
| Max tag name length | **512** characters (storage accounts: 128 characters) |
| Max tag value length | **256** characters |
| Tag name case-sensitivity | **Case-insensitive** (`Department` = `department`) |
| Tag value case-sensitivity | **Case-sensitive** (`Finance` ≠ `finance`) |
| Tag inheritance | Tags do **NOT automatically inherit** from resource group to child resources |
| Resources supporting tags | Almost all ARM resources (classic resources do not support tags) |

> ⚠️ **Tag Inheritance Rule**: Applying a tag to a Resource Group **does not** tag the resources inside it. To enforce tag inheritance down to child resources, you must deploy an **Azure Policy** with the `Modify` or `Append` effect!

```bash
# Azure CLI: Add tags to a resource
az resource tag --tags Department=Finance Environment=Prod --ids <resource-id>

# PowerShell: Update resource tags
$tags = (Get-AzResource -ResourceGroupName "RG1" -Name "VM1").Tags
$tags += @{ "CostCenter" = "CC104" }
Set-AzResource -ResourceId <resource-id> -Tag $tags -Force
```

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Associating VMs in single RG with departments | Assign **Tags** to the VMs (e.g., `Department: HR`) |
| Stopping a VM with ReadOnly lock | Blocked / Fails with authorization error |
| Listing storage keys with ReadOnly lock | Blocked / Fails |
| Role required to delete a lock | Owner or User Access Administrator (Contributor cannot delete locks) |
| Tag inheritance behavior | None (requires Azure Policy to propagate) |
| Max tags per resource | 50 tags |
| Lock precedence | Most restrictive lock wins (ReadOnly > CanNotDelete) |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: Your company has several departments. Each department has virtual machines located in a single resource group named RG1. You want to associate each VM with its respective department for cost tracking. What should you do?**
→ Assign **Tags** to each virtual machine representing their department name (e.g., `Department: Marketing`).

**Q: An administrator needs to stop and deallocate VM1 to change its size, but the stop action fails with an error. VM1 has no direct locks, but its resource group has a ReadOnly lock. What is the solution?**
→ The `ReadOnly` lock on the resource group is inherited by VM1 and prevents power state modifications. The administrator must **remove the ReadOnly lock** (or change it to `CanNotDelete`), stop and resize the VM, and then re-apply the lock.

**Q: You need to prevent all developers and administrators from accidentally deleting a production Azure SQL Database, while still allowing developers to modify database schemas and data.**
→ Apply a **CanNotDelete** lock to the database or its resource group.

**Q: A team adds a tag `CostCenter: 104` to a resource group named RG1. When viewing the cost analysis of the virtual machines inside RG1, the tag is missing. Why?**
→ Tags on a resource group **do not inherit** to child resources automatically. You must either manually tag the VMs or assign an **Azure Policy** to inherit the tag.
