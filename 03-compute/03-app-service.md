# Azure App Service

> 🎯 Exam Weight: Part of 20–25% Compute domain

---

## 🔑 What is Azure App Service?

- **PaaS (Platform as a Service)** for hosting web apps, REST APIs, and mobile backends
- Azure manages: OS, runtime, patching, load balancing, scaling
- You manage: your application code and configuration
- Supports: .NET, Java, Python, Node.js, PHP, Ruby, Docker containers

---

## 🏗️ App Service Plan

### What is an App Service Plan?
- Defines the **compute resources** (VMs) for your app
- Apps in the same plan **share the same resources**
- The plan determines: region, VM size, pricing tier, scaling

### App Service Plan Tiers

| Tier | Category | Features |
|------|----------|---------|
| **Free (F1)** | Shared | 60 CPU min/day, no SLA, no custom domain |
| **Shared (D1)** | Shared | Custom domain, shared compute |
| **Basic (B1, B2, B3)** | Dedicated | Custom domain + SSL, manual scale up to 3 instances |
| **Standard (S1, S2, S3)** | Dedicated | Auto-scale, deployment slots, Azure Traffic Manager |
| **Premium (P1v2 – P3v3)** | Dedicated | Enhanced auto-scale, VNet integration, more instances |
| **Isolated (I1 – I3)** | Isolated | Dedicated VNet (App Service Environment), highest scale |

> ⚠️ **Deployment Slots** require **Standard** tier or higher.
> ⚠️ **VNet Integration** requires **Standard** tier or higher.

---

## 🔄 Deployment Slots

### What Are Deployment Slots?
- **Separate environments** (staging, dev, QA) within the same App Service
- Each slot has its own URL (e.g., myapp-staging.azurewebsites.net)
- **Swap** slots to deploy to production without downtime
- During swap: slot configurations are swapped, serving requests from target slot

### Swap Process
1. **Staging** slot → test your new code
2. **Swap** → staging and production exchange
3. If issues: **swap back** (rollback in seconds)

### Sticky Settings (Slot-Specific Settings)
- Connection strings and app settings can be marked as **slot-specific**
- They stay with the slot when swapping — e.g., staging uses staging database
- Non-sticky settings **swap** along with the code

### Default Slots
- **Production** slot is always present
- Standard plan: up to **5 slots**
- Premium plan: up to **20 slots**

---

## ⬆️ Auto-Scaling

### Scale Out (Horizontal)
- Add more instances of your app
- Metric-based: CPU, memory, HTTP queue length
- Schedule-based: scale up at 9am, scale down at 6pm

### Scale Up (Vertical)  
- Move to larger plan tier
- No downtime for most operations

---

## 🌐 App Service Networking

### Inbound Features
| Feature | Description |
|---------|-------------|
| **App-assigned address** | Dedicated inbound IP |
| **Access restrictions** | IP-based firewall rules |
| **Service endpoints** | Restrict to VNet traffic |
| **Private endpoints** | Private IP in VNet |

### Outbound Features
| Feature | Description |
|---------|-------------|
| **VNet Integration** | App accesses resources in VNet |
| **Hybrid Connections** | Access on-premises resources via relay |
| **Gateway-required VNet integration** | Access on-prem via VPN Gateway |

---

## 🔒 Authentication & Authorization (Easy Auth)

- Built-in authentication — **no code changes** needed
- Supports: Azure AD, Microsoft, Google, Facebook, Twitter, GitHub
- Configuration: Authentication blade in App Service
- Unauthenticated requests: Redirect to login or return 401/403

---

## 📦 Deployment Methods

| Method | Description |
|--------|-------------|
| **Git deployment** | Push to Azure Git repo or GitHub |
| **ZIP deploy** | Upload zip file via Kudu or CLI |
| **Docker** | Deploy containerized app |
| **FTP** | Legacy method |
| **Visual Studio** | Direct publish |
| **Azure DevOps** | CI/CD pipeline |

```bash
# Deploy from local Git
az webapp deployment source config-local-git \
  --name myapp \
  --resource-group myRG

# Deploy a ZIP file
az webapp deploy \
  --resource-group myRG \
  --name myapp \
  --src-path app.zip \
  --type zip
```

---

## 🔧 App Settings & Connection Strings

- Stored as **environment variables** at runtime
- Override values in Web.config or appsettings.json
- Can be stored in **Azure Key Vault** (reference: `@Microsoft.KeyVault(...)`)
- **Slot-specific**: Mark settings to not swap between slots

---

## 📊 Monitoring & Diagnostics

### Application Insights
- APM (Application Performance Monitoring) for App Service
- Track requests, dependencies, exceptions, custom events
- Enable in the App Service blade (one-click integration)

### Diagnostic Logs
| Log Type | Platform | Description |
|----------|---------|-------------|
| **Application logging** | Windows/Linux | App-generated log messages |
| **Web server logging** | Windows | Raw HTTP request logs |
| **Error pages** | Windows | ASP.NET error details |
| **Failed request tracing** | Windows | Detailed IIS logs |
| **Deployment logging** | Both | Deployment activity logs |

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| App Service Plan = | Compute resources shared by apps |
| Free tier limitation | 60 CPU min/day, no SLA |
| Deployment slots require | **Standard** tier or higher |
| Max slots (Standard) | **5** |
| Max slots (Premium) | **20** |
| VNet integration requires | **Standard** tier or higher |
| Isolated tier runs in | **App Service Environment (ASE)** |
| Auto-scale available | **Standard** and higher |
| Easy Auth = | Built-in authentication, no code changes |
| Slot swap = | Zero-downtime deployment |

---

## 🚨 Common Exam Scenarios

**Q: A company wants zero-downtime deployments for their web app. What do they configure?**
→ **Deployment slots** — deploy to staging, test, then swap to production

**Q: A web app needs to connect to a SQL database in a private VNet. What feature?**
→ **VNet Integration** (requires Standard tier or higher)

**Q: You need to host 5 separate web apps as cheaply as possible with auto-scaling. What do you use?**
→ One **Standard App Service Plan** with all 5 apps (they share the same resources)

**Q: A web app's staging slot uses a staging database. After a swap, the production slot should still use the production database. What do you configure?**
→ Mark the connection string as **slot-specific** (sticky) so it doesn't swap

**Q: Which App Service plan tier provides the highest level of isolation and scale?**
→ **Isolated** tier (runs in App Service Environment — dedicated VNet)
