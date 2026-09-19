# Azure App Service

> 🎯 Exam Weight: Part of 20–25% Compute domain

---

## 🔑 Core Concepts

- Fully managed **Platform as a Service (PaaS)** for hosting web applications, REST APIs, and mobile backends
- Supports .NET, Java, Node.js, PHP, Python, and custom Docker containers
- Automatic OS patching, capacity provisioning, and load balancing

---

## 📦 App Service Plans & Tiers

| Tier | Deployment Slots | Custom Domains & SSL | Autoscale | Backups |
|------|------------------|----------------------|-----------|---------|
| **Free / Shared** | ❌ None | ❌ No | ❌ No | ❌ No |
| **Basic** | ❌ None | ✅ Yes | ❌ Manual only | ❌ No |
| **Standard** | ✅ **5 slots** | ✅ Yes | ✅ Up to 10 instances | ✅ Up to 10/day |
| **Premium (v2/v3)** | ✅ **20 slots** | ✅ Yes | ✅ Up to 30–100 instances | ✅ Up to 50/day |
| **Isolated** | ✅ **20 slots** | ✅ Yes | ✅ Dedicated VNet (ASE) | ✅ Yes |

> 💡 **Scaling Terminology**:
> - **Scale Up**: Increase CPU, RAM, disk space, or upgrade plan tier (e.g. Basic to Standard).
> - **Scale Out**: Increase the **number of VM instances** running the app.

---

## 🔄 Deployment Slots & Zero-Downtime Swaps

- Live apps with their own hostnames and configurations
- Supported on **Standard**, **Premium**, and **Isolated** tiers
- Allows validating code in a **Staging slot** before swapping into **Production**

### Swapped vs Sticky (Unswapped) Settings
When swapping slots:
- **Settings that SWAP**: Framework version, web sockets, connection strings (by default), app settings.
- **Settings that DO NOT swap (Sticky to slot)**:
  - Publishing endpoints & credentials
  - Custom domain names & SSL certificates
  - Scaling settings
  - Any App Setting or Connection String marked as **Deployment slot setting**!

```bash
# Azure CLI: Swap staging into production
az webapp deployment slot swap   --resource-group "RG1"   --name "MyWebApp"   --slot "staging"   --target-slot "production"
```

---

## 🌐 Custom Domain & SSL Verification

To bind a custom domain (e.g. `www.contoso.com`) to an App Service:
1. **Verification**: Create a **TXT record** at your DNS registrar:
   - Host: `asuid.www.contoso.com`
   - Value: The **Custom Domain Verification ID** found in the App Service portal.
2. **Routing**: Create a **CNAME record** mapping `www.contoso.com` to `<appname>.azurewebsites.net`.
3. For apex/root domains (e.g. `contoso.com`), use an **A record** mapped to the App Service inbound IP address + TXT record for verification.

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Minimum tier for Deployment Slots | **Standard** tier |
| Minimum tier for Custom Domain SSL | **Basic** tier |
| Minimum tier for Autoscale & Backup | **Standard** tier |
| Custom domain verification record | **TXT record** with `asuid.<subdomain>` |
| Sticking a setting to a specific slot | Check **"Deployment slot setting"** checkbox |
| Slot swap downtime | **Zero downtime** (pre-warms staging instance before routing traffic) |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You need to deploy a new version of a web application to App1 with zero downtime, and verify it with automated tests before directing production traffic to it.**
→ Deploy the new version to a **Staging Deployment Slot**, run verification tests, and then perform a **Slot Swap** with the Production slot.

**Q: You have an App Service with a Production slot and a Staging slot. You need to ensure the Staging slot always connects to a test database and never swaps connection strings with Production.**
→ In the App Service configuration, edit the database connection string and enable the **Deployment slot setting** checkbox.

**Q: You need to configure a custom domain `shop.contoso.com` on an Azure Web App. Which two DNS records must you create in your public DNS zone?**
→ A **CNAME record** pointing `shop.contoso.com` to `appname.azurewebsites.net`, and a **TXT record** pointing `asuid.shop.contoso.com` to the Custom Domain Verification ID.

**Q: You need to add a custom domain named `www.contoso.com` to webapp1. What should you do FIRST?**
→ **Create a DNS record** (CNAME or A record) at your DNS registrar pointing the custom domain to the App Service. You cannot add the domain in the portal until the DNS record exists for verification.

**Q: The option to create a staging slot is unavailable on your App Service plan. What should you do?**
→ **Scale up** the App Service plan to **Standard, Premium, or Isolated tier**. Deployment slots require Standard tier or higher. Scale Out (more instances) does NOT unlock slots.

**Q: You have App Service Plans: ASP1 (Windows, East US), ASP2 (Linux, West US), ASP3 (Linux, East US). Which plans can host an ASP.NET Core app? Which can host an ASP.NET (classic) app?**
→ **ASP.NET Core**: ASP1 and ASP3 (Core supports both Windows AND Linux). NOT ASP2 (wrong region for the app).
→ **ASP.NET (classic)**: ASP1 only (classic ASP.NET requires **Windows only**; Linux is not supported).
