# ♻️ Disaster Recovery

## Labs in This Section

| Lab | Title | Difficulty |
|---|---|---|
| Lab-01 | Azure Site Recovery — VM Replication | 🔴 |
| Lab-02 | Azure Backup — VMs & Databases | 🟡 |
| Lab-03 | Business Continuity Planning | ⭐ |

---

## Lab 01 — Azure Backup for VMs

```bash
RG="rg-backup-lab"
LOCATION="eastus"
az group create --name $RG --location $LOCATION

# Create Recovery Services Vault (central backup and DR service)
VAULT_NAME="rsv-backup-$(date +%s)"

az backup vault create \
  --resource-group $RG \
  --name $VAULT_NAME \
  --location $LOCATION

# Set storage redundancy
az backup vault backup-properties set \
  --resource-group $RG \
  --name $VAULT_NAME \
  --backup-storage-redundancy GeoRedundant  # or LocallyRedundant

# Create VM to backup
az vm create \
  --resource-group $RG \
  --name vm-to-backup \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys

# Enable backup for VM
az backup protection enable-for-vm \
  --resource-group $RG \
  --vault-name $VAULT_NAME \
  --vm vm-to-backup \
  --policy-name DefaultPolicy  # DefaultPolicy: daily backup, 30-day retention

# Create custom backup policy
cat > backup-policy.json << 'EOF'
{
  "backupManagementType": "AzureIaasVM",
  "schedulePolicy": {
    "schedulePolicyType": "SimpleSchedulePolicy",
    "scheduleRunFrequency": "Daily",
    "scheduleRunTimes": ["2024-01-01T02:00:00.000Z"],
    "scheduleWeeklyFrequency": 0
  },
  "retentionPolicy": {
    "retentionPolicyType": "LongTermRetentionPolicy",
    "dailySchedule": {
      "retentionTimes": ["2024-01-01T02:00:00.000Z"],
      "retentionDuration": {"count": 30, "durationType": "Days"}
    },
    "weeklySchedule": {
      "daysOfTheWeek": ["Sunday"],
      "retentionTimes": ["2024-01-01T02:00:00.000Z"],
      "retentionDuration": {"count": 12, "durationType": "Weeks"}
    },
    "monthlySchedule": {
      "retentionScheduleFormatType": "Weekly",
      "retentionScheduleWeekly": [
        {"daysOfTheWeek": ["Sunday"], "weeksOfTheMonth": ["First"]}
      ],
      "retentionTimes": ["2024-01-01T02:00:00.000Z"],
      "retentionDuration": {"count": 12, "durationType": "Months"}
    },
    "yearlySchedule": {
      "retentionScheduleFormatType": "Weekly",
      "monthsOfYear": ["January"],
      "retentionScheduleWeekly": [
        {"daysOfTheWeek": ["Sunday"], "weeksOfTheMonth": ["First"]}
      ],
      "retentionTimes": ["2024-01-01T02:00:00.000Z"],
      "retentionDuration": {"count": 7, "durationType": "Years"}
    }
  }
}
EOF

az backup policy create \
  --resource-group $RG \
  --vault-name $VAULT_NAME \
  --name "policy-prod-backup" \
  --backup-management-type AzureIaasVM \
  --policy @backup-policy.json

# Trigger on-demand backup
az backup protection backup-now \
  --resource-group $RG \
  --vault-name $VAULT_NAME \
  --container-name "IaasVMContainer;iaasvmcontainerv2;${RG};vm-to-backup" \
  --item-name "VM;iaasvmcontainerv2;${RG};vm-to-backup" \
  --backup-management-type AzureIaasVM \
  --retain-until "$(date -u -d '+7 days' '+%d-%m-%Y')"

# List backup jobs
az backup job list \
  --resource-group $RG \
  --vault-name $VAULT_NAME \
  --output table

# List recovery points
az backup recoverypoint list \
  --resource-group $RG \
  --vault-name $VAULT_NAME \
  --container-name "IaasVMContainer;iaasvmcontainerv2;${RG};vm-to-backup" \
  --item-name "VM;iaasvmcontainerv2;${RG};vm-to-backup" \
  --backup-management-type AzureIaasVM \
  --output table

# Restore VM from backup (full VM restore)
az backup restore restore-azurevm \
  --resource-group $RG \
  --vault-name $VAULT_NAME \
  --container-name "IaasVMContainer;iaasvmcontainerv2;${RG};vm-to-backup" \
  --item-name "VM;iaasvmcontainerv2;${RG};vm-to-backup" \
  --rp-name "RECOVERY_POINT_NAME" \
  --storage-account "STORAGE_ACCOUNT_NAME" \
  --restore-to-staging-storage-account

echo "✅ Backup configured!"
```

---

## Lab 02 — Azure Site Recovery (ASR)

```bash
# Azure Site Recovery = AWS DRS (Elastic Disaster Recovery)
# Replicates VMs to a secondary region for DR

VAULT_NAME="rsv-asr-$(date +%s)"
PRIMARY_REGION="eastus"
SECONDARY_REGION="westus2"

az backup vault create \
  --resource-group $RG \
  --name $VAULT_NAME \
  --location $PRIMARY_REGION

# ASR is configured via Portal (complex multi-step wizard):
echo "📋 ASR Configuration Steps (Portal):"
echo "1. Recovery Services Vault → Site Recovery → Prepare Infrastructure"
echo "2. Choose: Azure to Azure"
echo "3. Source region: eastus"
echo "4. Target region: westus2"
echo "5. Select VMs to replicate"
echo "6. Configure target VNet, storage, resource group"
echo "7. Enable replication (initial sync takes hours)"
echo "8. After sync: Test failover (non-disruptive)"
echo "9. Monitor: Replication health, RPO"
echo "10. Failover: Emergency or planned (RTO < 15 min typically)"

# RTO and RPO targets:
echo ""
echo "📊 Typical ASR SLAs:"
echo "  RPO (Recovery Point Objective): 60 seconds (continuous replication)"
echo "  RTO (Recovery Time Objective):  < 15 minutes"
```
