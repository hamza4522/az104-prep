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
>
> 💡 **Elevating Access**: A Global Administrator does **NOT** automatically have access to subscription resources by default. They must toggle **Access management for Azure resources** to **Yes** in Entra ID properties to grant themselves User Access Administrator at the root management group level.

---

## 🌐 Custom Domains & Verification

- Azure AD default domain is `<name>.onmicrosoft.com`
- You can add custom domain names (e.g., `contoso.com`)
- **Verification Requirement**: Add a **TXT record** (or MX record) with the specified verification value in your public DNS registrar/zone
- Until verified, the status remains **Unverified** and users cannot be assigned UPNs with that domain
- You can change the primary domain name only after the custom domain is verified

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

### Bulk User Operations
- **CSV template** in Azure Portal or PowerShell `Import-Csv` + `New-AzADUser`
- Required CSV fields: `Name`, `User name` (UPN), `Initial password`, `Block sign in (Yes/No)`

### User Lifecycle & Deletion
- Deleted users enter the **Deleted users** (recycle bin) for **30 days**
- During the 30-day window, users can be **restored** with all group memberships and licenses intact
- After 30 days, users are permanently and automatically deleted

### Key User Properties
- **UserPrincipalName (UPN)**: Login name (`john@contoso.com`)
- **ObjectId**: Unique GUID identifier
- **UsageLocation**: Required before assigning licenses (M365 / Azure AD Premium)
- **AccountEnabled**: true/false

---

## 👥 Groups

### Types of Groups
| Type | Description | Use Case |
|------|-------------|----------|
| **Security group** | Controls access to resources | RBAC, app access, licensing |
| **Microsoft 365 group** | Includes mailbox, calendar, Teams | Collaboration |

### Membership Types
| Type | Description | License |
|------|-------------|---------|
| **Assigned** | Admin manually adds/removes members | Free |
| **Dynamic User** | Membership auto-managed by rules (e.g., department = "Sales") | **Premium P1** |
| **Dynamic Device** | Members auto-managed based on device properties | **Premium P1** |

> ⚠️ **Exam Gotchas**:
> 1. Dynamic groups require an **Azure AD Premium P1** license for each unique user that is a member.
> 2. You **cannot** manually add or remove members from a dynamic group.
> 3. Dynamic groups **cannot** contain other groups (nested dynamic groups are not supported).

### Dynamic Group Rule Syntax Examples
```
# User rules
user.department -eq "Sales"
user.jobTitle -contains "Engineer"
(user.department -eq "IT") -and (user.country -eq "US")
user.userPrincipalName -endsWith "@contoso.com"

# Device rules
device.deviceOSType -eq "Windows"
device.deviceOSVersion -startsWith "10.0"
```

---

## 💻 Device Settings & Identity Types

### Device Identity Options
| Type | Description | Typical OS | Joined To |
|------|-------------|------------|-----------|
| **Azure AD registered** | Bring Your Own Device (BYOD) | Windows, iOS, Android, macOS | Local account / personal |
| **Azure AD joined** | Cloud-only corporate devices | Windows 10/11, Windows Server | Azure AD only |
| **Hybrid Azure AD joined** | On-prem AD joined + synced to Azure AD | Windows 10/11, Windows Server | On-prem AD + Azure AD |

### Key Device Settings in Azure AD Portal
1. **Users may join devices to Azure AD**:
   - Options: `All`, `Selected`, `None`
   - Controls which users can perform Azure AD Join
2. **Additional local administrators on Azure AD joined devices**:
   - Allows selecting specific users/groups to be granted local Administrator rights on all joined devices
3. **Maximum number of devices per user**:
   - Configurable quotas: **5, 10, 20, 50, 100, or Unlimited** (default is 50)
   - When a user reaches the maximum quota, they **cannot** join or register new devices until existing devices are removed or the quota is raised

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

## 🛡️ Multi-Factor Authentication (MFA) & Conditional Access

### MFA Methods
- Microsoft Authenticator app (push notification or TOTP)
- SMS / voice call
- OATH hardware/software tokens
- FIDO2 security keys

### Conditional Access Policies
- Requires **Azure AD Premium P1**
- Evaluates signals (**Conditions**) to apply enforcement (**Access Controls**):
  - **Conditions**: User/group, Cloud app, Location (Named IP ranges), Device platforms, Client apps, Sign-in risk
  - **Grant Controls**: Block access OR Grant with requirements (Require MFA, Require compliant device, Require Hybrid Azure AD join)
  - **Session Controls**: App-enforced restrictions, Conditional Access App Control, Sign-in frequency

---

## 🔐 Self-Service Password Reset (SSPR)

- Requires **Azure AD Premium P1**
- **Rollout Scopes**:
  - `None` (Disabled)
  - `Selected` (Specific security group)
  - `All` (All tenant users)
- **Methods Required to Reset**: 1 or 2
- **Available Authentication Methods**:
  - Mobile app notification
  - Mobile app code
  - Email
  - Mobile phone (SMS/call)
  - Office phone
  - Security questions (registration requires picking 3–5 questions)
- **Password Writeback**: Allows password changes in Azure AD to sync back to on-premises AD DS in real-time. Requires **Azure AD Connect** + **Azure AD Premium P1**.

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Dynamic groups license requirement | Azure AD Premium P1 |
| SSPR license requirement | Azure AD Premium P1 |
| Conditional Access license | Azure AD Premium P1 |
| Device join quota default | 50 devices per user (range: 5–100 or Unlimited) |
| Device limit error behavior | User is blocked from joining new devices until an old device is deleted |
| Soft-deleted user retention | 30 days in Entra ID recycle bin |
| Global Administrator Azure resources | Must toggle "Access management for Azure resources" to manage subscriptions |
| Custom domain validation | Add TXT or MX record in DNS registrar |
| MFA Server usage model | Cannot change usage model after creation; must deploy a new server |
| Dynamic group nesting | Not supported (dynamic groups cannot contain nested groups) |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: A user fails to register or join a new laptop to Azure AD with an error stating device limits. What is the cause?**
→ The user reached the **Maximum number of devices per user** quota configured in Azure AD Device Settings. Fix: Delete old devices from Azure AD or increase the device quota.

**Q: You need to assign the same department tag or group membership dynamically to 500 users based on their office location.**
→ Create a **Dynamic User Group** with membership rule `user.city -eq "Seattle"` or `user.department -eq "Finance"`. Requires Azure AD Premium P1.

**Q: You want to roll out SSPR only to pilot users in the Finance department first.**
→ Set SSPR enablement to **Selected** and target a security group containing the Finance department users.

**Q: A Global Administrator cannot see or manage resources in an Azure subscription within the tenant.**
→ The Global Admin must navigate to **Microsoft Entra ID > Properties** and set **Access management for Azure resources** to **Yes**.

**Q: You need to verify ownership of a custom domain `contoso.com` in your Azure AD tenant.**
→ Create a **TXT record** (or MX record) with the verification ID at the domain's public DNS registrar.

**Q: An administrator accidentally deletes a critical user account. How can it be recovered?**
→ Restore the user from the **Deleted users** container in Azure AD within **30 days**. All previous group memberships and permissions are restored automatically.

**Q: You need to create groups that will grant 3 users access to a SharePoint library and must auto-delete after 180 days. Which group types support this?**
→ Only **Microsoft 365 groups** support expiration policies. Create either:
  - A **Microsoft 365 group (Assigned membership)**, OR
  - A **Microsoft 365 group (Dynamic User membership)**
  - ⚠️ Security groups do NOT support expiration policies.

**Q: Admin1 (User Administrator role) tries to invite external partner user1@outlook.com and gets "Generic authorization exception". What should you do?**
→ From the **Users blade**, modify the **External collaboration settings** — configure who can invite guests (All users / Member users only / Admins only).

**Q: You have hybrid users (synced from on-premises AD). For which users can you modify the JobTitle attribute directly from Azure AD?**
→ Only **cloud-only users** (created in Azure AD) can have JobTitle modified directly in Azure AD. For synced users whose source is **Windows Server AD**, you must modify the attribute in the **on-premises Active Directory** — the change will then sync to Azure AD.

---

## 👥 Group Expiration Policy

| Group Type | Supports Expiration Policy? |
|------------|---------------------------|
| **Microsoft 365 group** | ✅ Yes — can be configured to auto-delete after N days |
| **Security group (Assigned)** | ❌ No |
| **Security group (Dynamic)** | ❌ No |

> 💡 **Exam Gotcha**: Expiration policies apply **only to Microsoft 365 groups** in Azure AD. Security groups of any membership type do NOT support expiration.

---

## 🌐 External Collaboration (B2B Guest Users)

- Governed by **External collaboration settings** in Azure AD (Users blade)
- Controls:
  - **Guest user access restrictions**: What guests can see in the directory
  - **Guest invite settings**: Who can invite external users (All users / Member users only / Admins and guest inviters only / No one)
- **Default**: Only Global Administrators and Guest Inviters can send invitations

> 💡 **Exam Tip**: If a User Administrator gets "Generic authorization exception" when inviting a guest → Go to **External collaboration settings** and change "Guest invite restrictions" to allow member users to invite.

---

## 🔄 Hybrid Identity: Attribute Editing Rules

| User Source | Can Edit in Azure AD? | Must Edit Where? |
|-------------|----------------------|-----------------|
| **Cloud-only** (created in Azure AD) | ✅ Yes | Azure AD portal |
| **Synced from on-premises AD** | ❌ No for most identity/contact/job attributes | **On-premises Active Directory** (then syncs to Azure AD) |
| **UsageLocation** | ✅ Yes for all users | Azure AD (needed for license assignment) |

