# Azure Monitor & Activity Log

> 🎯 Exam Weight: Part of 10–15% Monitoring domain

---

## 🔑 Azure Monitor Data Platform

```
[Sources: Apps, VMs, OS, Resources, Subscriptions, Tenant]
                             │
                             ▼
                    [Azure Monitor Engine]
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
      [Metrics]                            [Logs]
  Lightweight numbers               Structured records & events
  Time-series DB                    Log Analytics (KQL)
  Retained: 93 days                 Retained: 30–730 days
```

---

## 📜 Azure Activity Log (Subscription Control Plane)

- Automatically records **control-plane events** across the entire subscription:
  - Who created, updated, or deleted a resource
  - When a virtual machine was started, stopped, or restarted
  - Modifications to Network Security Groups, Route Tables, and RBAC roles
- **Retention**: **90 days** of history included free of charge
- **Long-Term Retention Requirement**:
  - To retain Activity Logs for > 90 days (e.g. 1 year, 7 years for compliance): Create a **Diagnostic Setting** on the Activity Log and export to an **Azure Storage Account** or **Log Analytics Workspace**.

---

## ⚙️ Diagnostic Settings (Resource Logs & Metrics)

Platform logs are not collected until a **Diagnostic Setting** is configured on the resource.
Supported Destinations:
1. **Log Analytics Workspace**: For querying with KQL and creating complex log search alerts.
2. **Azure Storage Account**: For low-cost long-term archival and compliance auditing.
3. **Event Hub**: For real-time streaming into third-party SIEM tools (Splunk, QRadar, Datadog).
4. **Partner Solutions**: Direct ingestion into Azure native partner ISVs.

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Activity Log default retention | **90 days** (included free) |
| Metrics default retention | **93 days** |
| Retaining Activity Logs for 1+ years | Configure **Diagnostic Setting** to Azure Storage Account |
| View who deleted a resource | **Activity Log** |
| Export destination for SIEM streaming | **Azure Event Hub** |

---

## 🔗 Network Performance Monitor (NPM)

- Cloud-based **hybrid network monitoring** solution in Azure Monitor
- Monitors network performance between points in your network infrastructure:
  - Between **on-premises datacenter and Azure VMs**
  - Between branch offices and multi-tier applications
  - ExpressRoute performance monitoring
- Used to **detect network issues before users complain**

> 💡 **Exam Tip**: To monitor **latency between an on-premises network and Azure VMs**, use **Network Performance Monitor** (not "Connection Troubleshoot" which is for specific VM-to-endpoint testing).

---

## 📱 App Service Diagnostics Logging

| Log Type | Enables | Use Case |
|----------|---------|----------|
| **Web server logging** | Raw HTTP request/response logs | Diagnose **HTTP 500**, 404, connectivity errors |
| **Application logging** | App-generated trace messages | Debug application code errors |
| **Detailed error messages** | Error page HTML for failed requests | View exact error for 400+ status codes |

> 💡 **Exam Gotcha (Q9)**: To provide developers real-time details of HTTP 500 connection errors on a Web App → Enable **Web server logging** (not "Application Logging" which is for app code).

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: A virtual machine was accidentally deleted last night. You need to identify which administrator initiated the deletion operation.**
→ Open the Azure **Activity Log**, filter the operation by "Delete Virtual Machine", and review the **Event initiated by** field.

**Q: An organization's compliance policy requires all subscription activity events to be retained for at least 365 days.**
→ Create a **Diagnostic Setting** for the Activity Log and configure an **Azure Storage Account** as the export destination with a retention of 365 days.

**Q: You need to monitor the latency between your on-premises network and 10 Azure virtual machines.**
→ Use **Network Performance Monitor** in Azure Monitor — it is designed for cloud-based hybrid network monitoring.

**Q: Users report HTTP 500 errors on webapp1. You need to provide developers real-time access to connection error details.**
→ From webapp1 settings, enable **Web server logging** (not Application Logging).
