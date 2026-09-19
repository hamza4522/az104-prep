# Resource Locks & Tags

> 🎯 Exam Weight: Part of 15–20% Identity & Governance domain

---

## 🔒 Resource Locks

### What Are Resource Locks?
- Prevent accidental **deletion** or **modification** of critical Azure resources
- Can be applied at: **Subscription**, **Resource Group**, or individual **Resource** level
- Locks are **inherited** by child resources

### Lock Types
| Lock Type | Prevents | Read | Modify | Delete |
|-----------|----------|------|--------|--------|
| **ReadOnly** | All changes and deletions | ✅ | ❌ | ❌ |
| **CanNotDelete (Delete)** | Deletions only | ✅ | ✅ | ❌ |

### Key Lock Behaviors
1. **Inheritance**: A lock on a resource group applies to **all resources** within it
2. **Delete lock on resource group**: Blocks deletion of the resource group AND all resources inside it
3. **Must remove lock first**: You cannot delete a resource group that contains locked resources — you must remove the lock first
4. **Lock scope**: Locks apply only to **management plane operations** (operations sent to `https://management.azure.com`), NOT to data plane operations

> ⚠️ **Exam Gotcha**: A **ReadOnly** lock on a storage account prevents listing storage keys (management operation), but does NOT prevent reading/writing blob data if you already have a key or SAS token (data plane).

---

## 🏷️ Resource Tags

### What Are Tags?
- **Name-value pairs** (metadata) applied to Azure resources for organization, cost tracking, and governance
- Help organize resources when you have many resources across multiple resource groups

### Tag Rules
| Rule | Value |
|------|-------|
| Max tags per resource/RG/subscription | **50** tag name-value pairs |
| Tag name max length | **512 characters** (128 for storage accounts) |
| Tag value max length | **256 characters** |
| Tag inheritance | Tags do **NOT** inherit from resource groups or subscriptions to child resources |

### Where Can Tags Be Applied?
Tags can be applied to:
- ✅ **Subscriptions**
- ✅ **Resource Groups**
- ✅ **Individual Resources** (VMs, Storage, VNets, etc.)
- ❌ Management Groups (cannot be tagged)

> ⚠️ **CRITICAL Exam Fact**: Tags applied to a resource group are **NOT inherited** by the resources inside it. Each resource must be tagged individually or via Azure Policy (Append/Modify effect).

### Using Tags for Cost Tracking
1. Assign a tag to each resource (e.g., `Department: Finance`, `Department: IT`)
2. Open **Cost Management + Billing > Cost analysis**
3. Filter the view by tag to see costs broken down by department

```bash
# Azure CLI: Apply a tag to a resource
az resource tag --tags Department=Finance --ids /subscriptions/{sub-id}/resourceGroups/RG1/providers/Microsoft.Compute/virtualMachines/VM1

# Azure CLI: Apply a tag to a resource group
az group update --name RG1 --set tags.Environment=Production

# PowerShell: Apply tags
Set-AzResource -ResourceGroupName "RG1" -Name "VM1" -ResourceType "Microsoft.Compute/virtualMachines" -Tag @{Department="Finance"; Project="Alpha"}
```

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Lock types | **ReadOnly** (no changes) and **CanNotDelete** (no deletions) |
| Lock inheritance | Locks on RG apply to all child resources |
| Deleting locked resource group | Must **remove lock first** |
| Tags inherit from parent? | **No** — tags do NOT inherit |
| Max tags per resource | **50** name-value pairs |
| Where can locks/tags be applied? | Subscriptions, Resource Groups, and Resources |
| Track costs by department using tags | Tag resources → Cost Analysis → Filter by tag |

---

## 🚨 Common Exam Scenarios (from AZ-104 MCQs)

**Q: You want to associate each VM with its respective department. All VMs are in the same resource group. What should you do?**
→ **Assign tags** to the virtual machines (e.g., `Department: Sales`, `Department: IT`). Tags are the correct way to categorize resources without moving them.

**Q: You need to send a cost report to the finance department detailing costs by department. Resources span 10 resource groups. What should you do?**
→ 1) **Assign a department tag** to each resource. 2) From **Cost Analysis**, **filter the view by tag** to group costs by department. 3) **Download the usage report**.

**Q: You need to track resource usage (tags) and prevent deletion (locks). You have a subscription (Sub1), resource group (RG1), and VM (VM1). Where can you apply locks and tags?**
→ Locks and tags can be applied to **Sub1, RG1, and VM1** (all three levels).

**Q: You need to delete a resource group TestRG that contains VM1 (running) and VNET1 (with a CanNotDelete lock). What should you do first?**
→ **Turn off VM1** (or deallocate) and **remove the resource lock** from VNET1. The lock prevents the resource group from being deleted.

**Q: Tags on resource group RG6 include "RGroup:RG6". You deploy VNET2 to RG6. Does VNET2 inherit the "RGroup:RG6" tag?**
→ **No**. Tags on resource groups are NOT inherited by resources within them.
