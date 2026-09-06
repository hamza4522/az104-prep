# Azure DNS

> 🎯 Exam Weight: Part of 25–30% Networking domain

---

## 🔑 What is Azure DNS?

- **Managed DNS hosting service** using Azure infrastructure
- Host your DNS zones and manage DNS records
- High availability and fast response using Azure's global network
- Integrates with Azure services and RBAC

---

## 📁 DNS Zone Types

### Public DNS Zone
- Resolves names on the **public internet**
- Authoritative DNS for your domain (e.g., contoso.com)
- Anyone on the internet can query it

### Private DNS Zone
- Resolves names **within Azure VNets only**
- Not visible/accessible from the internet
- Used for internal Azure resource name resolution
- Example: vm1.internal.contoso.com resolves to private IP

---

## 📋 DNS Record Types

| Record Type | Description | Example |
|-------------|-------------|---------|
| **A** | Maps hostname to IPv4 address | www → 1.2.3.4 |
| **AAAA** | Maps hostname to IPv6 address | www → 2001:db8::1 |
| **CNAME** | Alias to another hostname | www → myapp.azurewebsites.net |
| **MX** | Mail exchanger | @ → mail.contoso.com |
| **NS** | Name server records | Delegation records |
| **SOA** | Start of Authority | Zone metadata |
| **TXT** | Text records | Domain verification, SPF |
| **PTR** | Reverse DNS lookup | IP → hostname |
| **SRV** | Service location | VoIP, SIP, etc. |
| **CAA** | Certificate Authority Authorization | Which CAs can issue certs |

> ⚠️ **Exam Gotcha**: Cannot create an **A record at the zone apex** (root) — instead use an **Alias record** to point to an Azure resource (Load Balancer, Traffic Manager, Front Door, Public IP). This is unique to Azure DNS.

---

## 🌐 Azure Private DNS Zone

### How It Works
- Create a private DNS zone (e.g., `internal.contoso.com`)
- **Link** it to one or more VNets
- Resources in linked VNets can resolve the private zone

### VNet Links
| Link Type | Description |
|-----------|-------------|
| **Registration (auto-registration)** | VMs in this VNet automatically get DNS records |
| **Resolution** | VNet can query the zone but records NOT auto-created |

> ⚠️ Auto-registration works for VMs only — not for other Azure resources.

### Use Cases
- Internal hostname resolution for VMs
- **Azure Private Endpoint DNS** — private endpoints need private DNS zones to resolve correctly
- Hybrid DNS — resolve Azure resources from on-premises

### Private DNS Zone Auto-Registration
```
VM created in VNet with auto-registration link
    → VM gets A record: myvm.internal.contoso.com → 10.0.0.4
VM deleted
    → A record is automatically removed
```

---

## 🔗 Azure DNS Alias Records

- Special record type in Azure DNS
- Points to Azure resources (not IPs)
- **Automatically updates** when the Azure resource's IP changes
- Supported for: A, AAAA, CNAME record types

### When to Use Alias Records
| Scenario | Solution |
|----------|---------|
| Point zone apex (root) to Azure Load Balancer | **Alias A record** at @  |
| Point zone apex to Traffic Manager | **Alias A record** at @ |
| CNAME at zone apex | Not allowed — use **Alias A record** |
| Auto-update when IP changes | Use **Alias record** |

---

## 🛠️ Managing DNS Zones

```bash
# Create a public DNS zone
az network dns zone create \
  --resource-group myRG \
  --name contoso.com

# Add an A record
az network dns record-set a add-record \
  --resource-group myRG \
  --zone-name contoso.com \
  --record-set-name www \
  --ipv4-address 1.2.3.4

# Add a CNAME record
az network dns record-set cname set-record \
  --resource-group myRG \
  --zone-name contoso.com \
  --record-set-name app \
  --cname myapp.azurewebsites.net

# Create a private DNS zone
az network private-dns zone create \
  --resource-group myRG \
  --name internal.contoso.com

# Link private zone to VNet
az network private-dns link vnet create \
  --resource-group myRG \
  --zone-name internal.contoso.com \
  --name myVNetLink \
  --virtual-network myVNet \
  --registration-enabled true
```

---

## 🔀 DNS Resolution in Azure (Default)

### Azure-Provided DNS (168.63.129.16)
- Default DNS for all VMs in Azure
- Resolves:
  - Azure-internal hostnames (VM names within VNet)
  - Public internet names
- Limitation: Cannot resolve on-premises names

### Custom DNS
- Configure VNet to use a custom DNS server
- Custom DNS server can forward queries to:
  - Azure DNS (`168.63.129.16`) for Azure resources
  - On-premises DNS for internal domains
- Used in **hybrid scenarios**

---

## 🔗 Private Endpoint DNS

When using Private Endpoints, DNS must resolve to the private IP:
- Azure creates a **privatelink.** subdomain
- Create a **Private DNS Zone** matching the privatelink zone
- Link the zone to VNets that need to resolve

Example for Storage:
```
Public DNS: mystorageaccount.blob.core.windows.net → 20.0.0.1 (public IP)
Private DNS: mystorageaccount.blob.core.windows.net → CNAME → mystorageaccount.privatelink.blob.core.windows.net → 10.0.0.5 (private IP)
```

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Azure DNS resolves | Public zones + private zones |
| Zone apex records | Use **Alias records** (not CNAME) |
| Auto-registration on private zone | VMs only, not other resources |
| Private DNS zone links | VNet must be linked to resolve |
| Custom DNS IP for Azure | **168.63.129.16** |
| Private endpoint DNS | Needs private DNS zone for proper resolution |
| CNAME at zone root | **Not allowed** — use Alias record |
| Alias record auto-updates | Yes, when Azure resource IP changes |

---

## 🚨 Common Exam Scenarios

**Q: A company wants to use a custom domain (contoso.com) with Azure Traffic Manager. How do they create a root domain record?**
→ Create an **Alias A record** at the zone apex (@) pointing to the Traffic Manager profile

**Q: VMs in a VNet need to resolve each other by hostname automatically. What do you configure?**
→ **Private DNS Zone** with a **VNet link** where **registration (auto-registration) is enabled**

**Q: An App Service at `myapp.azurewebsites.net` needs a custom domain `www.contoso.com`. What DNS record?**
→ **CNAME** record: www → myapp.azurewebsites.net

**Q: A storage account has a private endpoint. VMs in a peered VNet cannot resolve its hostname. What's missing?**
→ The **Private DNS Zone** for blob storage needs to be **linked** to the peered VNet
