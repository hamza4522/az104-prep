# 🔐 IAM Lab 01 — Multi-Level Identity & Access Management

## Level Overview

| Level | Scenario | Real-World Context | Time |
|---|---|---|---|
| 🟢 **Level 1** | Multi-department user provisioning | Onboarding 50+ employees across 5 departments | 30 min |
| 🟡 **Level 2** | Enterprise RBAC with Separation of Duties | Production access model with custom roles | 60 min |
| 🔴 **Level 3** | Zero Trust + PIM + Conditional Access + SIEM | Full enterprise Zero Trust identity architecture | 90 min |

> **Run the lab:** `bash lab-script.sh` — all levels run sequentially

---

## 🟢 Level 1 — Multi-Department User Provisioning

**Scenario:** You are a Platform Engineer at a 200-person company. HR has sent you an onboarding request for 8 new hires across Engineering, Security, Finance, DevOps, and Data teams. You must create all accounts, assign them to appropriate security groups with proper hierarchy, and enforce naming standards.

### What you build:
```
Azure AD
├── grp-eng-all            (nested)
│   ├── grp-eng-lead       → Alice Chen (Senior Lead Engineer)
│   ├── grp-eng-engineer   → Bob Kumar (Software Engineer)
│   └── grp-devops-all     (nested — DevOps is part of Engineering org)
│       ├── grp-devops-lead    → Frank Lee
│       └── grp-devops-engineer → Grace Wu
├── grp-sec-all
│   ├── grp-sec-admin      → Carol Osei (Security Administrator)
│   └── grp-sec-engineer   → Dave Silva (Security Analyst)
├── grp-fin-all
│   └── grp-fin-readonly   → Eve Johnson (Financial Analyst)
└── grp-data-all
    └── grp-data-engineer  → Hank Patel (Data Engineer)
```

### Key Concepts Practiced:
- Azure AD user creation with department metadata
- Security group hierarchy (nested groups)
- Naming conventions for enterprise scale
- Temporary password + force change on first login

---

## 🟡 Level 2 — Production RBAC with Separation of Duties

**Scenario:** Your company has 4 environments (Production, Staging, Development, Shared Services). Implement Separation of Duties: developers CANNOT touch production, DevOps can operate but not create/delete, Security can audit everything but cannot read secrets, Finance sees costs only.

### RBAC Matrix:

| Group | Production | Staging | Development | Subscription-wide |
|---|---|---|---|---|
| `grp-eng-lead` | Reader | Contributor | Contributor | — |
| `grp-eng-engineer` | — | Reader | Contributor | — |
| `grp-devops-lead` | **Custom: DevOps Operator** | **Custom: DevOps Operator** | **Custom: DevOps Operator** | DevOps Operator |
| `grp-sec-admin` | **Custom: Security Auditor** | Security Auditor | Security Auditor | **Security Admin** |
| `grp-fin-readonly` | — | — | — | Cost Management Reader + Billing Reader |

### Custom Roles Created:
1. **`Custom - DevOps Operator`** — Start/stop/restart VMs, VMSS, App Services. NO create/delete/network/secrets
2. **`Custom - Security Auditor`** — Read ALL resources. NO data plane (blobs, secrets, DB data, storage keys)
3. **`Custom - Application Developer`** — Deploy to App Service, push to ACR. Dev/Staging ONLY

---

## 🔴 Level 3 — Zero Trust Identity Architecture

**Scenario:** Your CISO requires Zero Trust implementation following the NIST 800-207 standard. No standing privileged access. All admin actions require JIT elevation. All sign-ins are risk-scored. Breaches are detected automatically.

### Architecture:

```
┌──────────────────────────────────────────────────────────────────┐
│                   ZERO TRUST IDENTITY PLANE                      │
│                                                                  │
│  ┌─────────────────┐    ┌──────────────────┐                     │
│  │  Conditional     │    │  Identity         │                    │
│  │  Access Engine   │    │  Protection       │                    │
│  │                  │    │  (Risk Engine)    │                    │
│  │  CA001: MFA all  │    │  User risk score  │                    │
│  │  CA002: No legacy│    │  Sign-in risk     │                    │
│  │  CA003: Compliant│    │  Leaked creds     │                    │
│  │  CA004: Risk→MFA │    │  Atypical travel  │                    │
│  └────────┬─────────┘    └────────┬──────────┘                   │
│           │                       │                              │
│  ┌────────▼───────────────────────▼──────────┐                   │
│  │              AZURE AD IDENTITY             │                  │
│  │                                            │                  │
│  │  Regular Users    PIM-eligible Admins      │                  │
│  │  (MFA required)   (JIT, time-limited)      │                  │
│  │                                            │                  │
│  │  Break-Glass Accts (excluded from CA!)     │                  │
│  └────────────────────┬───────────────────────┘                  │
│                        │                                         │
│  ┌─────────────────────▼──────────────────────┐                  │
│  │         LOG ANALYTICS / SENTINEL            │                 │
│  │  AuditLogs  SignInLogs  RiskyUsers          │                  │
│  │  KQL Threat Detection → Automated Response │                  │
│  └─────────────────────────────────────────────┘                 │
└──────────────────────────────────────────────────────────────────┘
```

### Components Configured:

#### Break-Glass Accounts
- 2 cloud-only emergency accounts
- Excluded from ALL Conditional Access policies
- Monitored with Severity-0 alert (immediate notification)
- Passwords stored offline (paper + safe + KeePass encrypted)

#### Conditional Access Policies
| Policy ID | Name | Effect |
|---|---|---|
| CA001 | Require MFA for All Users | Report-only → then Enabled |
| CA002 | Block Legacy Authentication | **Enabled immediately** (no exceptions) |
| CA003 | Require Compliant Device for Production | Report-only → then Enabled |
| CA004 | High-Risk Sign-in → MFA + Password Change | **Enabled immediately** |

#### PIM Just-In-Time Access
```
Regular state: User has NO privileged access
                        ↓
User needs access → PIM Activation Request
                        ↓
Provide: Justification + Business reason
                        ↓
MFA verification required
                        ↓
(If Owner role) → Approval from CISO or EM
                        ↓
Time-limited access granted (max 2-8 hours)
                        ↓
Access expires → Audit log recorded → SIEM alert
```

#### KQL Threat Detection Queries (in `lab-script.sh`)
1. **Password Spray** — >10 failures across >5 accounts from same IP
2. **Impossible Travel** — Same user, 2 locations >500km apart, <2 hours
3. **SP After-Hours Activity** — Service principal active outside business hours
4. **Privileged Role Assignment** — ANY Owner/Admin role granted
5. **Mass Download Signal** — >100 file accesses in 10 minutes
6. **Guest Accessing Admin Apps** — Guest in Azure Portal
7. **Stale Accounts** — 90+ days no sign-in

---

## Solution Notes

### Why break-glass accounts are critical:
```
Without break-glass:
  IF your Global Admin's MFA device breaks
  AND Conditional Access blocks non-MFA logins
  THEN you are COMPLETELY LOCKED OUT of your Azure tenant

With break-glass:
  Emergency account bypasses CA → You can fix the configuration
```

### SoD (Separation of Duties) key rules:
1. No single person can both **request** and **approve** privilege
2. Developers CANNOT deploy to production directly
3. People who write code CANNOT approve their own deployments
4. Finance CANNOT grant themselves resource access
5. Security team CANNOT modify the security policies that audit them

---

## Cleanup
```bash
source lab-script.sh
cleanup_level1_lab
```
