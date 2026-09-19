# Azure Policy

> 🎯 Exam Weight: Part of 15–20% Identity & Governance domain

---

## 🔑 What is Azure Policy?

- Service for **enforcing organizational standards** and assessing compliance at scale
- Evaluates resources against defined rules during deployment (ARM request) and continuously on existing resources
- **RBAC vs Azure Policy**:
  - **RBAC**: Controls *who* has permissions to do actions (Identity & Authorization)
  - **Azure Policy**: Controls *what* resource properties and configurations are allowed (Governance & Compliance) regardless of the user's role (even an Owner must comply with Policy!)

---

## 🏗️ Policy Components

### 1. Policy Definition
- Defines **conditions** (if) and an **effect** (then)
- Written in JSON

### 2. Policy Initiative (Policy Set)
- A **collection of related policy definitions** grouped to achieve a broader compliance goal
- Example: "Regulatory Compliance: ISO 27001" or "Enforce Tagging and Monitoring"
- Simplifies governance by assigning and tracking one initiative rather than dozens of individual policies

### 3. Policy Assignment
- Applying a definition or initiative to a specific scope: **Management Group, Subscription, or Resource Group**
- Child scopes inherit assignments automatically

### 4. Exclusions & Exemptions
- **Exclusion**: Specified directly in the assignment to completely bypass certain child resource groups or resources
- **Exemption**: Explicitly exempts a scope or resource from an existing assignment with a formal justification (`Waiver` or `Mitigated`) and optional expiration date

---

## ⚡ Policy Evaluation Order & Effects

```
Disabled ➔ Append / Modify ➔ Deny ➔ Audit ➔ AuditIfNotExists / DeployIfNotExists
```

| Effect | Action on Request | Action on Existing Resources | Typical Use Case |
|--------|-------------------|-----------------------------|------------------|
| **Disabled** | None (turned off) | Not evaluated | Testing / debugging |
| **Modify** | Adds, replaces, or removes tags before ARM processes | Can be remediated | Enforce department tag on resources |
| **Append** | Adds required fields/properties to the resource creation request | Cannot remediate | Append default parameters or IP rules |
| **Deny** | **Blocks** the creation or update of non-compliant resource | **Marked as Non-Compliant** (NOT deleted/stopped!) | Block unapproved VM sizes or locations |
| **Audit** | **Allows** creation/update but logs a warning in activity logs | Marked as Non-Compliant | Assess compliance without breaking apps |
| **AuditIfNotExists** | Evaluates related/child resources; logs warning if missing | Marked as Non-Compliant | Audit if VM has diagnostic extension |
| **DeployIfNotExists** | Creates the missing related resource via managed identity | Requires **Remediation Task** | Auto-deploy Log Analytics agent on new VMs |

> ⚠️ **CRITICAL Exam Gotcha**: When you assign a policy with a **Deny** effect to an existing subscription:
> 1. Existing non-compliant resources **continue running** and are **NOT deleted or stopped**.
> 2. Existing resources appear as **Non-Compliant** in the Azure Policy dashboard.
> 3. Any attempt to update the existing non-compliant resource or deploy a new non-compliant resource is **blocked**.

---

## 🔄 Remediation Tasks

- Applied to resources with **DeployIfNotExists** or **Modify** effects
- To remediate existing resources, you must create a **Remediation Task**
- **Managed Identity Requirement**: The policy assignment creates a System-Assigned (or User-Assigned) Managed Identity. This identity must be granted appropriate RBAC permissions (e.g., Contributor) at the assignment scope to create or modify child resources.

```bash
# Azure CLI: Trigger a compliance evaluation scan
az policy state trigger-scan --resource-group "RG1"

# Azure CLI: Create a remediation task
az policy remediation create \
  --name "RemediateMissingTags" \
  --policy-assignment "/subscriptions/{sub-id}/providers/Microsoft.Authorization/policyAssignments/{assignment-id}" \
  --resource-group "RG1"
```

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Policy vs RBAC | Policy enforces resource configurations; RBAC grants user permissions |
| Deny effect on existing resources | Flags them as Non-Compliant; does NOT delete or power off resources |
| Policy evaluation order | Disabled ➔ Append/Modify ➔ Deny ➔ Audit ➔ AuditIfNotExists/DeployIfNotExists |
| Remediation requirement | Requires Managed Identity with RBAC write permissions on target scope |
| Initiative vs Definition | Initiative is a bundle/grouping of multiple policy definitions |
| Scope exclusion | Can exclude specific Resource Groups or Resources within the assigned scope |
| Triggering manual scan | `az policy state trigger-scan` or `Start-AzPolicyComplianceScan` |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You assign a policy definition that denies the creation of Azure SQL Database servers in the West US region. There are already 5 SQL servers running in West US in that subscription. What happens to the existing servers?**
→ The existing servers **continue to function without interruption**. They are reported as **Non-Compliant** in the Azure Policy dashboard. New deployments of SQL servers in West US are blocked.

**Q: You need to ensure that every newly deployed Virtual Machine automatically has the Log Analytics agent installed, and existing VMs are updated as well.**
→ Assign a built-in policy with the **DeployIfNotExists** effect targeting VMs, and create a **Remediation Task** to deploy the agent on all existing non-compliant VMs.

**Q: An organization wants to enforce 15 different security and compliance policies across all production subscriptions under a single management group.**
→ Create a **Policy Initiative (Policy Set)** containing the 15 definitions, and assign the initiative at the **Management Group scope**.

**Q: You need to prevent developers from deploying expensive VM sizes in RG1, but allow three specific developers who are Subscription Owners to do so.**
→ Azure Policy applies to **ALL users regardless of RBAC permissions** (even Subscription Owners). To allow specific developers, either assign the policy to a different resource group or configure a policy **Exemption** / **Exclusion** for their dedicated resource group.
