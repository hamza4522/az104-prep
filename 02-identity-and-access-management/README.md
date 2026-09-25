# 🛡️ Identity and Access Management (IAM)

> **AWS Parallel:** AWS IAM + AWS SSO → Azure Active Directory + RBAC  
> **GCP Parallel:** GCP IAM → Azure AD + Role Assignments  
> **OCI Parallel:** OCI IAM → Azure AD + RBAC

## Overview

Azure IAM has two distinct components:
1. **Azure Active Directory (Azure AD / Entra ID)** — Identity provider (who you are)
2. **Azure RBAC** — Authorization (what you can do)

| Concept | Azure | AWS | GCP |
|---|---|---|---|
| Identity Provider | Azure AD (Entra ID) | IAM + Cognito | Cloud Identity |
| Users & Groups | Azure AD Users/Groups | IAM Users/Groups | Cloud Identity |
| Service Identity | Managed Identity | IAM Role (instance profile) | Service Account |
| Access Control | RBAC (Role-Based) | IAM Policies | IAM Roles |
| Cross-account access | Azure Lighthouse / RBAC | Cross-account roles | Workload Identity |
| Temporary credentials | Managed Identity | STS AssumeRole | Workload Identity |
| Secret store | Key Vault | Secrets Manager | Secret Manager |
| Federation | SAML / OIDC / AD Connect | SAML / OIDC | SAML / OIDC |

---

## Labs in This Section

| Lab | Title | Difficulty |
|---|---|---|
| Lab-01 | Azure AD Users, Groups & Licenses | 🟢 |
| Lab-02 | RBAC — Built-in Roles & Custom Roles | 🟡 |
| Lab-03 | Service Principals & App Registrations | 🟡 |
| Lab-04 | Managed Identities (System & User Assigned) | 🟡 |
| Lab-05 | Privileged Identity Management (PIM) | 🔴 |
| Lab-06 | Conditional Access Policies | 🔴 |
| Lab-07 | Azure AD B2B & B2C | ⭐ |

---

## RBAC Scope Hierarchy

```
Root Management Group (/) — Broadest scope
  └── Management Group
        └── Subscription
              └── Resource Group
                    └── Resource  ← Narrowest scope
```

**Key Rule:** Assignments at higher scope are INHERITED by lower scopes (like AWS SCPs)

## Built-in Role Reference

| Role | Description | AWS Equivalent |
|---|---|---|
| Owner | Full access including role assignment | AdministratorAccess |
| Contributor | Can create/manage resources, NO role assignment | PowerUserAccess |
| Reader | Read-only access | ReadOnlyAccess |
| User Access Administrator | Manage access ONLY | IAMFullAccess |
| Specific roles | Storage Blob Data Contributor, VM Contributor, etc. | AWS managed policies |
