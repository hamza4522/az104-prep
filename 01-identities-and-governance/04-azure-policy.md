# Azure Policy

> 🎯 Exam Weight: Part of 15–20% Identity & Governance domain

---

## 🔑 What is Azure Policy?

- A service that creates, assigns, and manages **policies** that enforce rules and effects over Azure resources
- Ensures resources stay **compliant** with corporate standards and service level agreements
- Works at any scope: Management Group, Subscription, or Resource Group

---

## 📦 Policy Definitions, Assignments & Initiatives

### Policy Definition
A JSON rule that describes what to evaluate and what action to take:
```json
{
  "if": {
    "field": "type",
    "equals": "Microsoft.Sql/servers"
  },
  "then": {
    "effect": "deny"
  }
}
```

### Policy Assignment
- A policy definition **applied** to a specific scope (management group, subscription, or resource group)
- Policies assigned at a parent scope are **inherited** by child scopes
- You can set **exclusions** to exempt specific child resources or resource groups

### Policy Initiative (Initiative Definition)
- A **collection of policy definitions** grouped together for a single assignment
- Example: "Enable Monitoring in Azure Security Center" initiative contains multiple individual policies
- Simplifies policy management when you need to apply multiple related policies

---

## ⚡ Policy Effects

| Effect | Behavior |
|--------|----------|
| **Deny** | Blocks the resource creation or modification |
| **Audit** | Logs a warning in the Activity Log but allows the action |
| **AuditIfNotExists** | Audits if a related resource does NOT exist |
| **DeployIfNotExists** | Deploys a related resource if it doesn't exist (requires managed identity) |
| **Append** | Adds fields to a resource during creation or update (e.g., append a tag) |
| **Modify** | Adds, updates, or removes tags on a resource during creation or update |
| **Disabled** | Policy is not enforced |

> ⚠️ **Exam Gotcha**: Azure Policy with a **Deny** effect at a parent scope **cannot be overridden** by an Allow at a child scope. Deny always wins!

---

## 🏷️ Tag Policies (Frequently Tested!)

### Tags Do NOT Inherit
- Tags applied to a **resource group** or **subscription** are **NOT automatically inherited** by the resources within them
- To enforce tag inheritance, you must use Azure Policy with the **"Inherit a tag from the resource group"** built-in policy

### Common Tag Policy Scenarios
| Policy | Effect | What It Does |
|--------|--------|-------------|
| **Require a tag on resources** | Deny | Blocks creation of any resource without the specified tag |
| **Require a tag on resource groups** | Deny | Blocks creation of resource groups without the tag |
| **Inherit a tag from the resource group** | Modify | Automatically copies a tag from the RG to new resources created within it |
| **Append a tag and its value** | Append | Adds a specific tag to all new resources at the assigned scope |

> 💡 **Key Exam Fact**: When you assign a tag policy with the **Append** or **Modify** effect to a resource group, new resources deployed to that RG will automatically get the tag. However, **existing resources** in the RG are NOT retroactively tagged — only new resources get the tag unless you run a remediation task.

---

## 🔄 Policy Compliance & Remediation

- **Compliance dashboard** shows which resources comply with assigned policies
- **Non-compliant resources** can be remediated:
  - For `DeployIfNotExists` and `Modify` policies: Create a **remediation task** that applies the policy to existing non-compliant resources
  - Remediation tasks require a **managed identity** to modify resources

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Tags inherit from resource group? | **No** — tags do NOT inherit by default |
| Force tag inheritance | Use Azure Policy with **Modify** or **Append** effect |
| Deny at parent scope | **Cannot be overridden** by child scope policies |
| Policy exclusions | Can exclude specific child scopes from policy assignment |
| Marketplace legal terms error | Run `Set-AzMarketplaceTerms` cmdlet to accept terms programmatically |
| Policy initiative | Group of policies assigned together as a single unit |

---

## 🚨 Common Exam Scenarios (from AZ-104 MCQs)

**Q: You assign a policy to RG6 that appends a tag "Label:Value1" to new resources. You also manually tag RG6 with "RGroup:RG6". When you deploy VNET2 to RG6, what tags does VNET2 have?**
→ VNET2 gets **only "Label:Value1"** (from the append policy). It does **NOT** get "RGroup:RG6" because tags on resource groups are **not inherited** by resources.

**Q: An Azure Policy at the subscription scope denies creation of Azure SQL Servers, but an exclusion is set for ContosoRG1. Where can you create SQL servers?**
→ You can create Azure SQL Servers **only in ContosoRG1** (the excluded resource group). The deny policy blocks creation everywhere else in the subscription.

**Q: Admin1 deploys a Marketplace resource but gets "Legal terms have not been accepted" error. How do you fix it?**
→ Run the **`Set-AzMarketplaceTerms`** cmdlet from Azure PowerShell to accept the Marketplace legal terms programmatically.

**Q: Azure Policy at the root management group denies virtual networks. Can you create a VNet in a child subscription that has an "allow" policy?**
→ **No**. Deny at the root management group is inherited and **deny overrides allow**.
