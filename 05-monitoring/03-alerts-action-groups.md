# Alerts & Action Groups

> 🎯 Exam Weight: Part of 10–15% Monitoring domain

---

## 🔑 What are Azure Monitor Alerts?

- Proactively **notify you** when conditions in your Azure environment are met
- Based on: metrics, logs, activity logs, or availability
- Alert → triggers **Action Group** to send notifications or run automated responses

---

## 🏗️ Alert Components

```
Alert Rule = Signal + Condition + Action Group
              (what to    (threshold   (what to do
               monitor)    or query)    when fired)
```

### Signal Types
| Signal Type | Source | Examples |
|-------------|--------|---------|
| **Metric** | Azure Monitor Metrics | CPU > 80%, requests/sec > 1000 |
| **Log** | Log Analytics query | Error count > 5 in 5 mins |
| **Activity Log** | Azure Activity Log | Resource deleted, VM stopped |
| **Resource health** | Azure Resource Health | VM becomes unavailable |

---

## 📋 Alert Rule Configuration

### Key Settings
| Setting | Description |
|---------|-------------|
| **Target scope** | Resource, resource group, or subscription |
| **Condition** | Signal + threshold + evaluation period |
| **Action group** | What to do when alert fires |
| **Severity** | 0 (Critical) to 4 (Verbose) |
| **Alert rule state** | Enabled or disabled |
| **Auto-resolve** | Alert resolves when condition no longer met |

### Alert Severity Levels
| Severity | Name | Use Case |
|----------|------|---------|
| **Sev 0** | Critical | Service outage |
| **Sev 1** | Error | Major issue |
| **Sev 2** | Warning | Potential issue |
| **Sev 3** | Informational | Non-urgent info |
| **Sev 4** | Verbose | Detailed debugging |

---

## 📣 Action Groups

### What Are Action Groups?
- Defines **what to do** when an alert fires
- Reusable — same action group can be used by multiple alert rules
- Can have **multiple actions** in one group

### Action Types
| Action Type | Description |
|-------------|-------------|
| **Email/SMS/Push/Voice** | Notify people |
| **Azure Function** | Trigger serverless function |
| **Logic App** | Trigger an automated workflow |
| **Webhook** | Call an HTTP endpoint |
| **ITSM** | Create ticket in ServiceNow, etc. |
| **Automation Runbook** | Run Azure Automation runbook |
| **Arm Template** | Deploy/modify resources |
| **Event Hub** | Stream alert to Event Hub |

### Creating Action Groups
```bash
# Create an action group with email notification
az monitor action-group create \
  --resource-group myRG \
  --name myActionGroup \
  --short-name myAG \
  --action email myEmail admin@contoso.com
```

---

## ⚡ Metric Alerts

### Static Threshold Alert
- Alert when metric exceeds a fixed value
- Example: Alert when CPU > 85% for 5 minutes

### Dynamic Threshold Alert
- Uses **machine learning** to calculate thresholds based on historical data
- Automatically adapts to patterns (daily/weekly seasonality)
- Better for metrics with natural variation

### Metric Alert Configuration
```bash
# Create a metric alert (CPU > 80%)
az monitor metrics alert create \
  --name "HighCPU" \
  --resource-group myRG \
  --scopes {vm-resource-id} \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action myActionGroup \
  --severity 2
```

---

## 📝 Log Alerts

### What Are They?
- Run a **KQL query** on Log Analytics on a schedule
- Alert when query returns results or meets a threshold
- More complex but more powerful than metric alerts

### Example Log Alert Rule
```kql
// Alert if more than 5 login failures in 15 minutes
SecurityEvent
| where EventID == 4625
| where TimeGenerated > ago(15m)
| summarize Count = count()
| where Count > 5
```

### Log Alert Configuration
```bash
# Create a log alert
az monitor scheduled-query create \
  --resource-group myRG \
  --name "LoginFailures" \
  --scopes {workspace-resource-id} \
  --condition-query "SecurityEvent | where EventID == 4625 | summarize Count=count() | where Count > 5" \
  --condition-threshold 0 \
  --condition-time-aggregation Count \
  --evaluation-frequency 5m \
  --window-duration 15m \
  --severity 2 \
  --action-groups myActionGroup
```

---

## 📅 Activity Log Alerts

### What Are They?
- Alert on **operations recorded in the Activity Log**
- Examples:
  - Someone deletes a resource group
  - A VM is stopped
  - A policy assignment is created
  - Service health incident affects your region

### Common Activity Log Alert Scenarios
```bash
# Alert when any resource in a resource group is deleted
az monitor activity-log alert create \
  --name "ResourceDeleted" \
  --resource-group myRG \
  --scope /subscriptions/{sub-id}/resourceGroups/myRG \
  --condition category=Administrative operationName=Microsoft.Resources/resourceGroups/delete \
  --action-group myActionGroup
```

---

## 🩺 Azure Resource Health

- Monitors the **health of Azure resources** (not your applications)
- Notifies when Azure infrastructure issues affect your resources
- Statuses: Available, Degraded, Unavailable, Unknown
- Set up **Resource Health Alerts** via Activity Log alerts

---

## 🔔 Smart Groups

- **AI-grouping** of related alerts into one smart group
- Reduces alert noise — related alerts appear as one item
- Available in Azure Monitor Alerts blade
- Helps identify root cause across many individual alerts

---

## 📊 Alert Processing Rules

- Apply actions (suppress, change action group) to **multiple alert rules**
- Use cases:
  - **Suppress alerts** during maintenance windows
  - Apply the same action group to all alerts in a resource group
  - Add on-call contact to all critical alerts

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Alert components | Signal + Condition + **Action Group** |
| Severity 0 | **Critical** |
| Severity 4 | **Verbose** |
| Action group can have | **Multiple actions** |
| Same action group | Can be used by **multiple alert rules** |
| Dynamic thresholds | Use **ML** to adapt to patterns |
| Log alerts run | **KQL queries** on a schedule |
| Activity log alerts | Trigger on control plane operations |
| Smart groups | AI-grouped related alerts |
| Alert processing rules | Suppress or modify alerts in bulk |

---

## 🚨 Common Exam Scenarios

**Q: You want to be notified when any resource in a subscription is deleted. What do you configure?**
→ **Activity Log Alert** scoped to subscription, condition: operation = DELETE

**Q: Multiple teams need different notifications (email for team A, SMS for team B) for the same alert. What do you configure?**
→ Create **two action groups** (one per team), assign both to the same alert rule

**Q: During a scheduled maintenance window, you don't want alerts firing. What do you configure?**
→ **Alert Processing Rules** with a suppression rule for the maintenance window time period

**Q: A metric shows irregular patterns at different times of day. You want alerts that adapt automatically. What type of alert?**
→ **Dynamic threshold metric alert** — adapts to historical patterns automatically

**Q: You want to automatically restart a VM when it becomes unresponsive (high CPU for 5 minutes). What do you configure?**
→ Create a **metric alert** for CPU > 95% → action group with an **Automation Runbook** to restart the VM
