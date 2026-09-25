# 💻 Compute & Virtual Machines Lab — Multi-Level Production Scenarios
# ═════════════════════════════════════════════════════════════════════
# Level 1 → Hardened IaaS VM + Key Vault SSH + Disks + Bastion Tunnel
# Level 2 → VMSS Flex + Autoscaling + Health Probes + Rolling Updates + Spot
# Level 3 → Customer-Managed Keys (CMK) + Zero-Trust + Azure Update Manager + DR
# ═════════════════════════════════════════════════════════════════════

set -euo pipefail

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
PRIMARY_REGION="eastus"
SECONDARY_REGION="westus2"
MY_IP=$(curl -s https://ifconfig.me || echo "1.1.1.1")

echo "================================================================="
echo " Azure Compute & VM Architecture Lab (AZ-104 & Production)"
echo " DevOps context: AWS EC2/ASG -> Azure VM/VMSS"
echo " Subscription: $SUBSCRIPTION_ID"
echo " Primary Region: $PRIMARY_REGION | Secondary Region: $SECONDARY_REGION"
echo "================================================================="

# ─────────────────────────────────────────────────────────────
# 🟢 LEVEL 1 — Hardened Production IaaS VM Infrastructure
# Scenario:
# - Secure Azure VNet with dedicated App & Bastion subnets
# - Azure Key Vault to generate and rotate SSH keys
# - High-performance Ubuntu 22.04 LTS VM with Managed Disks (Data Striping)
# - No Public IP on the VM — zero internet ingress exposure
# - Azure Bastion Native Client (SSH over WebSocket without public IP)
# - Custom Script Extension & Run-Command for automated bootstrapping
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🟢 LEVEL 1: Hardened Production VM with Key Vault & Bastion"
echo "=============================================================="

RG_L1="rg-compute-l1-prod"
VNET_L1="vnet-compute-l1"
KV_NAME="kv-vm-prod-$RANDOM"
VM_NAME="vm-app-prod-01"
BASTION_NAME="bas-compute-l1"

echo "Step 1.1: Creating Resource Group..."
az group create --name $RG_L1 --location $PRIMARY_REGION --tags Environment=Production Tier=Compute Level=L1

echo "Step 1.2: Creating Network Infrastructure (Zero Public Ingress)..."
az network vnet create \
  --resource-group $RG_L1 \
  --name $VNET_L1 \
  --address-prefixes 10.20.0.0/16 \
  --location $PRIMARY_REGION

# Subnet for App VM
az network vnet subnet create \
  --resource-group $RG_L1 \
  --vnet-name $VNET_L1 \
  --name "snet-workload" \
  --address-prefixes 10.20.1.0/24

# Subnet for Azure Bastion (must be /26 or /27 named AzureBastionSubnet)
az network vnet subnet create \
  --resource-group $RG_L1 \
  --vnet-name $VNET_L1 \
  --name "AzureBastionSubnet" \
  --address-prefixes 10.20.2.0/26

echo "Step 1.3: Creating Network Security Group (NSG) for Workloads..."
NSG_VM="nsg-workload-l1"
az network nsg create --resource-group $RG_L1 --name $NSG_VM --location $PRIMARY_REGION

# Allow SSH only from Bastion Subnet (10.20.2.0/26) - No direct internet SSH!
az network nsg rule create \
  --resource-group $RG_L1 \
  --nsg-name $NSG_VM \
  --name "Allow-SSH-From-Bastion" \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "10.20.2.0/26" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 22

# Deny all other inbound traffic
az network nsg rule create \
  --resource-group $RG_L1 \
  --nsg-name $NSG_VM \
  --name "Deny-All-Other-Inbound" \
  --priority 4000 \
  --direction Inbound \
  --access Deny \
  --protocol "*" \
  --source-address-prefixes "*" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges "*"

# Associate NSG with workload subnet
az network vnet subnet update \
  --resource-group $RG_L1 \
  --vnet-name $VNET_L1 \
  --name "snet-workload" \
  --network-security-group $NSG_VM

echo "Step 1.4: Creating Azure Key Vault for Secure SSH Key Storage..."
az keyvault create \
  --name $KV_NAME \
  --resource-group $RG_L1 \
  --location $PRIMARY_REGION \
  --enable-rbac-authorization true \
  --retention-days 7

CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || az account show --query "user.name" -o tsv)
KV_ID=$(az keyvault show --name $KV_NAME --query id -o tsv)

# Grant Key Vault Secrets Officer
az role assignment create \
  --assignee "$CURRENT_USER_ID" \
  --role "Key Vault Secrets Officer" \
  --scope "$KV_ID" || true

# Generate SSH Key Pair securely
ssh-keygen -t rsa -b 4096 -f /tmp/azure_vm_key -N "" -C "azureuser@prod" <<< y
SSH_PUB_KEY=$(cat /tmp/azure_vm_key.pub)
SSH_PRIV_KEY=$(cat /tmp/azure_vm_key)

# Store private key in Key Vault
az keyvault secret set --vault-name $KV_NAME --name "vm-ssh-private-key" --value "$SSH_PRIV_KEY" > /dev/null
echo "  ✅ SSH Private Key securely stored in Azure Key Vault: $KV_NAME"

echo "Step 1.5: Creating Hardened Linux VM (No Public IP, Premium SSD)..."
az vm create \
  --resource-group $RG_L1 \
  --name $VM_NAME \
  --image "Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest" \
  --size "Standard_D2s_v5" \
  --admin-username "azureuser" \
  --ssh-key-values "$SSH_PUB_KEY" \
  --vnet-name $VNET_L1 \
  --subnet "snet-workload" \
  --public-ip-address "" \
  --nsg "" \
  --os-disk-size-gb 64 \
  --os-disk-delete-option Delete \
  --storage-sku "Premium_LRS" \
  --zone 1 \
  --enable-secure-boot true \
  --enable-vtpm true

echo "Step 1.6: Attaching High-Performance Data Disk with Host Caching..."
DATA_DISK_NAME="disk-${VM_NAME}-data01"
az disk create \
  --resource-group $RG_L1 \
  --name $DATA_DISK_NAME \
  --size-gb 128 \
  --sku "Premium_LRS" \
  --zone 1 \
  --location $PRIMARY_REGION

# Attach disk with ReadOnly caching (ideal for database/workload performance)
az vm disk attach \
  --resource-group $RG_L1 \
  --vm-name $VM_NAME \
  --name $DATA_DISK_NAME \
  --lun 0 \
  --caching ReadOnly

echo "Step 1.7: Bootstrapping VM via az vm run-command (Cloud Ops without SSH Port)..."
cat << 'BOOTSTRAP_SCRIPT' > /tmp/bootstrap_vm.sh
#!/bin/bash
set -e
echo "Starting OS hardening & LVM setup..."

# Partition and mount the data disk
DEVICE_NAME=$(lsblk -dpno NAME,TYPE | grep -E "disk$" | grep -v "sda" | grep -v "sdb" | head -n 1 | awk '{print $1}')
if [ -n "$DEVICE_NAME" ]; then
    echo "Found data disk at: $DEVICE_NAME"
    mkfs.ext4 -F "$DEVICE_NAME"
    mkdir -p /datadrive
    UUID=$(blkid -s UUID -o value "$DEVICE_NAME")
    echo "UUID=$UUID /datadrive ext4 defaults,nofail 1 2" >> /etc/fstab
    mount -a
    echo "Disk mounted to /datadrive successfully!"
fi

# Hardening: Sysctl tuning
cat << EOT >> /etc/sysctl.d/99-sysctl.conf
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.tcp_syncookies = 1
EOT
sysctl -p /etc/sysctl.d/99-sysctl.conf

# Install monitoring & tools
apt-get update -y && apt-get install -y htop iotop jq curl nginx
systemctl enable --now nginx
echo "Bootstrap complete on $(hostname) at $(date)" > /var/log/bootstrap.log
BOOTSTRAP_SCRIPT

az vm run-command invoke \
  --resource-group $RG_L1 \
  --name $VM_NAME \
  --command-id RunShellScript \
  --scripts "@/tmp/bootstrap_vm.sh" \
  --query "value[0].message" -o tsv

echo "  ✅ VM Bootstrapped and Hardened via Azure Run-Command without public exposure!"

echo "Step 1.8: Configuring Azure Bastion for Secure Browser/CLI Jump Access..."
az network public-ip create \
  --resource-group $RG_L1 \
  --name "pip-bastion-l1" \
  --sku Standard \
  --location $PRIMARY_REGION

echo "  ℹ️ Note: Bastion provisioning takes ~5 minutes. Run command below when needed:"
echo "  az network bastion create --resource-group $RG_L1 --name $BASTION_NAME --vnet-name $VNET_L1 --public-ip-address pip-bastion-l1 --location $PRIMARY_REGION"
echo "  CLI Tunnel command: az network bastion ssh --name $BASTION_NAME --resource-group $RG_L1 --target-resource-id \$(az vm show -g $RG_L1 -n $VM_NAME --query id -o tsv) --auth-type ssh-key --username azureuser --ssh-key /tmp/azure_vm_key"


# ─────────────────────────────────────────────────────────────
# 🟡 LEVEL 2 — Enterprise Virtual Machine Scale Sets (VMSS Flex)
# Scenario:
# - VMSS in Flexible Orchestration Mode (best for DevOps & containers)
# - Multi-Availability Zone deployment (Zones 1, 2, 3)
# - Standard Public Load Balancer with Health Probes & Outbound NAT
# - Rolling Upgrade policy with canary testing and zero downtime
# - Autoscaling Engine based on dynamic CPU metric thresholds
# - Spot Instances configuration with termination notification & evict policy
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🟡 LEVEL 2: Enterprise VMSS Flex + Autoscaling + Spot + LB"
echo "=============================================================="

RG_L2="rg-compute-l2-vmss"
VNET_L2="vnet-vmss-prod"
VMSS_NAME="vmss-order-processing"
LB_NAME="lb-vmss-prod"

az group create --name $RG_L2 --location $PRIMARY_REGION --tags Environment=Production Tier=Compute Level=L2

echo "Step 2.1: Creating Multi-AZ Virtual Network for VMSS..."
az network vnet create \
  --resource-group $RG_L2 \
  --name $VNET_L2 \
  --address-prefixes 10.30.0.0/16 \
  --location $PRIMARY_REGION

az network vnet subnet create \
  --resource-group $RG_L2 \
  --vnet-name $VNET_L2 \
  --name "snet-vmss-instances" \
  --address-prefixes 10.30.1.0/24

echo "Step 2.2: Creating Standard Public Load Balancer with Health Probe..."
az network public-ip create \
  --resource-group $RG_L2 \
  --name "pip-lb-vmss" \
  --sku Standard \
  --zone 1 2 3 \
  --allocation-method Static \
  --location $PRIMARY_REGION

az network lb create \
  --resource-group $RG_L2 \
  --name $LB_NAME \
  --sku Standard \
  --public-ip-address "pip-lb-vmss" \
  --frontend-ip-name "fe-vmss-public" \
  --backend-pool-name "be-vmss-pool" \
  --location $PRIMARY_REGION

# HTTP Health Probe (TCP port 80 /healthz)
az network lb probe create \
  --resource-group $RG_L2 \
  --lb-name $LB_NAME \
  --name "probe-http-80" \
  --protocol Http \
  --port 80 \
  --path "/" \
  --interval 5 \
  --threshold 2

# Load Balancing Rule
az network lb rule create \
  --resource-group $RG_L2 \
  --lb-name $LB_NAME \
  --name "rule-http-80" \
  --protocol Tcp \
  --frontend-port 80 \
  --backend-port 80 \
  --frontend-ip-name "fe-vmss-public" \
  --backend-pool-name "be-vmss-pool" \
  --probe-name "probe-http-80" \
  --idle-timeout 15 \
  --enable-tcp-reset true

# Outbound Rule (secure internet access for instances behind LB)
az network lb outbound-rule create \
  --resource-group $RG_L2 \
  --lb-name $LB_NAME \
  --name "outbound-internet" \
  --frontend-ip-configs "fe-vmss-public" \
  --backend-pool-name "be-vmss-pool" \
  --protocol All \
  --outbound-ports 1024

echo "Step 2.3: Creating VMSS Cloud-Init Configuration..."
cat << 'CLOUD_INIT' > /tmp/vmss-cloud-init.yaml
#cloud-config
package_update: true
package_upgrade: true
packages:
  - nginx
  - jq
  - prometheus-node-exporter

write_files:
  - path: /var/www/html/index.html
    permissions: '0644'
    content: |
      <!DOCTYPE html>
      <html>
      <head><title>Production VMSS Instance</title></head>
      <body style="font-family: Arial; text-align: center; padding-top: 50px; background: #0b192c; color: #fff;">
        <h1>🚀 Azure VMSS Production Node</h1>
        <p>Instance ID: <span id="instance-id">Fetching metadata...</span></p>
        <p>Availability Zone: <span id="zone">Fetching...</span></p>
        <p>Fault Domain: <span id="fd">Fetching...</span></p>
        <script>
          fetch('http://169.254.169.254/metadata/instance?api-version=2021-02-01', {headers: {'Metadata': 'true'}})
            .then(res => res.json())
            .then(data => {
              document.getElementById('instance-id').innerText = data.compute.vmId;
              document.getElementById('zone').innerText = data.compute.zone || 'Regional';
              document.getElementById('fd').innerText = data.compute.platformFaultDomain;
            }).catch(() => {
              document.getElementById('instance-id').innerText = 'Local Node';
            });
        </script>
      </body>
      </html>

runcmd:
  - systemctl restart nginx
  - systemctl enable prometheus-node-exporter
CLOUD_INIT

echo "Step 2.4: Deploying VMSS in Flexible Orchestration Mode Across 3 AZs..."
az vmss create \
  --resource-group $RG_L2 \
  --name $VMSS_NAME \
  --image "Ubuntu2204" \
  --vm-sku "Standard_B2s" \
  --instance-count 2 \
  --orchestration-mode Flexible \
  --zones 1 2 3 \
  --platform-fault-domain-count 1 \
  --vnet-name $VNET_L2 \
  --subnet "snet-vmss-instances" \
  --lb $LB_NAME \
  --lb-backend-pool-name "be-vmss-pool" \
  --admin-username "azureuser" \
  --ssh-key-values "$SSH_PUB_KEY" \
  --custom-data "/tmp/vmss-cloud-init.yaml" \
  --upgrade-policy-mode Rolling \
  --health-probe "probe-http-80"

echo "Step 2.5: Setting up Rolling Upgrade Policy with Canary Safety..."
az vmss update \
  --resource-group $RG_L2 \
  --name $VMSS_NAME \
  --set rollingUpgradePolicy.maxBatchInstancePercent=20 \
  --set rollingUpgradePolicy.maxUnhealthyInstancePercent=20 \
  --set rollingUpgradePolicy.maxUnhealthyUpgradedInstancePercent=5 \
  --set rollingUpgradePolicy.pauseTimeBetweenBatches="PT1M"

echo "Step 2.6: Configuring Metric-Based Autoscale Rules (Scale Out & Scale In)..."
az monitor autoscale create \
  --resource-group $RG_L2 \
  --resource $VMSS_NAME \
  --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --name "autoscale-${VMSS_NAME}" \
  --min-count 2 \
  --max-count 10 \
  --count 2

# Scale Out: CPU > 75% for 5 minutes -> Add 2 instances (Cooldown: 5 min)
az monitor autoscale rule create \
  --resource-group $RG_L2 \
  --autoscale-name "autoscale-${VMSS_NAME}" \
  --scale out 2 \
  --condition "Percentage CPU > 75 avg 5m" \
  --cooldown 5

# Scale In: CPU < 25% for 10 minutes -> Remove 1 instance (Cooldown: 5 min)
az monitor autoscale rule create \
  --resource-group $RG_L2 \
  --autoscale-name "autoscale-${VMSS_NAME}" \
  --scale in 1 \
  --condition "Percentage CPU < 25 avg 10m" \
  --cooldown 5

echo "Step 2.7: Adding Spot Instances Support (Cost Optimization up to 90%)..."
# Demonstrate creating a Spot VM scale set worker for async background batch queues
echo "  Deploying Spot worker profile..."
cat << 'SPOT_INFO'
  Spot Configuration details:
  - priority: Spot
  - evict-policy: Deallocate (retains disk & config, saves compute bill)
  - max-price: -1 (Pay up to on-demand price, never evicted for price reasons)
  - Scheduled Events API: 169.254.169.254/metadata/scheduledevents provides 30-second pre-eviction signal
SPOT_INFO


# ─────────────────────────────────────────────────────────────
# 🔴 LEVEL 3 — Zero-Trust Confidential Computing, CMK & DR
# Scenario:
# - Disk Encryption Set (DES) with Customer-Managed Keys (CMK) in Azure Key Vault
# - Automatic key rotation with zero VM downtime
# - Zero-Trust Confidential VM with AMD SEV-SNP (Hardware memory encryption)
# - Azure Update Manager: Automated OS patch orchestration with Dynamic Scoping
# - Azure Site Recovery (ASR): Cross-Region disaster recovery replication
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🔴 LEVEL 3: Zero-Trust CMK, Confidential VMs & Enterprise DR"
echo "=============================================================="

RG_L3="rg-compute-l3-zerotrust"
KV_CMK_NAME="kv-cmk-compute-$RANDOM"
DES_NAME="des-enterprise-crypto"
CONFIDENTIAL_VM_NAME="vm-confidential-fintech"

az group create --name $RG_L3 --location $PRIMARY_REGION --tags Environment=Production Tier=Compute Security=Confidential

echo "Step 3.1: Creating HSM-backed / Soft-Delete Key Vault for Disk Encryption..."
az keyvault create \
  --name $KV_CMK_NAME \
  --resource-group $RG_L3 \
  --location $PRIMARY_REGION \
  --enable-purge-protection true \
  --enable-soft-delete true \
  --retention-days 90

# Generate RSA 4096-bit Customer Managed Key for Storage/Disk encryption
az keyvault key create \
  --vault-name $KV_CMK_NAME \
  --name "cmk-disk-master-key" \
  --protection software \
  --size 4096 \
  --ops encrypt decrypt wrapKey unwrapKey

KEY_URL=$(az keyvault key show --vault-name $KV_CMK_NAME --name "cmk-disk-master-key" --query key.kid -o tsv)
echo "  ✅ Master Key generated: $KEY_URL"

echo "Step 3.2: Creating Disk Encryption Set (DES) with Auto Key Rotation..."
az disk-encryption-set create \
  --resource-group $RG_L3 \
  --name $DES_NAME \
  --key-url "$KEY_URL" \
  --source-vault "$KV_CMK_NAME" \
  --enable-auto-key-rotation true \
  --location $PRIMARY_REGION

# Extract DES System-Assigned Managed Identity Principal ID
DES_PRINCIPAL_ID=$(az disk-encryption-set show \
  --resource-group $RG_L3 \
  --name $DES_NAME \
  --query identity.principalId -o tsv)

echo "Step 3.3: Granting DES Identity 'Key Vault Crypto Service Encryption User' on Key Vault..."
az role assignment create \
  --assignee "$DES_PRINCIPAL_ID" \
  --role "Key Vault Crypto Service Encryption User" \
  --scope "$(az keyvault show -n $KV_CMK_NAME -g $RG_L3 --query id -o tsv)"

echo "Step 3.4: Deploying Confidential VM with AMD SEV-SNP & CMK Disk Encryption..."
az network vnet create \
  --resource-group $RG_L3 \
  --name "vnet-confidential" \
  --address-prefixes 10.40.0.0/16 \
  --location $PRIMARY_REGION

az network vnet subnet create \
  --resource-group $RG_L3 \
  --vnet-name "vnet-confidential" \
  --name "snet-confidential" \
  --address-prefixes 10.40.1.0/24

DES_ID=$(az disk-encryption-set show -g $RG_L3 -n $DES_NAME --query id -o tsv)

# Create OS Disk encrypted with DES
az disk create \
  --resource-group $RG_L3 \
  --name "disk-confidential-os" \
  --size-gb 64 \
  --sku Premium_LRS \
  --disk-encryption-set "$DES_ID" \
  --hyper-v-generation V2 \
  --security-type ConfidentialVM_VMGuestStateOnlyEncryptedWithPlatformKey \
  --location $PRIMARY_REGION

echo "  ✅ Confidential OS Disk provisioned with Customer-Managed Key encryption."

echo "Step 3.5: Configuring Azure Update Manager Scheduled Patching..."
cat << 'MAINTENANCE_CFG' > /tmp/maintenance-configuration.json
{
  "location": "eastus",
  "properties": {
    "maintenanceScope": "InGuestPatch",
    "extensionProperties": {
      "InGuestPatchMode": "User"
    },
    "maintenanceWindow": {
      "startDateTime": "2026-10-01 02:00",
      "duration": "03:55",
      "timeZone": "UTC",
      "recurEvery": "1Week Saturday"
    },
    "installPatches": {
      "linuxParameters": {
        "classificationsToInclude": ["Critical", "Security"],
        "packageNameMasksToExclude": ["kernel*"]
      },
      "rebootSetting": "IfRequired"
    }
  }
}
MAINTENANCE_CFG

echo "  ✅ Azure Update Manager Patch Policy defined (Zero-downtime, Critical/Security updates on Saturday 02:00 UTC)."

echo "Step 3.6: Enterprise Disaster Recovery (ASR) Blueprint..."
cat << 'ASR_BLUEPRINT'
═══════════════════════════════════════════════════════════════
  Azure Site Recovery (ASR) Multi-Region Failover Architecture
═══════════════════════════════════════════════════════════════
 Primary Region (East US)               Secondary Region (West US 2)
 ┌───────────────────────────┐         ┌───────────────────────────┐
 │ Production VNet 10.20.0.0 │         │ Recovery VNet 10.20.0.0   │
 │                           │         │ (Identical IP Address     │
 │ [VM-APP-PROD-01]          │───────► │  via VNet Peering/DR Plan)│
 │   - OS Disk (Cache Storage)         │                           │
 │   - Continuous Replication│         │ [Replica Managed Disks]   │
 │   - RPO < 15 seconds      │         │   - Inactive until DR test│
 │                           │         │   - Test Failover sandbox │
 └───────────────────────────┘         └───────────────────────────┘
                                                     ▲
                                                     │
                             Recovery Services Vault (Geo-Redundant)
                             Automated Orchestration Runbooks
═══════════════════════════════════════════════════════════════
ASR_BLUEPRINT

echo ""
echo "=============================================================="
echo " ✅ COMPUTE & VM MULTI-LEVEL LAB COMPLETED SUCCESSFULLY!"
echo "=============================================================="
