# Azure Automation & Runbooks

> 🎯 Exam Weight: Part of 10–15% Monitoring domain

---

## 🔑 What is Azure Automation?

- Cloud automation, process orchestration, and configuration management service
- Saves operational costs by automating routine, repetitive tasks (e.g. auto-stopping VMs at night)

---

## 📜 Runbooks & Execution Models

| Runbook Type | Language / Format | Complexity |
|--------------|-------------------|------------|
| **PowerShell** | Standard PowerShell script (`.ps1`) | Low / Medium |
| **PowerShell Workflow** | PowerShell workflow (supports checkpointing) | Medium / High |
| **Graphical** | Visual drag-and-drop designer | Low |
| **Python** | Python 2 or Python 3 scripts | Medium |

### Triggers
- **Schedules**: Hourly, daily, weekly, or one-time execution.
- **Webhooks**: Starts a runbook via an external HTTP POST request with JSON payload.
- **Alerts**: Triggered via an Action Group.

---

## 🏢 Hybrid Runbook Worker

- Executes runbooks **directly on on-premises computers** or machines in AWS/GCP
- Overcomes cloud-to-on-prem network barriers: runbooks run locally behind your corporate firewall to manage local Active Directory, files, or hardware!

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Execute runbook on on-premises machines | Deploy a **Hybrid Runbook Worker** |
| Trigger runbook via external HTTP POST | Configure a **Webhook** |
| Stop/Start VMs on schedule to save costs | **Azure Automation** with Schedule |
| Runbook authentication | Managed Identity (System-assigned or User-assigned) |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You need to run an automation script that creates Active Directory user accounts on an on-premises domain controller whenever a new employee is hired.**
→ Deploy an Azure Automation **Hybrid Runbook Worker** on a server on the on-premises network, and target the runbook to run on the Hybrid Worker group.

---

## 🔗 IT Service Management Connector (ITSM)

Connects Azure Monitor alerts to an on-premises **ITSM tool** (e.g., Microsoft System Center Service Manager, ServiceNow, Cherwell, Provance):

| Feature | Details |
|---------|---------|
| **Full name** | IT Service Management Connector (ITSMC) |
| **Supported ITSM tools** | Microsoft System Center Service Manager, ServiceNow, Cherwell, Provance |
| **What it does** | Creates work items (incidents, change requests) in the ITSM tool based on Azure alerts |
| **Alert types supported** | Metric alerts, Activity Log alerts, Log Analytics alerts |
| **Requirement** | Must be deployed FIRST before creating ITSM-based notification actions in Action Groups |

> 💡 **Exam Tip (Q15)**: To set an alert in Service Manager when Azure VM memory falls below 10% → **Deploy the IT Service Management Connector (ITSM)** first, then configure the alert rule and action group.

**Q: You need to ensure that an alert is set in Microsoft System Center Service Manager when the available memory on VM1 is below 10%. What should you do first?**
→ Deploy the **IT Service Management Connector (ITSMC)** to connect Azure Monitor with Service Manager. Then create the alert rule targeting the memory metric on VM1.
