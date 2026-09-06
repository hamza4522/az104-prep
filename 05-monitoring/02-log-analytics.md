# Log Analytics & KQL

> 🎯 Exam Weight: Part of 10–15% Monitoring domain

---

## 🔑 What is Log Analytics?

- **Centralized log store and query engine** within Azure Monitor
- Collect logs from: Azure resources, VMs, on-premises servers, Kubernetes
- Query logs using **Kusto Query Language (KQL)**
- Foundation for alerts, workbooks, dashboards, and Microsoft Sentinel

---

## 🏛️ Log Analytics Workspace

### What It Is
- Container that **stores log data** (the actual database)
- Has its own **retention settings**
- Can receive data from multiple resources, subscriptions, and regions
- One workspace can serve multiple purposes (cost vs. isolation tradeoff)

### Default Retention
- **30 days** interactive retention (free, queryable)
- Up to **730 days** (2 years) extended retention (additional cost)
- Beyond 730 days → archive to Storage Account

### Workspace Architecture Options
| Architecture | Description | When to Use |
|-------------|-------------|------------|
| **Single workspace** | All logs to one workspace | Simple environments, centralized view |
| **Multiple workspaces** | Separate by region, team, or purpose | Compliance isolation, latency |
| **Dedicated cluster** | For large volumes (>500 GB/day) | High-scale environments |

---

## 📡 Data Sources

### What Can Send Logs
| Source | Agent/Method |
|--------|-------------|
| **Azure VMs (Windows/Linux)** | Azure Monitor Agent (AMA) or Log Analytics Agent (deprecated) |
| **Azure Resources** | Diagnostic Settings |
| **On-premises servers** | Azure Arc + AMA |
| **Azure Kubernetes Service** | Container Insights |
| **Applications** | Application Insights |
| **Security events** | Microsoft Sentinel |

### Azure Monitor Agent (AMA) — New Recommended Agent
- Replaces legacy agents: Log Analytics Agent, Diagnostics Extension, Telegraf
- Configured via **Data Collection Rules (DCR)** instead of workspace settings
- Supports: Windows, Linux, Arc-enabled servers

---

## 🔍 Kusto Query Language (KQL)

### Basic KQL Structure
```kql
TableName
| operator1 arguments
| operator2 arguments
| ...
```

### Common KQL Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `where` | Filter rows | `where Computer == "MyVM"` |
| `project` | Select columns | `project TimeGenerated, Computer, CPU` |
| `summarize` | Aggregate data | `summarize avg(CPU) by Computer` |
| `sort by` / `order by` | Sort results | `sort by TimeGenerated desc` |
| `top` | Get top N rows | `top 10 by CPU` |
| `extend` | Add computed columns | `extend CPUPercent = CPU * 100` |
| `count` | Count rows | `count` |
| `distinct` | Unique values | `distinct Computer` |
| `join` | Join two tables | `join (TableB) on Key` |
| `ago()` | Relative time | `where TimeGenerated > ago(1h)` |
| `bin()` | Round time | `bin(TimeGenerated, 5m)` |

### Common KQL Queries for AZ-104

```kql
// VMs with high CPU (>90%) in last hour
Perf
| where TimeGenerated > ago(1h)
| where CounterName == "% Processor Time"
| where CounterValue > 90
| project TimeGenerated, Computer, CounterValue
| sort by CounterValue desc

// Count events by computer
Event
| where TimeGenerated > ago(24h)
| summarize EventCount = count() by Computer
| sort by EventCount desc

// Find failed logins
SecurityEvent
| where EventID == 4625
| where TimeGenerated > ago(1h)
| summarize FailedLogins = count() by Account, Computer

// Heartbeat - check which agents are connected
Heartbeat
| where TimeGenerated > ago(1h)
| summarize LastHeartbeat = max(TimeGenerated) by Computer
| where LastHeartbeat < ago(15m)  // Find agents not reporting

// Activity Log - find all DELETE operations
AzureActivity
| where OperationNameValue endswith "DELETE"
| where TimeGenerated > ago(7d)
| project TimeGenerated, Caller, ResourceGroup, ResourceId, ActivityStatusValue

// VM available memory
InsightsMetrics
| where TimeGenerated > ago(1h)
| where Name == "AvailableMB"
| summarize avg(Val) by Computer
```

---

## 📊 Common Log Tables

| Table | Contains |
|-------|---------|
| **AzureActivity** | Azure subscription activity log events |
| **Heartbeat** | Agent heartbeat records (VM health) |
| **Event** | Windows event log entries |
| **Syslog** | Linux syslog entries |
| **Perf** | Performance counters (CPU, memory, disk) |
| **SecurityEvent** | Windows security events |
| **AzureMetrics** | Azure resource metrics |
| **InsightsMetrics** | Metrics from Azure Monitor agents |
| **ContainerLog** | AKS container logs |
| **AppRequests** | Application Insights HTTP requests |
| **AppDependencies** | Application Insights dependencies |

---

## 💲 Log Analytics Pricing

| Model | Description |
|-------|-------------|
| **Pay-As-You-Go** | Per GB ingested |
| **Commitment Tier** | Daily commitment (100, 200, 300... GB/day) — cheaper |

> 💡 For large volumes, **Commitment Tiers** are more cost-effective.

### Data Retention Costs
| Period | Cost |
|--------|------|
| 0–30 days | **Free** (included) |
| 31–730 days | Additional per GB/month |
| >730 days | Archive to Storage Account |

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Log query language | **KQL** (Kusto Query Language) |
| Default log retention | **30 days** |
| Max interactive retention | **730 days** |
| Azure Monitor Agent replaces | Log Analytics Agent (MMA/OMS) |
| DCR = | Data Collection Rule |
| Heartbeat table | Agent connectivity check |
| Perf table | Performance counter data |
| AzureActivity table | Subscription control plane logs |

---

## 🚨 Common Exam Scenarios

**Q: You need to query logs from VMs across 3 subscriptions in one place. What do you configure?**
→ Send all logs to a **single Log Analytics workspace** using Diagnostic Settings and Azure Monitor Agent

**Q: You need to find all VMs that haven't sent a heartbeat in the last 15 minutes. What KQL query?**
→ Query the **Heartbeat** table, filter for `LastHeartbeat < ago(15m)`

**Q: Log data needs to be retained for 3 years for compliance. What do you configure?**
→ Set Log Analytics retention to max (730 days), then configure **Data Export** to a **Storage Account** for the remaining period

**Q: Which agent should you deploy on new VMs to collect performance data and events?**
→ **Azure Monitor Agent (AMA)** configured with a **Data Collection Rule (DCR)**
