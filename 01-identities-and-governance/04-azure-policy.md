# Azure Policy

> 🎯 Exam Weight: Part of 15–20% Identity & Governance domain

---

## 🔑 What is Azure Policy?

- Service for **enforcing organizational standards** and assessing compliance
- Evaluates resources for **non-compliance** with policy definitions
- Can **prevent** non-compliant resources from being created (Deny effect)
- Can **automatically remediate** non-compliant existing resources

> ⚠️ **RBAC vs Azure Policy**:
> - **RBAC** = controls *who* can perform *what actions*
> - **Azure Policy** = ensures resources *comply with rules* regardless of who creates them

---

## 🏗️ Policy Components

### 1. Policy Definition
- Defines **what to evaluate** and **what action to take**
- Written in JSON
- Contains: conditions (if/then) + effect

### 2. Policy Initiative (Policy Set)
- A **collection of policy definitions** grouped for a specific goal
- Example: "Enable Azure Monitor for VMs" — contains multiple policies

### 3. Policy Assignment
- Applying a policy definition or initiative to a **specific scope**
- Scope: Management Group, Subscription, Resource Group, or Resource

---

## ⚡ Policy Effects (Most Important!)

| Effect | What Happens | Use Case |
|--------|-------------|----------|
| **Deny** | Blocks the non-compliant resource creation/update | Prevent specific VM SKUs |
| **Audit** | Allows but **logs** non-compliance | Monitor without blocking |
| **AuditIfNotExists** | Audits if a related resource **doesn't exist** | Check if diagnostics are enabled |
| **DeployIfNotExists** | Automatically **deploys** a missing resource | Auto-deploy Log Analytics agent |
| **Append** | Adds fields to a resource request | Force add tags |
| **Modify** | Add/modify/remove tags on resources | Enforce tag values |
| **Disabled** | Policy is turned off | Testing |

> 💡 **Remember**: **Deny** = preventive. **Audit** = detective. **DeployIfNotExists** = corrective (remediation).

---

## 📋 Common Built-in Policy Examples

| Policy | Effect | Purpose |
|--------|--------|---------|
| Allowed locations | Deny | Restrict resources to specific regions |
| Allowed VM SKUs | Deny | Only allow certain VM sizes |
| Require tags | Deny | Enforce mandatory tags |
| Audit VMs without managed disks | Audit | Check disk compliance |
| Deploy Log Analytics agent | DeployIfNotExists | Auto-deploy monitoring agent |
| Inherit tags from resource group | Modify | Auto-add RG tags to resources |

---

## 🔧 Custom Policy Definition (JSON Structure)

```json
{
  "properties": {
    "displayName": "Require tag on resources",
    "description": "Enforces a required tag on resources",
    "mode": "Indexed",
    "parameters": {
      "tagName": {
        "type": "String",
        "metadata": {
          "displayName": "Tag Name",
          "description": "Name of the tag"
        }
      }
    },
    "policyRule": {
      "if": {
        "field": "[concat('tags[', parameters('tagName'), ']')]",
        "exists": "false"
      },
      "then": {
        "effect": "deny"
      }
    }
  }
}
```

---

## 🔄 Compliance & Remediation

### Compliance States
| State | Meaning |
|-------|---------|
| **Compliant** | Resource meets policy requirements |
| **Non-compliant** | Resource violates the policy |
| **Exempt** | Resource is excluded from evaluation |

### Remediation Tasks
- For **DeployIfNotExists** and **Modify** effects only
- Creates a **remediation task** to fix existing non-compliant resources
- Requires a **managed identity** to perform remediation actions

> ⚠️ **Exam Gotcha**: Policies apply to **new resources immediately** but for existing resources, you must run a **remediation task** to fix non-compliance.

---

## 🏷️ Policy Exclusions (Exemptions)

- You can **exempt** specific resources, resource groups, or subscriptions from a policy
- Two exemption categories:
  - **Waiver**: Exempt because the policy goal doesn't apply
  - **Mitigated**: Exempt because the resource is compliant through another method

---

## 🌍 Policy Scope & Inheritance

```
Management Group Policy
    ↓ (inherited)
    Subscription Policy
        ↓ (inherited)  
        Resource Group Policy
            ↓ (inherited)
            Resource
```

- Policies at higher scopes are **inherited** by all lower-level resources
- You can **exclude** child scopes from a policy assignment

---

## 💡 Azure Policy vs RBAC vs Resource Locks

| Feature | RBAC | Azure Policy | Resource Locks |
|---------|------|-------------|----------------|
| **Controls** | Who can do what | What resources should look like | Prevent deletion/modification |
| **Scope** | User/identity | Resource properties | Resource/group |
| **When enforced** | On action | On create/update | On delete/modify |
| **Prevents creation** | Yes (if no permission) | Yes (Deny effect) | No (locks affect existing) |

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Policy effect to block creation | **Deny** |
| Policy effect to monitor but allow | **Audit** |
| Policy effect to auto-fix | **DeployIfNotExists** or **Modify** |
| Remediation task needed for existing resources | **Yes** |
| Policy evaluation frequency | Every ~24 hours (or on-demand) |
| Policy definition limit per subscription | 500 |
| Initiative definition limit per subscription | 200 |
| Assignment limit per subscription | 200 |
| Remediation requires | Managed identity on the policy assignment |

---

## 🚨 Common Exam Scenarios

**Q: An organization wants to ensure all resources are deployed only in East US and West US. What do you configure?**
→ Apply an **Azure Policy** with **Allowed Locations** and set it to East US and West US with **Deny** effect

**Q: You want to monitor which VMs don't have the Log Analytics agent but don't want to block their creation. What effect?**
→ **AuditIfNotExists** — logs non-compliance without blocking

**Q: You need to automatically deploy the Log Analytics agent to all new VMs. What policy effect?**
→ **DeployIfNotExists**

**Q: A policy with Deny effect was applied. You have 200 existing non-compliant resources. What happens?**
→ Existing resources are **not affected** — only new/updated resources are blocked. You must run a **remediation task** for existing ones (but Deny doesn't deploy, so only Modify/DeployIfNotExists can remediate)

**Q: You need to add a mandatory "CostCenter" tag to all resources. What's the best policy effect for new resources?**
→ **Deny** — block creation if tag is missing. OR **Append** — automatically add the tag.
