# Storage Security

> 🎯 Exam Weight: Part of 15–20% Storage domain

---

## 🔑 Storage Security Overview

Azure Storage security has multiple layers:
1. **Network-level** — firewalls, VNet service endpoints, private endpoints
2. **Authentication** — keys, SAS, Azure AD
3. **Authorization** — RBAC for management, RBAC/ACL for data
4. **Encryption** — data at rest, data in transit
5. **Auditing** — Storage Analytics logging

---

## 🔐 Authentication Methods

### 1. Storage Account Keys
- **Two keys** per account (for zero-downtime rotation)
- Full admin access to the storage account
- Should be **stored in Azure Key Vault**, not in code
- Rotate regularly

```bash
# List storage account keys
az storage account keys list --account-name mystorageaccount --resource-group myRG

# Regenerate a key
az storage account keys renew --account-name mystorageaccount --key primary --resource-group myRG
```

### 2. Azure AD Authentication (Recommended for Data)
- For **Blob** and **Queue** storage
- Assign **storage data roles** (not management roles):
  | Role | Access |
  |------|--------|
  | **Storage Blob Data Owner** | Full access to blob data |
  | **Storage Blob Data Contributor** | Read/write/delete blobs |
  | **Storage Blob Data Reader** | Read-only blob access |
  | **Storage Queue Data Contributor** | Read/write queue messages |
- More secure than keys — uses short-lived tokens, audit trail

### 3. Shared Access Signatures (SAS)
(See also: [Storage Accounts — SAS](./01-storage-accounts.md))

| SAS Type | Based On | Security Level |
|----------|---------|---------------|
| **Account SAS** | Storage account key | Medium |
| **Service SAS** | Storage account key | Medium |
| **User delegation SAS** | Azure AD identity | **Highest** |

> 💡 **Best Practice**: Use **User delegation SAS** when possible. Never embed account keys in applications.

---

## 🌐 Network Security

### Storage Firewall Rules
- By default: public access from all networks allowed
- Can restrict to:
  - **Selected virtual networks and IP ranges**
  - **Specific IP addresses**
  - **Trusted Microsoft services** only

```bash
# Restrict storage to a specific VNet
az storage account update \
  --name mystorageaccount \
  --resource-group myRG \
  --default-action Deny

# Add a VNet rule
az storage account network-rule add \
  --account-name mystorageaccount \
  --resource-group myRG \
  --vnet-name myVNet \
  --subnet mySubnet
```

### Service Endpoints
- Route traffic from a VNet to storage over the **Azure backbone**
- Storage still has a **public endpoint** but access is controlled via VNet rules
- Configuration: Enable on subnet, then add VNet rule to storage account

### Private Endpoints
- Gives storage a **private IP** in your VNet
- Traffic never leaves the Azure network
- DNS resolution returns the **private IP**, not public endpoint
- Most secure option — blocks all public access possible

> | Feature | Service Endpoint | Private Endpoint |
> |---------|-----------------|-----------------|
> | IP type | Public (but VNet-routed) | **Private IP** |
> | Public endpoint | Still exists | Can be disabled |
> | DNS | No change needed | Needs private DNS zone |
> | Security | Good | **Best** |

---

## 🔒 Encryption

### At Rest
- All Azure Storage data is **automatically encrypted** using **AES-256**
- Enabled by default — **cannot be disabled**
- **Encryption key management options**:
  | Option | Description |
  |--------|-------------|
  | **Microsoft-managed keys (MMK)** | Default — Microsoft manages keys |
  | **Customer-managed keys (CMK)** | You manage keys in **Azure Key Vault** |
  | **Customer-provided keys** | You provide key on each request (API only) |

> 💡 CMK gives you full control: rotate, revoke, and audit key usage.

### In Transit
- Data encrypted in transit using **TLS (HTTPS)**
- Can **enforce HTTPS only** by enabling "Secure transfer required" on storage account (default: enabled)
- When secure transfer is required, any HTTP request fails

```bash
# Enforce HTTPS (secure transfer)
az storage account update \
  --name mystorageaccount \
  --resource-group myRG \
  --https-only true
```

---

## 🏛️ Azure Key Vault Integration

### What is Azure Key Vault?
- Managed service for storing **secrets, keys, and certificates**
- Used for:
  - **Secrets**: connection strings, passwords, API keys
  - **Keys**: encryption keys for CMK
  - **Certificates**: TLS/SSL certificates

### Key Vault Access
- **Access Policies** (legacy): Grant identities permission to secrets/keys/certificates
- **Azure RBAC** (recommended): Use role assignments for Key Vault data plane

### Key Rotation
- Azure Key Vault can **automatically rotate** keys on a schedule
- Configure rotation policy on the key
- Storage account with CMK automatically picks up new key version

---

## 📊 Storage Analytics & Logging

### Diagnostic Settings
- Enable logging for:
  - **Read operations**
  - **Write operations**
  - **Delete operations**
- Logs stored in `$logs` container in the storage account
- View in **Azure Monitor** or **Log Analytics**

### Metrics
- **Capacity metrics**: Storage used, blob count
- **Transaction metrics**: Requests, errors, latency, availability
- View in **Azure Monitor → Metrics**

---

## 🔑 Shared Access Signatures (SAS) — Deep Dive

### SAS Token Components
```
sv=2023-01-03        # Storage service version
st=2024-01-01T00:00Z # Start time
se=2024-12-31T23:59Z # Expiry time  
sr=c                 # Resource: b=blob, c=container, s=share, q=queue, t=table
sp=rl                # Permissions: r=read, w=write, d=delete, l=list
sip=1.2.3.4          # IP restriction (optional)
spr=https            # Protocol: https only
sig=xxx              # Signature (HMAC-SHA256)
```

### Stored Access Policies
- Pre-define a SAS policy on a container/share/queue
- Can **revoke** SAS tokens by modifying or deleting the policy
- Without stored access policy, individual SAS tokens **cannot be revoked** before expiry

```bash
# Create a stored access policy
az storage container policy create \
  --container-name mycontainer \
  --name ReadPolicy \
  --permissions rl \
  --expiry 2024-12-31 \
  --account-name mystorageaccount

# Create SAS using stored access policy
az storage container generate-sas \
  --container-name mycontainer \
  --policy-name ReadPolicy \
  --account-name mystorageaccount
```

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Storage encryption algorithm | **AES-256** |
| Encryption default | **Always on**, cannot disable |
| Default key management | **Microsoft-managed keys** |
| Secure transfer default | **Enabled** (HTTPS required) |
| Private endpoint gives | Private IP to storage |
| Service endpoint | VNet routing, still public IP |
| SAS revocation (without stored policy) | **Not possible** before expiry |
| SAS revocation (with stored policy) | **Yes** — delete/modify policy |
| Most secure SAS type | **User delegation SAS** |
| Key Vault stores | Secrets, Keys, Certificates |

---

## 🚨 Common Exam Scenarios

**Q: You issued a SAS token to a contractor. You need to revoke it immediately. What should have been set up?**
→ A **Stored Access Policy** — delete or modify it to immediately revoke all SAS tokens referencing it

**Q: An application needs to read blob data. You don't want to use storage account keys. What's the most secure approach?**
→ Use a **Managed Identity** for the application and assign it the **Storage Blob Data Reader** role

**Q: You need to ensure no storage account in your subscription allows HTTP traffic. What do you configure?**
→ **Azure Policy** to enforce "Secure transfer required" on all storage accounts

**Q: A team wants to use their own encryption keys and be able to revoke access to data at any time. What do you configure?**
→ **Customer-managed keys (CMK)** stored in **Azure Key Vault**

**Q: An app in a VM needs to access blob storage. The storage should not be accessible from the internet. What do you use?**
→ **Private endpoint** for the storage account + configure the storage firewall to deny public access
