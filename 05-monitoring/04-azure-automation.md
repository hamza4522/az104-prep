# Azure Automation & Update Management

> 🎯 Exam Weight: Part of 10–15% Monitoring domain

---

## 🔑 What is Azure Automation?

- Cloud-based automation and configuration service
- Automate: repetitive tasks, VM management, patching, deployments
- Key features: **Runbooks, Update Management, Desired State Configuration (DSC), Inventory, Change Tracking**

---

## 📜 Runbooks

### What Are Runbooks?
- Scripts that automate Azure management tasks
- Types of runbooks:

| Type | Language | Use Case |
|------|---------|---------|
| **PowerShell** | PowerShell | Windows-centric automation |
| **PowerShell Workflow** | PowerShell Workflow | Parallel tasks, checkpointing |
| **Python** | Python 2/3 | Python-based automation |
| **Graphical** | Visual designer | Non-coders, simple workflows |
| **Graphical PowerShell Workflow** | Visual designer | Complex workflows visually |

### Runbook Execution
- **Azure sandbox**: Runbooks run in shared Azure infrastructure
- **Hybrid Runbook Worker**: Run on on-prem or Azure VMs for local resource access

```bash
# Create an Automation Account
az automation account create \
  --resource-group myRG \
  --name myAutomationAccount \
  --location eastus \
  --sku Basic

# Import a runbook
az automation runbook create \
  --resource-group myRG \
  --automation-account-name myAutomationAccount \
  --name StartVMs \
  --type PowerShell

# Start a runbook
az automation runbook start \
  --resource-group myRG \
  --automation-account-name myAutomationAccount \
  --name StartVMs
```

### Common Runbook Use Cases
- Start/Stop VMs on a schedule (common cost-saving automation)
- Auto-remediate Azure Monitor alerts (e.g., restart unresponsive VM)
- Apply configurations to new VMs
- Clean up unused resources

---

## 🔧 Hybrid Runbook Worker

- Run runbooks on **on-premises or Azure VMs**
- Access resources not reachable from Azure sandbox (local DB, on-prem systems)
- Install **Hybrid Worker agent** on target machines
- Group workers into **Hybrid Worker Groups**

---

## 🔄 Azure Automation Update Management

### What It Does
- Manage **OS updates** for Windows and Linux VMs
- Works for: Azure VMs, on-premises VMs (via Azure Arc), VMs in other clouds
- Schedule update deployments, view compliance status

### How It Works
1. Connect VMs to a **Log Analytics Workspace**
2. Enable **Update Management** on the workspace
3. View **update compliance** — which VMs are missing updates
4. Schedule **Update Deployment** to install updates

### Update Deployment Settings
| Setting | Description |
|---------|-------------|
| **Schedule** | When to run (one-time or recurring) |
| **Duration** | Max time window for updates (1–6 hours) |
| **Machines** | Specific VMs, groups, or all |
| **Update classifications** | Critical, Security, Update Rollups, etc. |
| **Reboot settings** | Never reboot, if required, always reboot |

> ⚠️ Update Management relies on **Log Analytics Agent** (being replaced by Azure Update Manager)

### Azure Update Manager (New — replacing Update Management)
- Native Azure service, no Log Analytics dependency
- Supports Azure and Arc-enabled machines
- Better compliance reporting

---

## ⚙️ Desired State Configuration (DSC)

### What It Is
- Ensure VMs maintain a **desired configuration** state
- If a VM drifts from the desired state → automatically corrected
- Uses PowerShell DSC scripts

### DSC Modes
| Mode | Description |
|------|-------------|
| **ApplyOnly** | Apply config once, no monitoring |
| **ApplyAndMonitor** | Apply + report drift (no auto-fix) |
| **ApplyAndAutoCorrect** | Apply + auto-fix drift |

---

## 📊 Change Tracking & Inventory

### Change Tracking
- Track changes to: software, Windows services, Linux daemons, registry keys, files
- Stores changes in **Log Analytics**
- Useful for detecting unauthorized changes

### Inventory
- Collect inventory of: installed software, Windows features, Windows services, Linux packages
- View what's installed across all monitored VMs

---

## 📅 Schedules & Webhooks

### Schedules
- Trigger runbooks at specific times (one-time or recurring)
- Time zones supported
- Link schedule to runbook

### Webhooks
- Trigger runbooks via **HTTP POST** from external services
- URL contains authentication token (valid for configurable time)
- Used for alert-triggered automation (e.g., Azure Monitor alert → webhook → runbook)

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Runbook types | PowerShell, Python, Graphical, PowerShell Workflow |
| On-prem runbook execution | **Hybrid Runbook Worker** |
| Update Management requires | **Log Analytics Workspace** |
| DSC auto-fix mode | **ApplyAndAutoCorrect** |
| Webhook triggers | Runbook via HTTP POST |
| Change Tracking stores to | **Log Analytics Workspace** |
| Start/Stop VMs automation | Common use case via runbook + schedule |
| Azure Update Manager | New native service replacing Update Management |

---

## 🚨 Common Exam Scenarios

**Q: VMs need to be automatically shut down at 7PM every day to save costs. What do you configure?**
→ **Azure Automation Runbook** + **Schedule** to stop/deallocate VMs at 7PM daily

**Q: You need to patch 200 on-premises Windows servers on a schedule from Azure. What do you use?**
→ **Azure Automation Update Management** with **Hybrid Runbook Worker** or **Azure Arc** + **Azure Update Manager**

**Q: An alert fires when a VM becomes unresponsive. You want to automatically restart it. What's the integration?**
→ Azure Monitor Alert → **Action Group** with **Automation Runbook** action to restart the VM

**Q: You want to ensure all Windows VMs always have IIS installed. If it's removed, it should be reinstalled automatically. What feature?**
→ **Azure Automation DSC** with **ApplyAndAutoCorrect** mode
