# Azure Monitor

> 🎯 Exam Weight: Part of 10–15% Monitoring domain

---

## 🔑 What is Azure Monitor?

- **Centralized monitoring platform** for all Azure resources
- Collects: metrics, logs, traces, and activity logs
- Provides: dashboards, alerts, autoscale, workbooks, insights

### Azure Monitor Data Types
| Type | Description | Storage |
|------|-------------|---------|
| **Metrics** | Numerical time-series data (CPU%, requests/sec) | Azure Monitor Metrics database |
| **Logs** | Text-based records, structured (JSON) | Log Analytics Workspace |
| **Activity Log** | Subscription-level operations (who did what, when) | Azure Monitor (90 days), can archive |
| **Resource Logs** | Diagnostic logs from Azure resources | Log Analytics, Storage, Event Hub |

---

## 📊 Azure Monitor Metrics

### What Are Metrics?
- **Numerical values** collected at regular intervals
- Examples: CPU percentage, disk IOPS, network in/out, request count
- Retained for **93 days** in Azure Monitor
- For longer retention → send to **Log Analytics**

### Key Metrics Tools
| Tool | Description |
|------|-------------|
| **Metrics Explorer** | Visualize metrics, create charts |
| **Metric Alerts** | Alert when metric exceeds threshold |
| **Autoscale** | Scale resources based on metrics |

### Platform Metrics vs Custom Metrics
| Type | Description |
|------|-------------|
| **Platform metrics** | Automatically collected from Azure resources (no config) |
| **Custom metrics** | Application-defined metrics sent via API or Application Insights |

---

## 📋 Activity Log

### What It Is
- Records **control plane operations** on Azure resources
- Answers: Who did what, on which resource, when
- Retained for **90 days** by default in Azure Monitor
- Archive to Storage Account or send to Log Analytics for longer retention

### Activity Log Event Categories
| Category | Description |
|----------|-------------|
| **Administrative** | Create, update, delete, action operations |
| **Security** | Azure Defender alerts |
| **ServiceHealth** | Azure service incidents |
| **ResourceHealth** | Resource health changes |
| **Alert** | Azure Monitor alerts firing |
| **Autoscale** | Autoscale actions |
| **Policy** | Azure Policy evaluation results |
| **Recommendation** | Advisor recommendations |

### Common Activity Log Query
```kql
// Find all delete operations in last 24 hours
AzureActivity
| where OperationNameValue endswith "DELETE"
| where TimeGenerated > ago(24h)
| project TimeGenerated, Caller, ResourceGroup, Resource, ActivityStatusValue
```

---

## 🔍 Diagnostic Settings

### What Are They?
- Configure **where resource logs and metrics are sent**
- Must be configured on each resource (not automatic for logs)
- Destinations:
  | Destination | Use Case |
  |-------------|---------|
  | **Log Analytics Workspace** | Query, alert, long-term analysis |
  | **Storage Account** | Archive, compliance |
  | **Event Hub** | Stream to SIEM or external tools |
  | **Azure Monitor Partner** | Third-party integrations |

```bash
# Create diagnostic setting for a VM (send to Log Analytics)
az monitor diagnostic-settings create \
  --name myDiagSettings \
  --resource {vm-resource-id} \
  --workspace {log-analytics-workspace-id} \
  --metrics '[{"category":"AllMetrics","enabled":true}]' \
  --logs '[{"category":"Administrative","enabled":true}]'
```

---

## 📈 Azure Monitor Workbooks

- **Interactive reports** combining text, queries, metrics, and parameters
- Create custom dashboards for stakeholders
- Templates available for common scenarios

---

## 🔍 Application Insights

### What It Is
- APM (Application Performance Monitoring) service
- Monitor your **application code** (not just infrastructure)
- Part of Azure Monitor

### What It Tracks
| Data | Description |
|------|-------------|
| **Requests** | HTTP requests, response times, failure rates |
| **Dependencies** | Calls to databases, external APIs, storage |
| **Exceptions** | Unhandled exceptions and stack traces |
| **Page views** | Client-side telemetry |
| **Custom events** | Application-specific events |
| **Performance counters** | Server-side CPU, memory |

### Application Map
- Visual diagram of application components and their dependencies
- Shows where failures and slowdowns occur

### Live Metrics
- Real-time stream of application telemetry
- Instant view of requests, failures, CPU

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Metrics retention | **93 days** in Azure Monitor |
| Activity Log retention | **90 days** by default |
| Logs stored in | **Log Analytics Workspace** |
| Diagnostic settings configure | Where resource logs are sent |
| Activity Log captures | Control plane operations (who did what) |
| Application Insights for | **Application-level** monitoring |
| Custom metrics | Sent via API or Application Insights SDK |
| Metrics Explorer for | Visualizing numerical metrics |

---

## 🚨 Common Exam Scenarios

**Q: An admin accidentally deleted a resource group. How do you find out who did it and when?**
→ **Activity Log** — search for DELETE operations on the resource group

**Q: You need to keep VM performance metrics for 2 years for compliance. What do you configure?**
→ Send metrics via **Diagnostic Settings** to a **Storage Account** (metrics only retained 93 days in Monitor natively)

**Q: An application is experiencing slowdowns. You need to see which database calls are taking too long. What do you use?**
→ **Application Insights** — dependency tracking shows slow database calls

**Q: You want to create a custom dashboard showing CPU and memory metrics across 50 VMs in one view. What do you use?**
→ **Azure Monitor Workbooks** or **Azure Dashboards** using Metrics Explorer pinned charts
