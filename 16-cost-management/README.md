# 💰 Cost Management

> **AWS Parallel:** Cost Explorer + Budgets → Azure Cost Management  
> **GCP Parallel:** Cloud Billing → Azure Cost Management

## Labs in This Section

| Lab | Title | Difficulty |
|---|---|---|
| Lab-01 | Cost Analysis & Budgets | 🟢 |
| Lab-02 | Azure Reservations & Savings Plans | 🟡 |
| Lab-03 | Cost Optimization Best Practices | 🟡 |

---

## Lab 01 — Cost Analysis & Budgets

```bash
# View cost summary for current month
az consumption usage list \
  --start-date $(date -d "$(date +%Y-%m-01)" +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --output table

# View cost by resource group
az consumption usage list \
  --start-date $(date -d "$(date +%Y-%m-01)" +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --query "[].{ResourceGroup:instanceName, Cost:pretaxCost, Currency:currency}" \
  --output table

# Create a budget (like AWS Budgets)
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

az consumption budget create \
  --budget-name "monthly-budget-500" \
  --amount 500 \
  --time-grain Monthly \
  --start-date "$(date +%Y-%m-01)" \
  --end-date "2025-12-31" \
  --category Cost \
  --resource-group-filter "rg-prod*" \
  --notifications '[
    {
      "enabled": true,
      "operator": "GreaterThan",
      "threshold": 80,
      "contactEmails": ["devops@company.com"],
      "thresholdType": "Actual"
    },
    {
      "enabled": true,
      "operator": "GreaterThan",
      "threshold": 100,
      "contactEmails": ["devops@company.com", "finance@company.com"],
      "thresholdType": "Forecasted"
    }
  ]'

echo "✅ Budget created: Alert at 80% actual, 100% forecasted"

# List budgets
az consumption budget list --output table

# Get Azure Advisor cost recommendations (like AWS Trusted Advisor)
az advisor recommendation list \
  --category Cost \
  --output table

# Show potential savings
az advisor recommendation list \
  --category Cost \
  --query "[].{Title:shortDescription.problem, Impact:impact, Savings:extendedProperties.annualSavingsAmount}" \
  --output table
```

## Key Cost Optimization Tips

| Strategy | Description | Savings |
|---|---|---|
| Right-sizing | Use Azure Advisor recommendations | 20-40% |
| Reserved Instances | 1-3 year commitment | 40-72% |
| Azure Hybrid Benefit | Use existing Windows Server / SQL licenses | Up to 49% |
| Spot VMs | Preemptible instances for batch workloads | 60-90% |
| Auto-shutdown | Dev/test VMs shut down at night | 50-75% |
| Storage tiers | Move cold data to Cool/Archive | 60-80% |
| Delete orphaned resources | Unused disks, IPs, LBs | Varies |
| Dev/Test subscription | Microsoft offer for dev workloads | 55%+ |

## Azure Hybrid Benefit (Save on Licensing)

```bash
# Apply Hybrid Benefit to VM (use existing Windows Server license)
az vm update \
  --resource-group rg-prod \
  --name vm-windows-01 \
  --license-type Windows_Server

# For SQL Server (use existing SQL license)
az vm update \
  --resource-group rg-prod \
  --name vm-sql-01 \
  --license-type RHEL_BYOS

# Check Hybrid Benefit status
az vm list \
  --query "[?licenseType!=null].{Name:name, LicenseType:licenseType}" \
  --output table
```

## Auto-Shutdown for Dev VMs

```bash
# Enable auto-shutdown at 7 PM UTC
az vm auto-shutdown \
  --resource-group rg-dev \
  --vm-name vm-dev-01 \
  --time 1900 \
  --email "developer@company.com"

# Disable auto-shutdown
az vm auto-shutdown \
  --resource-group rg-dev \
  --vm-name vm-dev-01 \
  --off
```
