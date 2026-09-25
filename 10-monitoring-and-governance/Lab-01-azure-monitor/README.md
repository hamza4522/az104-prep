# 📊 Lab 01 — Azure Monitor: Metrics, Alerts & Dashboards

**Difficulty:** 🟢 Beginner  
**Time:** 60 minutes  
**Goal:** Set up comprehensive monitoring with Azure Monitor — the AWS CloudWatch equivalent

---

## Part 1 — Azure Monitor Basics

```bash
RG="rg-monitoring-lab"
LOCATION="eastus"

az group create --name $RG --location $LOCATION

# Create a Log Analytics Workspace (central log repository)
# Like AWS CloudWatch Log Groups + Logs Insights
WORKSPACE_NAME="law-monitoring-$(date +%s)"

az monitor log-analytics workspace create \
  --resource-group $RG \
  --workspace-name $WORKSPACE_NAME \
  --location $LOCATION \
  --sku PerGB2018 \
  --retention-time 90 \
  --tags Environment=Lab

WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RG \
  --workspace-name $WORKSPACE_NAME \
  --query id \
  --output tsv)

echo "✅ Log Analytics Workspace: $WORKSPACE_NAME"
echo "Workspace ID: $WORKSPACE_ID"

# List workspaces
az monitor log-analytics workspace list \
  --resource-group $RG \
  --output table
```

---

## Part 2 — Enable Diagnostic Settings

```bash
# =========================================
# Enable diagnostics for a VM
# Like enabling CloudWatch agent / Detailed monitoring in AWS
# =========================================

# First create a VM for monitoring
az vm create \
  --resource-group $RG \
  --name vm-monitored \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys

VM_ID=$(az vm show --resource-group $RG --name vm-monitored --query id --output tsv)

# Install Azure Monitor Agent (AMA) on the VM
# This replaces the old Log Analytics agent (MMA)
az vm extension set \
  --resource-group $RG \
  --vm-name vm-monitored \
  --name AzureMonitorLinuxAgent \
  --publisher Microsoft.Azure.Monitor \
  --version 1.0 \
  --enable-auto-upgrade true

# Create Data Collection Rule (DCR) — defines what to collect and where to send
cat > dcr-linux.json << EOF
{
  "location": "$LOCATION",
  "properties": {
    "dataSources": {
      "performanceCounters": [
        {
          "name": "VMInsightsPerfCounters",
          "streams": ["Microsoft-InsightsMetrics"],
          "samplingFrequencyInSeconds": 60,
          "counterSpecifiers": [
            "\\\\Processor Information(_Total)\\\\% Processor Time",
            "\\\\Processor Information(_Total)\\\\% User Time",
            "\\\\Processor Information(_Total)\\\\% Privileged Time",
            "\\\\Memory\\\\% Committed Bytes In Use",
            "\\\\Memory\\\\Available MB",
            "\\\\Memory\\\\Committed MB",
            "\\\\LogicalDisk(*)\\\\% Free Space",
            "\\\\LogicalDisk(*)\\\\Disk Read Bytes/sec",
            "\\\\LogicalDisk(*)\\\\Disk Write Bytes/sec",
            "\\\\Network Interface(*)\\\\Bytes Total/sec"
          ]
        }
      ],
      "syslog": [
        {
          "name": "syslog-data",
          "streams": ["Microsoft-Syslog"],
          "facilityNames": ["kern", "user", "daemon", "cron", "syslog", "local0"],
          "logLevels": ["Error", "Critical", "Alert", "Emergency"]
        }
      ]
    },
    "destinations": {
      "logAnalytics": [
        {
          "workspaceResourceId": "$WORKSPACE_ID",
          "name": "la-destination"
        }
      ]
    },
    "dataFlows": [
      {
        "streams": ["Microsoft-InsightsMetrics"],
        "destinations": ["la-destination"]
      },
      {
        "streams": ["Microsoft-Syslog"],
        "destinations": ["la-destination"]
      }
    ]
  }
}
EOF

# Create the DCR
az monitor data-collection rule create \
  --resource-group $RG \
  --name "dcr-linux-monitoring" \
  --location $LOCATION \
  --rule-file dcr-linux.json

DCR_ID=$(az monitor data-collection rule show \
  --resource-group $RG \
  --name "dcr-linux-monitoring" \
  --query id \
  --output tsv)

# Associate DCR with VM
az monitor data-collection rule association create \
  --name "dcr-vm-association" \
  --resource $VM_ID \
  --data-collection-rule-id $DCR_ID

# Enable diagnostic settings for Azure resources
# (Sends Azure platform metrics/logs to Log Analytics)

# For Storage Account
STORAGE_NAME="stlab$(date +%s)"
az storage account create \
  --resource-group $RG \
  --name $STORAGE_NAME \
  --location $LOCATION \
  --sku Standard_LRS

STORAGE_ID=$(az storage account show \
  --resource-group $RG \
  --name $STORAGE_NAME \
  --query id \
  --output tsv)

az monitor diagnostic-settings create \
  --name "diag-storage-to-law" \
  --resource $STORAGE_ID \
  --workspace $WORKSPACE_ID \
  --logs '[{"category":"StorageRead","enabled":true},{"category":"StorageWrite","enabled":true},{"category":"StorageDelete","enabled":true}]' \
  --metrics '[{"category":"Transaction","enabled":true}]'

echo "✅ Diagnostic settings configured"
```

---

## Part 3 — Azure Monitor Alerts

```bash
# =========================================
# Create Action Group (notification channels)
# Like SNS Topic in AWS
# =========================================

az monitor action-group create \
  --resource-group $RG \
  --name "ag-devops-team" \
  --short-name "devops" \
  --action email devops-lead devops-lead@company.com \
  --action email oncall-engineer oncall@company.com

# Get action group ID
ACTION_GROUP_ID=$(az monitor action-group show \
  --resource-group $RG \
  --name "ag-devops-team" \
  --query id \
  --output tsv)

# =========================================
# Create Metric Alerts (like CloudWatch Metric Alarms)
# =========================================

# Alert: VM CPU > 80% for 5 minutes
az monitor metrics alert create \
  --resource-group $RG \
  --name "alert-vm-high-cpu" \
  --scopes $VM_ID \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --description "VM CPU utilization above 80%" \
  --action $ACTION_GROUP_ID

# Alert: VM CPU < 5% for 30 minutes (under-utilized)
az monitor metrics alert create \
  --resource-group $RG \
  --name "alert-vm-low-cpu" \
  --scopes $VM_ID \
  --condition "avg Percentage CPU < 5" \
  --window-size 30m \
  --evaluation-frequency 5m \
  --severity 4 \
  --description "VM may be over-provisioned"

# Alert: Available memory < 500MB
az monitor metrics alert create \
  --resource-group $RG \
  --name "alert-vm-low-memory" \
  --scopes $VM_ID \
  --condition "avg Available Memory Bytes < 524288000" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 1 \
  --description "VM memory is critically low" \
  --action $ACTION_GROUP_ID

# Alert: Storage account throttling
az monitor metrics alert create \
  --resource-group $RG \
  --name "alert-storage-throttling" \
  --scopes $STORAGE_ID \
  --condition "total Transactions where ResponseType equals ClientThrottlingError > 10" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --description "Storage account being throttled" \
  --action $ACTION_GROUP_ID

# List all alerts
az monitor metrics alert list \
  --resource-group $RG \
  --output table
```

### Log-based Alerts (KQL)

```bash
# =========================================
# Create Log Alert (query-based)
# Like CloudWatch Logs Metric Filter + Alarm
# =========================================

# Alert: Error rate high in application logs
az monitor scheduled-query create \
  --resource-group $RG \
  --name "alert-app-errors" \
  --scopes $WORKSPACE_ID \
  --condition "count > 10" \
  --condition-query "AppExceptions | where TimeGenerated > ago(5m) | summarize count()" \
  --evaluation-frequency 5m \
  --window-size 5m \
  --severity 2 \
  --description "High error rate detected in application" \
  --action-groups $ACTION_GROUP_ID

# Alert: Failed logins (security)
az monitor scheduled-query create \
  --resource-group $RG \
  --name "alert-failed-logins" \
  --scopes $WORKSPACE_ID \
  --condition "count > 5" \
  --condition-query "SecurityEvent | where EventID == 4625 | where TimeGenerated > ago(10m) | summarize count()" \
  --evaluation-frequency 5m \
  --window-size 10m \
  --severity 1 \
  --description "Multiple failed login attempts detected" \
  --action-groups $ACTION_GROUP_ID
```

---

## Part 4 — KQL (Kusto Query Language) Essentials

> KQL is the query language for Azure Log Analytics  
> Similar to: SQL / CloudWatch Logs Insights / GCP Logging

```kql
// =========================================
// BASIC KQL SYNTAX
// =========================================

// Select all from a table (last 30 min default)
Heartbeat
| take 100

// Filter with where
Heartbeat
| where TimeGenerated > ago(1h)
| where Computer == "vm-monitored"

// Project (select specific columns — like SELECT col FROM)
Heartbeat
| where TimeGenerated > ago(1h)
| project TimeGenerated, Computer, OSType, Category

// Summarize (aggregate — like GROUP BY)
Heartbeat
| where TimeGenerated > ago(24h)
| summarize count() by Computer, bin(TimeGenerated, 1h)

// =========================================
// VM PERFORMANCE QUERIES
// =========================================

// CPU utilization last 1 hour
InsightsMetrics
| where TimeGenerated > ago(1h)
| where Name == "UtilizationPercentage"
| summarize avg(Val) by bin(TimeGenerated, 5m), Computer
| render timechart

// Memory available
InsightsMetrics
| where TimeGenerated > ago(1h)
| where Name == "AvailableMB"
| summarize avg(Val) by bin(TimeGenerated, 5m), Computer
| render timechart

// Disk I/O
InsightsMetrics
| where TimeGenerated > ago(1h)
| where Name in ("ReadBytesPerSecond", "WriteBytesPerSecond")
| summarize avg(Val) by bin(TimeGenerated, 5m), Computer, Name
| render timechart

// Top 10 processes by CPU
InsightsMetrics
| where TimeGenerated > ago(30m)
| where Name == "UtilizationPercentage"
| top 10 by Val desc
| project TimeGenerated, Computer, Val

// =========================================
// SECURITY QUERIES
// =========================================

// Failed logins
SecurityEvent
| where TimeGenerated > ago(24h)
| where EventID == 4625  // Failed logon
| summarize FailedAttempts=count() by Account, IpAddress, Computer
| sort by FailedAttempts desc

// Successful logins from unusual locations
SigninLogs
| where TimeGenerated > ago(24h)
| where ResultType == 0  // Success
| project TimeGenerated, UserPrincipalName, Location, IPAddress, ClientAppUsed
| sort by TimeGenerated desc

// New user created
AuditLogs
| where TimeGenerated > ago(7d)
| where OperationName == "Add user"
| project TimeGenerated, InitiatedBy, TargetResources

// =========================================
// APPLICATION INSIGHTS QUERIES
// =========================================

// Request rate
requests
| where timestamp > ago(1h)
| summarize count() by bin(timestamp, 5m), name
| render timechart

// Error rate
requests
| where timestamp > ago(1h)
| summarize 
    TotalRequests = count(),
    FailedRequests = countif(success == false),
    ErrorRate = round(countif(success == false) * 100.0 / count(), 2)
  by bin(timestamp, 5m)
| render timechart

// Slow requests (> 2 seconds)
requests
| where timestamp > ago(1h)
| where duration > 2000
| project timestamp, name, duration, resultCode, url
| sort by duration desc

// Exception details
exceptions
| where timestamp > ago(1h)
| project timestamp, type, method, message, details
| sort by timestamp desc

// User journey (dependency map)
dependencies
| where timestamp > ago(1h)
| summarize count(), avg(duration) by target, name, type
| sort by count() desc

// =========================================
// ACTIVITY LOG QUERIES (Audit Trail)
// Like CloudTrail queries
// =========================================

AzureActivity
| where TimeGenerated > ago(24h)
| where OperationNameValue contains "write" or OperationNameValue contains "delete"
| project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue, ResourceGroup
| sort by TimeGenerated desc

// Who deleted what?
AzureActivity
| where TimeGenerated > ago(7d)
| where OperationNameValue contains "delete"
| where ActivityStatusValue == "Success"
| project TimeGenerated, Caller, OperationNameValue, ResourceGroup, Resource
| sort by TimeGenerated desc

// Failed deployments
AzureActivity
| where TimeGenerated > ago(7d)
| where OperationNameValue contains "deployments"
| where ActivityStatusValue == "Failed"
| project TimeGenerated, Caller, Properties, ResourceGroup
```

---

## Part 5 — Dashboards & Workbooks

```bash
# =========================================
# Create Azure Dashboard via CLI
# =========================================

cat > dashboard.json << 'EOF'
{
  "lenses": {
    "0": {
      "order": 0,
      "parts": {
        "0": {
          "position": {"x": 0, "y": 0, "rowSpan": 4, "colSpan": 6},
          "metadata": {
            "type": "Extension/Microsoft_Azure_Monitoring/PartType/MetricsChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {"resourceType": "microsoft.compute/virtualmachines"},
                        "name": "Percentage CPU",
                        "aggregationType": 4
                      }
                    ],
                    "title": "VM CPU Utilization"
                  }
                }
              }
            }
          }
        }
      }
    }
  },
  "metadata": {
    "model": {"timeRange": {"value": {"relative": {"duration": 24, "timeUnit": 1}}}}
  }
}
EOF

DASHBOARD_NAME="dashboard-monitoring-$(date +%s)"
az portal dashboard create \
  --resource-group $RG \
  --name $DASHBOARD_NAME \
  --input-path dashboard.json \
  --location $LOCATION

echo "✅ Dashboard created!"
```

---

## Part 6 — Azure Monitor Autoscale

```bash
# =========================================
# Configure autoscale for a VM Scale Set
# Like AWS Auto Scaling Groups with CloudWatch alarms
# =========================================

# First create a VMSS
az vmss create \
  --resource-group $RG \
  --name vmss-web \
  --image Ubuntu2204 \
  --instance-count 2 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --load-balancer lb-web \
  --public-ip-address pip-lb-web

VMSS_ID=$(az vmss show --resource-group $RG --name vmss-web --query id --output tsv)

# Create autoscale profile
az monitor autoscale create \
  --resource-group $RG \
  --resource $VMSS_ID \
  --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --name autoscale-vmss-web \
  --min-count 2 \
  --max-count 20 \
  --count 2

# Scale OUT rule: CPU > 70% → add 2 instances
az monitor autoscale rule create \
  --resource-group $RG \
  --autoscale-name autoscale-vmss-web \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 2 \
  --cooldown 5

# Scale IN rule: CPU < 30% → remove 1 instance
az monitor autoscale rule create \
  --resource-group $RG \
  --autoscale-name autoscale-vmss-web \
  --condition "Percentage CPU < 30 avg 15m" \
  --scale in 1 \
  --cooldown 10

# Add scheduled scaling (predictable workloads)
az monitor autoscale profile create \
  --resource-group $RG \
  --autoscale-name autoscale-vmss-web \
  --name "business-hours" \
  --timezone "Eastern Standard Time" \
  --start 2024-01-01T08:00:00 \
  --end 2024-12-31T18:00:00 \
  --recurrence week mon tue wed thu fri \
  --min-count 4 \
  --max-count 20 \
  --count 4

echo "✅ Autoscale configured for VMSS"
```

---

## Cleanup

```bash
az group delete --name rg-monitoring-lab --yes --no-wait
rm -f dcr-linux.json dashboard.json
```

---

## ✅ Lab Checklist

- [ ] Created Log Analytics Workspace
- [ ] Installed Azure Monitor Agent on VM
- [ ] Created Data Collection Rule for performance and syslog
- [ ] Enabled diagnostic settings on Storage Account
- [ ] Created Action Group with email notifications
- [ ] Created CPU metric alert
- [ ] Created memory metric alert
- [ ] Created log-based alert with KQL
- [ ] Ran KQL queries for VM performance
- [ ] Ran KQL queries for security events
- [ ] Ran KQL queries for Activity Log audit
- [ ] Configured VM Scale Set autoscale
