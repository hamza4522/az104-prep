# Azure DNS & Private DNS Zones

> 🎯 Exam Weight: Part of 25–30% Networking domain

---

## 🔑 Public Azure DNS vs Azure Private DNS Zones

| Feature | Public Azure DNS | Azure Private DNS Zones |
|---------|------------------|-------------------------|
| **Scope** | Global Internet | Virtual Networks in Azure |
| **Zone Type** | Standard domain (e.g. `contoso.com`) | Private domain (e.g. `corp.internal`) |
| **Resolution** | Public internet clients | Linked VNets only |
| **Auto-Registration** | ❌ No | ✅ **Yes** (for VMs in Registration VNet) |

---

## 🔒 Azure Private DNS Zones: Registration vs Resolution Links

When linking a Virtual Network to an Azure Private DNS Zone:

```
[Azure Private DNS Zone: corp.internal]
       ▲                                 ▲
       │ (Auto-registration enabled)     │ (Resolution only)
       ▼                                 ▼
[VNet-Prod (Registration VNet)]     [VNet-Dev (Resolution VNet)]
Auto-registers VM hostnames        Resolves records; NO auto-register
```

| Link Setting | Max VNets per Zone | Automatic Hostname Registration? |
|--------------|-------------------|----------------------------------|
| **Registration Virtual Network** | **1 VNet** per private zone | ✅ **Yes** (VM name + private IP added/updated/deleted automatically) |
| **Resolution Virtual Network** | Up to **1,000 VNets** | ❌ No (manual record creation, but resolves existing records) |

---

## 🏷️ Public DNS Record Types & Alias Records

| Record Type | Maps | Use Case |
|-------------|------|----------|
| **A Record** | Hostname ➔ IPv4 address | Standard host routing (`13.72.x.x`) |
| **CNAME Record** | Hostname ➔ Canonical FQDN | Subdomain alias (`www.contoso.com` ➔ `app.azurewebsites.net`) |
| **Alias Record** | Hostname ➔ **Azure Resource directly** | Apex domain (`contoso.com`) or dynamic Azure public IPs |

### Why Use Alias Records?
- Standard DNS does **not** allow CNAME records at the zone apex (`contoso.com`).
- An **Alias record** can be created at the zone apex and point directly to:
  - Azure Public IP address resource
  - Azure Traffic Manager profile
  - Azure Front Door profile
- If the underlying Azure resource IP changes, the alias record **automatically updates** without TTL delays!

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Registration VNets per Private DNS Zone | Exactly **1** VNet |
| Resolution VNets per Private DNS Zone | Up to **1,000** VNets |
| Apex domain record pointing to Azure PaaS | **Alias record** (CNAME cannot be apex) |
| Delegating public domain to Azure DNS | Update **NS records** at domain registrar |
| Auto-registration record lifecycle | When a VM is deleted, its DNS record is automatically removed |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You have an Azure Private DNS zone named `internal.contoso.com` linked to VNet1 with auto-registration enabled. You link VNet2 to the same zone. You need VMs deployed in VNet2 to automatically register their DNS records. What should you do?**
→ A Private DNS zone supports only **one registration virtual network**. You must deploy a second Private DNS zone for VNet2 auto-registration, or register VNet2 VM records manually.

**Q: You need to configure a DNS record for the zone apex (`contoso.com`) that routes traffic to an Azure Traffic Manager profile.**
→ Create an **Alias record** (A record with Alias enabled) at the zone apex pointing to the Traffic Manager resource.

**Q: You delegate a public domain `contoso.com` to Azure DNS. What records must you configure at your domain registrar?**
→ Configure the 4 Azure DNS **Name Server (NS) records** provided in the Azure DNS zone overview.
