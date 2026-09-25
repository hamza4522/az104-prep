# 🔄 Hybrid & Migration

> **AWS Parallel:** Migration Hub + Database Migration Service → Azure Migrate  
> **GCP Parallel:** Migrate for Compute Engine → Azure Migrate

## Labs in This Section

| Lab | Title | Difficulty |
|---|---|---|
| Lab-01 | Azure Migrate — Discovery & Assessment | 🟡 |
| Lab-02 | Azure Site Recovery — Disaster Recovery | 🔴 |
| Lab-03 | Azure Arc — Manage Hybrid Servers | 🔴 |

---

## Lab 01 — Azure Migrate: Discovery & Assessment

```bash
RG="rg-migration-lab"
LOCATION="eastus"

az group create --name $RG --location $LOCATION

# Create Azure Migrate project
az migrate project create \
  --resource-group $RG \
  --name "migrate-project-prod" \
  --location $LOCATION

# List migrate projects
az migrate project list --resource-group $RG --output table

# Azure Migrate Assessment (via Portal — portal.azure.com → Azure Migrate)
# 1. Create project
# 2. Download collector appliance (VMware/Hyper-V/Physical)
# 3. Run discovery (scans on-prem environment)
# 4. Create assessment (right-size recommendations, cost estimates)
# 5. Create migration groups
# 6. Start replication (continuous data replication)
# 7. Test migration (validate in Azure)
# 8. Run migration (cutover)
# 9. Clean up source

echo "📋 Azure Migrate Steps:"
echo "1. Create project in Azure Migrate hub"
echo "2. Deploy collector appliance on-premises"
echo "3. Discover VMs (VMware vCenter, Hyper-V, Physical)"
echo "4. Create assessment groups"
echo "5. View recommendations and cost estimates"
echo "6. Start agentless replication"
echo "7. Test failover to Azure VNet"
echo "8. Complete migration"
```

---

## Lab 02 — Azure Arc: Manage Hybrid Servers

```bash
# Register Arc providers
az provider register --namespace Microsoft.HybridCompute
az provider register --namespace Microsoft.GuestConfiguration
az provider register --namespace Microsoft.HybridConnectivity

# Create Arc resource group
az group create --name rg-arc-lab --location eastus

# Generate Arc onboarding script
az connectedmachine connect \
  --resource-group rg-arc-lab \
  --name "on-prem-server-01" \
  --location eastus \
  --subscription $(az account show --query id --output tsv) \
  --tags Environment=Hybrid Location="DataCenter-1"

# On your on-premises Linux server:
# curl -L https://aka.ms/azcmagent | bash
# sudo azcmagent connect \
#   --service-principal-id "CLIENT_ID" \
#   --service-principal-secret "CLIENT_SECRET" \
#   --tenant-id "TENANT_ID" \
#   --subscription-id "SUB_ID" \
#   --resource-group "rg-arc-lab" \
#   --location "eastus"

# List Arc-enabled servers
az connectedmachine list --output table

# Install extensions on Arc servers (just like Azure VMs!)
az connectedmachine extension create \
  --resource-group rg-arc-lab \
  --machine-name "on-prem-server-01" \
  --name AzureMonitorLinuxAgent \
  --type AzureMonitorLinuxAgent \
  --publisher Microsoft.Azure.Monitor \
  --location eastus

# Run policy on Arc servers
az policy assignment create \
  --name "arc-monitoring-policy" \
  --policy "Deploy Log Analytics agent to Linux Azure Arc machines" \
  --scope "/subscriptions/$(az account show --query id --output tsv)/resourceGroups/rg-arc-lab"

echo "✅ On-premises server managed via Azure Arc"
echo "Benefits:"
echo "  - Apply Azure Policy to on-prem servers"
echo "  - Use Azure Monitor for hybrid monitoring"
echo "  - Run Azure extensions on-premises"
echo "  - Assign RBAC roles to on-prem servers"
echo "  - Use Azure Defender for on-prem security"
```

---

## Lab 03 — Azure VPN Gateway: Site-to-Site

```bash
RG="rg-vpn-lab"
LOCATION="eastus"

az group create --name $RG --location $LOCATION

# Create VNet
az network vnet create \
  --resource-group $RG \
  --name vnet-azure \
  --address-prefixes 10.1.0.0/16

az network vnet subnet create \
  --resource-group $RG \
  --vnet-name vnet-azure \
  --name WorkloadSubnet \
  --address-prefixes 10.1.1.0/24

# Create Gateway Subnet (REQUIRED — must be named GatewaySubnet)
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name vnet-azure \
  --name GatewaySubnet \
  --address-prefixes 10.1.255.0/27

# Create public IP for VPN gateway
az network public-ip create \
  --resource-group $RG \
  --name pip-vpngw \
  --sku Standard \
  --allocation-method Static \
  --zone 1 2 3

# Create VPN Gateway (takes 30-45 minutes!)
az network vnet-gateway create \
  --resource-group $RG \
  --name vpngw-azure \
  --location $LOCATION \
  --public-ip-address pip-vpngw \
  --vnet vnet-azure \
  --gateway-type Vpn \
  --vpn-type RouteBased \
  --sku VpnGw2AZ \
  --generation Generation2 \
  --no-wait

echo "VPN Gateway creation started (takes 30-45 minutes...)"

# Create Local Network Gateway (represents on-premises VPN device)
ON_PREM_GATEWAY_IP="203.0.113.1"  # Your on-prem VPN device public IP
ON_PREM_NETWORK="192.168.0.0/24"  # Your on-prem network CIDR

az network local-gateway create \
  --resource-group $RG \
  --name lng-onprem \
  --gateway-ip-address $ON_PREM_GATEWAY_IP \
  --local-address-prefixes $ON_PREM_NETWORK

# Create VPN connection
az network vpn-connection create \
  --resource-group $RG \
  --name conn-azure-to-onprem \
  --vnet-gateway1 vpngw-azure \
  --local-gateway2 lng-onprem \
  --shared-key "MySecretPreSharedKey123!" \
  --connection-type IPSec \
  --routing-weight 10

# Monitor connection
az network vpn-connection show \
  --resource-group $RG \
  --name conn-azure-to-onprem \
  --query connectionStatus

echo "✅ S2S VPN configured!"
echo "Configure matching settings on your on-premises VPN device"
```
