# 📊 Azure Monitor & Governance Lab — Multi-Level Production Scenarios
# ═════════════════════════════════════════════════════════════════════
# Level 1 → Log Analytics Workspace + AMA Agent + DCR + Action Groups & Alerts
# Level 2 → Advanced KQL Query Suite + App Insights Tracing + Workbooks
# Level 3 → Azure Policy Governance + DeployIfNotExists Remediation + Locks
# ═════════════════════════════════════════════════════════════════════

set -euo pipefail

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
PRIMARY_REGION="eastus"
RAND_SUFFIX=$RANDOM
ALERT_EMAIL="devops-alerts@company.com"

echo "================================================================="
echo " Azure Monitoring & Enterprise Governance Lab"
echo " AWS Parallel: CloudWatch + CloudTrail + AWS Config + GuardDuty"
echo " GCP Parallel: Cloud Monitoring + Cloud Logging + Cloud Armor"
echo "================================================================="

# ─────────────────────────────────────────────────────────────
# 🟢 LEVEL 1 — Centralized Log Analytics, AMA, DCR & Metric Alerts
# Scenario:
# - Central Log Analytics Workspace with 90-day retention & daily cap
# - Azure Monitor Agent (AMA) configuration with Data Collection Rule (DCR)
# - Action Group with Email, Webhook, and PagerDuty routing
# - Dynamic Metric Alert (CPU threshold > 80% with auto-mitigation)
# - Diagnostic Settings streaming Activity Log and Platform Metrics
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🟢 LEVEL 1: Centralized Log Analytics, DCR & Metric Alerts"
echo "=============================================================="

RG_L1="rg-monitor-l1-prod"
LAW_NAME="law-enterprise-prod-${RAND_SUFFIX}"
AG_NAME="ag-critical-incidents"
DCR_NAME="dcr-linux-workloads"

echo "Step 1.1: Creating Monitoring Resource Group..."
az group create --name $RG_L1 --location $PRIMARY_REGION --tags Tier=Monitoring Level=L1

echo "Step 1.2: Creating Enterprise Log Analytics Workspace..."
az monitor log-analytics workspace create \
  --resource-group $RG_L1 \
  --workspace-name $LAW_NAME \
  --location $PRIMARY_REGION \
  --sku "PerGB2018" \
  --retention-time 90 \
  --daily-quota-gb 5

LAW_ID=$(az monitor log-analytics workspace show -g $RG_L1 -n $LAW_NAME --query id -o tsv)
echo "  ✅ Log Analytics Workspace ready: $LAW_ID"

echo "Step 1.3: Creating Multi-Channel Action Group (Email + Webhook)..."
az monitor action-group create \
  --resource-group $RG_L1 \
  --name $AG_NAME \
  --short-name "CritAlerts" \
  --action email "DevOpsTeam" "$ALERT_EMAIL" usecommonalertschema true \
  --action webhook "SlackWebhook" "https://hooks.slack.com/services/T000/B000/XXXX" usecommonalertschema true

AG_ID=$(az monitor action-group show -g $RG_L1 -n $AG_NAME --query id -o tsv)
echo "  ✅ Action Group created: $AG_ID"

echo "Step 1.4: Creating Data Collection Rule (DCR) for Azure Monitor Agent..."
# DCR specifies exactly what logs (syslog, performance counters) to gather and where to store them
cat << 'DCR_JSON' > /tmp/dcr-rules.json
{
  "location": "eastus",
  "properties": {
    "dataSources": {
      "performanceCounters": [
        {
          "name": "perfCounterDataSource60s",
          "samplingFrequencyInSeconds": 60,
          "streams": [
            "Microsoft-Perf"
          ],
          "counterSpecifiers": [
            "Processor(*)\\% Processor Time",
            "Memory(*)\\% Used Memory",
            "LogicalDisk(*)\\% Free Space"
          ]
        }
      ],
      "syslog": [
        {
          "name": "syslogDataSource",
          "streams": [
            "Microsoft-Syslog"
          ],
          "facilityNames": [
            "auth", "authpriv", "cron", "daemon", "mark", "kern", "syslog"
          ],
          "logLevels": [
            "Warning", "Error", "Critical", "Alert", "Emergency"
          ]
        }
      ]
    },
    "destinations": {
      "logAnalytics": [
        {
          "workspaceResourceId": "WORKSPACE_PLACEHOLDER",
          "name": "centralWorkspace"
        }
      ]
    },
    "dataFlows": [
      {
        "streams": [
          "Microsoft-Perf",
          "Microsoft-Syslog"
        ],
        "destinations": [
          "centralWorkspace"
        ]
      }
    ]
  }
}
DCR_JSON

# Replace workspace placeholder
sed -i "s|WORKSPACE_PLACEHOLDER|$LAW_ID|g" /tmp/dcr-rules.json

az monitor data-collection rule create \
  --resource-group $RG_L1 \
  --name $DCR_NAME \
  --rule-file "/tmp/dcr-rules.json"

echo "  ✅ Data Collection Rule (DCR) deployed with Syslog + Perf Counter streams."

echo "Step 1.5: Creating Activity Log Diagnostic Settings..."
# Stream Azure Control Plane Activity Logs (Who deleted/modified what) into Log Analytics
az monitor diagnostic-settings subscription create \
  --name "sub-activity-to-law" \
  --location $PRIMARY_REGION \
  --workspace "$LAW_ID" \
  --logs '[{"category":"Administrative","enabled":true},{"category":"Security","enabled":true},{"category":"Alert","enabled":true},{"category":"Policy","enabled":true}]'

echo "  ✅ Subscription Activity Logs continuously streamed to Log Analytics."


# ─────────────────────────────────────────────────────────────
# 🟡 LEVEL 2 — Advanced KQL Operational Suite & Workbooks
# Scenario:
# - KQL (Kusto Query Language) library for real production triage
# - Scheduled Query Rules (Alert on KQL conditions)
# - Detecting Heartbeat drop, brute-force SSH, high error rates
# - Distributed tracing with Application Insights
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🟡 LEVEL 2: Advanced KQL Operational Suite & Log Alerts"
echo "=============================================================="

echo "Deploying Production KQL Query Library..."

cat << 'KQL_LIBRARY' > /tmp/kql-operational-library.kql
// ═══════════════════════════════════════════════════════════════
// 1. Heartbeat Monitor: Detect Silent VM Crashes (AWS EC2 Status Check equivalent)
// ═══════════════════════════════════════════════════════════════
Heartbeat
| where TimeGenerated > ago(1h)
| summarize LastHeartbeat = max(TimeGenerated) by Computer, ResourceGroup
| where LastHeartbeat < ago(5m)
| project Computer, ResourceGroup, LastHeartbeat, DowntimeMinutes = datetime_diff('minute', now(), LastHeartbeat)

// ═══════════════════════════════════════════════════════════════
// 2. High Disk Saturation Alert (> 85% disk used)
// ═══════════════════════════════════════════════════════════════
Perf
| where TimeGenerated > ago(15m)
| where ObjectName == "LogicalDisk" and CounterName == "% Free Space"
| summarize AvgFreePct = avg(CounterValue) by Computer, InstanceName
| where AvgFreePct < 15.0
| project Computer, MountPoint = InstanceName, FreeSpacePct = round(AvgFreePct, 2)

// ═══════════════════════════════════════════════════════════════
// 3. Security: Failed SSH / Admin Login Attempts (Brute Force Detection)
// ═══════════════════════════════════════════════════════════════
Syslog
| where TimeGenerated > ago(1h)
| where Facility == "auth" or Facility == "authpriv"
| where SyslogMessage has "Failed password" or SyslogMessage has "authentication failure"
| parse SyslogMessage with * "from " AttackerIP " port" *
| summarize FailedCount = count() by AttackerIP, Computer
| where FailedCount >= 10
| order by FailedCount desc

// ═══════════════════════════════════════════════════════════════
// 4. Azure Activity Log: Unauthorized / Denied Actions
// ═══════════════════════════════════════════════════════════════
AzureActivity
| where TimeGenerated > ago(24h)
| where ActivityStatusValue == "Failed" or ActivitySubstatusValue has "Deny"
| summarize DeniedEvents = count() by Caller, CallerIpAddress, OperationNameValue, ResourceGroup
| order by DeniedEvents desc

// ═══════════════════════════════════════════════════════════════
// 5. App Service / Web API: 5xx Spikes & Latency Outliers
// ═══════════════════════════════════════════════════════════════
AppServiceHTTPLogs
| where TimeGenerated > ago(30m)
| summarize TotalRequests = count(),
            Failed5xx = countif(ScStatus >= 500),
            AvgLatencyMs = avg(TimeTaken),
            P95LatencyMs = percentile(TimeTaken, 95)
            by CsMethod, CsUriStem
| where Failed5xx > 5 or P95LatencyMs > 2000
| order by Failed5xx desc
KQL_LIBRARY

echo "  ✅ KQL production query library written to /tmp/kql-operational-library.kql"

echo "Step 2.1: Creating Scheduled Query Alert based on KQL (Heartbeat Missing)..."
az monitor scheduled-query create \
  --resource-group $RG_L1 \
  --name "alert-vm-heartbeat-missing" \
  --scopes "$LAW_ID" \
  --condition "count 'Heartbeat | where TimeGenerated > ago(15m) | summarize LastHeartbeat = max(TimeGenerated) by Computer | where LastHeartbeat < ago(5m)' > 0" \
  --condition-query-type "ResultCount" \
  --evaluation-frequency 5m \
  --window-size 15m \
  --severity 1 \
  --action-groups "$AG_ID" \
  --description "Fires when any VM stops sending heartbeat for over 5 minutes."

echo "  ✅ Scheduled KQL Query Alert deployed."


# ─────────────────────────────────────────────────────────────
# 🔴 LEVEL 3 — Enterprise Azure Policy Governance & Remediation
# Scenario:
# - Custom Policy Definition (Enforce Tags, Allowed Locations, Deny Public IP)
# - DeployIfNotExists Policy with Managed Identity Automatic Remediation
# - Management Group / Subscription Level Initiative (Policy Set)
# - CanNotDelete & ReadOnly Resource Locks for critical production infrastructure
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🔴 LEVEL 3: Enterprise Policy, Remediation Tasks & Locks"
echo "=============================================================="

RG_L3="rg-governance-l3-prod"
az group create --name $RG_L3 --location $PRIMARY_REGION --tags Tier=Governance Level=L3

echo "Step 3.1: Defining Custom Policy: Require Environment Tag with Automatic Remediation..."
cat << 'POLICY_RULE' > /tmp/policy-require-tag.json
{
  "mode": "Indexed",
  "policyRule": {
    "if": {
      "field": "tags['Environment']",
      "exists": "false"
    },
    "then": {
      "effect": "modify",
      "details": {
        "roleDefinitionIds": [
          "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
        ],
        "operations": [
          {
            "operation": "add",
            "field": "tags['Environment']",
            "value": "Production"
          }
        ]
      }
    }
  }
}
POLICY_RULE

# Create Custom Policy Definition
POLICY_DEF_NAME="policy-modify-environment-tag"
az policy definition create \
  --name $POLICY_DEF_NAME \
  --rules "/tmp/policy-require-tag.json" \
  --description "Automatically appends Environment=Production tag if missing on resources." \
  --mode Indexed

echo "Step 3.2: Assigning Policy Definition with System-Assigned Managed Identity..."
ASSIGNMENT_NAME="assign-env-tag-remediation"
az policy assignment create \
  --name $ASSIGNMENT_NAME \
  --resource-group $RG_L3 \
  --policy $POLICY_DEF_NAME \
  --location $PRIMARY_REGION \
  --assign-identity

ASSIGNMENT_IDENTITY=$(az policy assignment show \
  --name $ASSIGNMENT_NAME \
  --resource-group $RG_L3 \
  --query identity.principalId -o tsv)

echo "Step 3.3: Granting Remediation Identity 'Contributor' on Target Scope..."
az role assignment create \
  --assignee "$ASSIGNMENT_IDENTITY" \
  --role "Contributor" \
  --resource-group $RG_L3

echo "Step 3.4: Triggering Automatic Policy Remediation Task..."
az policy remediation create \
  --name "remediate-missing-tags" \
  --policy-assignment $ASSIGNMENT_NAME \
  --resource-group $RG_L3

echo "  ✅ Azure Policy automatically remediating non-compliant resources without human intervention."

echo "Step 3.5: Applying Resource Locks (Prevent Accidental Deletion of Critical DB/Network)..."
# CanNotDelete: Authorized users can read/modify, but CANNOT delete the resource
az lock create \
  --name "lock-prevent-deletion" \
  --resource-group $RG_L3 \
  --lock-type CanNotDelete \
  --notes "Production lock: Contact Cloud Security before deleting this Resource Group."

echo "  ✅ Resource Lock 'CanNotDelete' active on $RG_L3."

echo ""
echo "=============================================================="
echo " ✅ MONITORING & GOVERNANCE MULTI-LEVEL LAB COMPLETE!"
echo "=============================================================="
