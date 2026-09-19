# Log Analytics & KQL

> 🎯 Exam Weight: Part of 10–15% Monitoring domain

---

## 🔑 Log Analytics Workspaces

- Centralized repository for log data collected from Azure Monitor, VMs, and PaaS services
- **Data Retention**:
  - Configurable from **30 to 730 days** (default is 30 days)
  - Interactive retention vs long-term archive tier (up to 12 years)

---

## 🔍 Essential KQL (Kusto Query Language) Queries Tested on Exam

### 1. Identify Inactive or Offline VMs (Heartbeat Query)
```kql
// Find VMs that have not sent a heartbeat in the last 1 hour
Heartbeat
| summarize LastHeartbeat = max(TimeGenerated) by Computer
| where LastHeartbeat < ago(1h)
```

### 2. Query Windows / Linux Error Events
```kql
// Find critical or error event logs grouped by source
Event
| where EventLevelName in ("Error", "Critical")
| summarize ErrorCount = count() by Source, Computer
| order by ErrorCount desc
```

### 3. Track Deleted Resources from Activity Log
```kql
AzureActivity
| where OperationNameValue endswith "delete" and ActivityStatusValue == "Success"
| project TimeGenerated, Caller, ResourceGroup, Resource
```

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Default Log Analytics retention | **30 days** |
| Max interactive retention | **730 days** (2 years) |
| Agent for modern VM telemetry | **Azure Monitor Agent (AMA)** with Data Collection Rules (DCR) |
| Heartbeat table use case | Verifying agent health and VM availability |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You need to generate a list of all virtual machines that failed to report a heartbeat in the last 60 minutes.**
→ In Log Analytics, query the `Heartbeat` table, summarize by `max(TimeGenerated)` per computer, and filter where `LastHeartbeat < ago(1h)`.

**Q: You need to increase the log retention period of a Log Analytics workspace from 30 days to 180 days.**
→ Open the Log Analytics workspace blade, select **Usage and estimated costs** > **Data Retention**, and set the slider to 180 days.
