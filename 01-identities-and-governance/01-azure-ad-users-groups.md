# Azure AD Users & Groups (Microsoft Entra ID)

> 🎯 Exam Weight: Part of 15–20% Identity & Governance domain

---

## 🔑 Key Concepts

### Azure Active Directory (now called Microsoft Entra ID)
- Microsoft's **cloud-based identity and access management** service
- Different from on-premises Windows Server Active Directory (AD DS)
- Used for authenticating users to Azure, Microsoft 365, and custom apps

### Tenants vs Subscriptions
| Concept | Description |
|---------|-------------|
| **Tenant** | An instance of Azure AD representing one organization |
| **Subscription** | A billing/resource container. One tenant can have **multiple subscriptions** |
| **Directory** | Another name for a tenant |

> ⚠️ **Exam Gotcha**: One Azure AD tenant can be associated with multiple subscriptions, but one subscription can only trust **one** Azure AD tenant.

---

## 👤 User Accounts

### Types of User Accounts
| Type | Description |
|------|-------------|
| **Cloud identity** | Created directly in Azure AD (e.g., user@domain.onmicrosoft.com) |
| **Guest user** | External user invited via B2B collaboration (different org or personal email) |
| **Directory-synchronized** | Synced from on-premises AD using **Azure AD Connect** |

### Creating Users
```powershell
# PowerShell
New-AzADUser -DisplayName "John Doe" -UserPrincipalName "john@contoso.com" -Password $password -MailNickname "john"

# Azure CLI
az ad user create --display-name "John Doe" --user-principal-name john@contoso.com --password P@ssword123
```

### Key User Properties
- **UserPrincipalName (UPN)**: Login name (john@contoso.com)
- **ObjectId**: Unique GUID identifier
- **UsageLocation**: Required before assigning licenses
- **AccountEnabled**: true/false

---

## 👥 Groups

### Types of Groups
| Type | Description | Use Case |
|------|-------------|----------|
| **Security group** | Controls access to resources | RBAC, app access |
| **Microsoft 365 group** | Includes mailbox, calendar, Teams | Collaboration |

### Membership Types
| Type | Description |
|------|-------------|
| **Assigned** | Admin manually adds/removes members |
| **Dynamic User** | Membership auto-managed by rules (e.g., department = "Sales") |
| **Dynamic Device** | For devices based on device properties |

> ⚠️ **Exam Gotcha**: Dynamic groups require **Azure AD Premium P1** license.

### Dynamic Group Rule Example
```
user.department -eq "Sales"
user.jobTitle -contains "Engineer"
(user.department -eq "IT") -and (user.country -eq "US")
```

### Creating Groups
```powershell
# PowerShell
New-AzADGroup -DisplayName "IT Team" -MailNickname "itteam"

# Azure CLI
az ad group create --display-name "IT Team" --mail-nickname "itteam"
```

---

## 🔄 Azure AD Connect (Hybrid Identity)

### What it Does
- Synchronizes on-premises AD users/groups to Azure AD
- Enables **Single Sign-On (SSO)** for hybrid environments

### Sync Methods
| Method | Description |
|--------|-------------|
| **Password Hash Sync (PHS)** | Syncs password hashes. Simplest option. Works if on-prem AD is down |
| **Pass-through Authentication (PTA)** | Validates passwords against on-prem AD in real-time |
| **Federation (AD FS)** | Most complex. Uses separate federation servers |

> 💡 **Exam Tip**: **Password Hash Sync** is the recommended and simplest option for most scenarios.

---

## 🛡️ Multi-Factor Authentication (MFA)

### MFA Methods
- Microsoft Authenticator app
- SMS/voice call
- OATH hardware/software tokens
- FIDO2 security keys

### Conditional Access
- Requires **Azure AD Premium P1**
- Policies that enforce MFA based on conditions:
  - User location (IP/country)
  - Device compliance state
  - Application being accessed
  - Sign-in risk level

### Named Locations
- Define trusted IP ranges to bypass or enforce MFA
- Can exclude corporate network from MFA requirement

---

## 🔐 Self-Service Password Reset (SSPR)

- Requires **Azure AD Premium P1** (or is included in Microsoft 365 Business Premium)
- Users can reset their own passwords without IT help desk
- Authentication methods: email, phone, security questions, authenticator app

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Free tier max users | Unlimited (basic features) |
| Dynamic groups require | Azure AD Premium P1 |
| SSPR requires | Azure AD Premium P1 |
| Conditional Access requires | Azure AD Premium P1 |
| Azure AD Privileged Identity Management requires | Azure AD Premium P2 |
| B2B guest user invitation | Free (up to 5 guest users per licensed user) |
| Max subscriptions per tenant | No hard limit |
| Default user role permissions | Can read all directory info, invite guests, register apps |

---

## 🚨 Common Exam Scenarios

**Q: A company wants to automatically add users from the Sales department to a group. What do they need?**
→ **Dynamic group** with rule `user.department -eq "Sales"` + **Azure AD Premium P1**

**Q: Users need to reset their own passwords. What's required?**
→ Enable **SSPR** and configure authentication methods

**Q: An on-premises AD user needs to access Azure resources. What's the best sync method?**
→ **Azure AD Connect** with **Password Hash Sync** (unless strong requirement for real-time validation)

**Q: A guest user from another company needs access. What do you use?**
→ **Azure AD B2B** — invite as guest user
