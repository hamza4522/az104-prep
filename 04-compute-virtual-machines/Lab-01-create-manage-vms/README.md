# 🖥️ Lab 01 — Create and Manage Virtual Machines

**Difficulty:** 🟢 Beginner-Intermediate  
**Time:** 75 minutes  
**Goal:** Create, configure, connect, resize, and manage Azure VMs via CLI and Portal

---

## Part 1 — Create Your First VM

```bash
# Setup
RG="rg-vm-lab"
LOCATION="eastus"

az group create --name $RG --location $LOCATION

# =========================================
# Create a Linux VM (Ubuntu)
# =========================================
az vm create \
  --resource-group $RG \
  --name vm-linux-web \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --public-ip-address pip-linux-web \
  --vnet-name vnet-lab \
  --subnet subnet-default \
  --nsg nsg-linux-web \
  --tags Environment=Lab OS=Linux Role=Web \
  --no-wait

# Available images
az vm image list --output table                    # Popular images (cached)
az vm image list --all --publisher Canonical       # All Ubuntu images
az vm image list --all --publisher MicrosoftWindowsServer  # All Windows Server
az vm image list --all --publisher RedHat          # RHEL images
az vm image list --all --publisher OpenLogic       # CentOS/AlmaLinux

# Get specific image URN
az vm image list \
  --publisher Canonical \
  --offer 0001-com-ubuntu-server-jammy \
  --sku 22_04-lts-gen2 \
  --all \
  --query "[].urn" \
  --output table

# =========================================
# Create a Windows VM
# =========================================
az vm create \
  --resource-group $RG \
  --name vm-windows-app \
  --image Win2022Datacenter \
  --size Standard_D2s_v3 \
  --admin-username azureAdmin \
  --admin-password "SecureP@ss2024!" \
  --public-ip-sku Standard \
  --tags Environment=Lab OS=Windows Role=App

# Wait for both VMs to be created
az vm wait --resource-group $RG --name vm-linux-web --created
echo "✅ Linux VM created"

az vm wait --resource-group $RG --name vm-windows-app --created
echo "✅ Windows VM created"
```

---

## Part 2 — VM Sizes and Information

```bash
# List available VM sizes in a region
az vm list-sizes --location eastus --output table

# Find sizes with specific vCPUs
az vm list-sizes --location eastus \
  --query "[?numberOfCores==`4`].{Size:name, vCPUs:numberOfCores, RAM:memoryInMb, Disk:resourceDiskSizeInMb}" \
  --output table

# List VM series
az vm list-sizes --location eastus \
  --query "[?starts_with(name,'Standard_D')].{Size:name, vCPUs:numberOfCores, RAM:memoryInMb}" \
  --output table

# Get current VM details
az vm show \
  --resource-group $RG \
  --name vm-linux-web \
  --output json

# Get VM status (power state)
az vm show \
  --resource-group $RG \
  --name vm-linux-web \
  --show-details \
  --query "{Name:name, PowerState:powerState, PublicIP:publicIps, PrivateIP:privateIps, Size:hardwareProfile.vmSize}" \
  --output json

# List ALL VMs across subscription
az vm list --output table
az vm list --all --output table  # includes powered off

# List with power state
az vm list \
  --resource-group $RG \
  --show-details \
  --query "[].{Name:name, State:powerState, Size:hardwareProfile.vmSize}" \
  --output table
```

---

## Part 3 — Connect to VMs

```bash
# =========================================
# Connect to Linux VM via SSH
# =========================================

# Get public IP
LINUX_IP=$(az vm show --resource-group $RG --name vm-linux-web \
  --show-details --query publicIps --output tsv)
echo "Linux VM IP: $LINUX_IP"

# SSH in (private key auto-generated to ~/.ssh/)
ssh azureuser@$LINUX_IP

# If you generated SSH key manually:
ssh -i ~/.ssh/id_rsa azureuser@$LINUX_IP

# Run remote command without full SSH session
ssh azureuser@$LINUX_IP "uname -a && df -h && free -h"

# =========================================
# Connect to Windows VM via RDP
# =========================================

# Get public IP
WIN_IP=$(az vm show --resource-group $RG --name vm-windows-app \
  --show-details --query publicIps --output tsv)
echo "Windows VM IP: $WIN_IP"

# Open RDP connection (Windows)
mstsc /v:$WIN_IP

# macOS: use Microsoft Remote Desktop app

# Azure CLI: Open RDP file
az vm open-port --resource-group $RG --name vm-windows-app --port 3389

# =========================================
# Run commands directly via Azure CLI (without SSH/RDP)
# Equivalent to AWS SSM Run Command
# =========================================

# Run shell command on Linux VM
az vm run-command invoke \
  --resource-group $RG \
  --name vm-linux-web \
  --command-id RunShellScript \
  --scripts "echo 'Hello from Azure CLI!' && uname -a && uptime"

# Run PowerShell on Windows VM
az vm run-command invoke \
  --resource-group $RG \
  --name vm-windows-app \
  --command-id RunPowerShellScript \
  --scripts "Get-ComputerInfo | Select-Object CsName, OsVersion, OsArchitecture"

# Run a script file
az vm run-command invoke \
  --resource-group $RG \
  --name vm-linux-web \
  --command-id RunShellScript \
  --scripts @install-nginx.sh

# List available run commands
az vm run-command list --location eastus --output table
```

---

## Part 4 — VM Lifecycle Management

```bash
# =========================================
# Start / Stop / Restart / Deallocate
# =========================================

# Stop and deallocate VM (billing stops for compute — like stopping EC2)
az vm deallocate \
  --resource-group $RG \
  --name vm-linux-web

# Just power off (OS shutdown, but compute billing CONTINUES — like stopping GCP VM)
az vm stop \
  --resource-group $RG \
  --name vm-linux-web

# Start VM
az vm start \
  --resource-group $RG \
  --name vm-linux-web

# Restart VM
az vm restart \
  --resource-group $RG \
  --name vm-linux-web

# Redeploy VM (move to different host node — troubleshooting)
az vm redeploy \
  --resource-group $RG \
  --name vm-linux-web

# Check VM status
az vm get-instance-view \
  --resource-group $RG \
  --name vm-linux-web \
  --query "instanceView.statuses[1].displayStatus" \
  --output tsv

# Bulk operations
az vm start --ids $(az vm list --resource-group $RG --query "[].id" --output tsv)
az vm deallocate --ids $(az vm list --resource-group $RG --query "[].id" --output tsv)
```

---

## Part 5 — Resize a VM

```bash
# List sizes available for resize (not all sizes available in all regions/zones)
az vm list-vm-resize-options \
  --resource-group $RG \
  --name vm-linux-web \
  --output table

# Resize VM (requires deallocation if changing across VM families)
az vm resize \
  --resource-group $RG \
  --name vm-linux-web \
  --size Standard_D2s_v3

# If resize fails (cross-family), deallocate first:
az vm deallocate --resource-group $RG --name vm-linux-web
az vm resize --resource-group $RG --name vm-linux-web --size Standard_E2s_v3
az vm start --resource-group $RG --name vm-linux-web
```

---

## Part 6 — VM Disks Management

```bash
# View current disk configuration
az vm show \
  --resource-group $RG \
  --name vm-linux-web \
  --query "storageProfile" \
  --output json

# Add a data disk to existing VM
az vm disk attach \
  --resource-group $RG \
  --vm-name vm-linux-web \
  --name disk-data-01 \
  --new \
  --size-gb 128 \
  --sku Premium_LRS

# List disks
az disk list --resource-group $RG --output table

# Resize OS disk (must deallocate first)
az vm deallocate --resource-group $RG --name vm-linux-web

OS_DISK_NAME=$(az vm show --resource-group $RG --name vm-linux-web \
  --query "storageProfile.osDisk.name" --output tsv)

az disk update \
  --resource-group $RG \
  --name $OS_DISK_NAME \
  --size-gb 64

az vm start --resource-group $RG --name vm-linux-web

# On the VM: extend the filesystem after disk resize
# sudo growpart /dev/sda 1
# sudo resize2fs /dev/sda1

# Create disk snapshot (backup)
az snapshot create \
  --resource-group $RG \
  --name snap-linux-web-$(date +%Y%m%d) \
  --source $OS_DISK_NAME \
  --incremental true

# Create disk from snapshot (restore)
az disk create \
  --resource-group $RG \
  --name disk-restored-01 \
  --source snap-linux-web-$(date +%Y%m%d) \
  --sku Premium_LRS

# Detach a data disk
az vm disk detach \
  --resource-group $RG \
  --vm-name vm-linux-web \
  --name disk-data-01

# Delete a disk
az disk delete --resource-group $RG --name disk-data-01 --yes
```

---

## Part 7 — VM Extensions (User Data / Cloud-Init equivalent)

```bash
# =========================================
# Method 1: cloud-init (for Linux VMs)
# Runs at first boot — like EC2 user data
# =========================================

cat > cloud-init.yml << 'EOF'
#cloud-config
package_upgrade: true
packages:
  - nginx
  - git
  - curl
  - htop
  - docker.io

runcmd:
  - systemctl enable nginx
  - systemctl start nginx
  - systemctl enable docker
  - systemctl start docker
  - usermod -aG docker azureuser
  - echo "Custom VM configured at $(date)" > /var/www/html/index.html
  - echo "<h1>Hello from Azure VM!</h1><p>Hostname: $(hostname)</p>" > /var/www/html/index.html

write_files:
  - path: /etc/nginx/conf.d/default.conf
    content: |
      server {
        listen 80;
        server_name _;
        root /var/www/html;
        index index.html;
      }
EOF

# Create VM with cloud-init
az vm create \
  --resource-group $RG \
  --name vm-cloudinit \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data cloud-init.yml \
  --public-ip-sku Standard

# Wait for VM and open port 80
az vm open-port --resource-group $RG --name vm-cloudinit --port 80

VM_IP=$(az vm show --resource-group $RG --name vm-cloudinit \
  --show-details --query publicIps --output tsv)

echo "VM IP: $VM_IP"
echo "Check: http://$VM_IP"

# =========================================
# Method 2: Custom Script Extension
# Runs scripts after VM is created
# Like AWS SSM Run Command but persistent
# =========================================

# Create a setup script
cat > setup-webserver.sh << 'EOF'
#!/bin/bash
apt-get update -y
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx

cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head><title>Azure VM Lab</title></head>
<body>
  <h1>Hello from Azure!</h1>
  <p>Hostname: $(hostname)</p>
  <p>IP: $(hostname -I)</p>
  <p>Date: $(date)</p>
</body>
</html>
HTML
EOF

# Upload script to storage (or use raw GitHub URL)
STORAGE_ACCOUNT="mystoragelab$(date +%s)"
az storage account create \
  --resource-group $RG \
  --name $STORAGE_ACCOUNT \
  --location $LOCATION \
  --sku Standard_LRS

az storage container create \
  --account-name $STORAGE_ACCOUNT \
  --name scripts

az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --container-name scripts \
  --name setup-webserver.sh \
  --file setup-webserver.sh

# Get storage account key
STORAGE_KEY=$(az storage account keys list \
  --resource-group $RG \
  --account-name $STORAGE_ACCOUNT \
  --query "[0].value" \
  --output tsv)

# Apply Custom Script Extension
az vm extension set \
  --resource-group $RG \
  --vm-name vm-linux-web \
  --name CustomScript \
  --publisher Microsoft.Azure.Extensions \
  --settings "{'fileUris': ['https://${STORAGE_ACCOUNT}.blob.core.windows.net/scripts/setup-webserver.sh']}" \
  --protected-settings "{'commandToExecute': 'bash setup-webserver.sh', 'storageAccountName': '${STORAGE_ACCOUNT}', 'storageAccountKey': '${STORAGE_KEY}'}"

# List extensions on a VM
az vm extension list --resource-group $RG --vm-name vm-linux-web --output table

# Get extension status
az vm extension show \
  --resource-group $RG \
  --vm-name vm-linux-web \
  --name CustomScript \
  --output json
```

---

## Part 8 — VM Networking

```bash
# Get VM's NIC details
NIC_ID=$(az vm show --resource-group $RG --name vm-linux-web \
  --query "networkProfile.networkInterfaces[0].id" --output tsv)

NIC_NAME=$(echo $NIC_ID | cut -d/ -f9)
echo "NIC Name: $NIC_NAME"

az network nic show --ids $NIC_ID --output json

# Get effective security rules
az network nic list-effective-nsg \
  --resource-group $RG \
  --name $NIC_NAME \
  --output table

# Add a secondary NIC
az network nic create \
  --resource-group $RG \
  --name nic-secondary \
  --vnet-name vnet-lab \
  --subnet subnet-default

az vm nic add \
  --resource-group $RG \
  --vm-name vm-linux-web \
  --nics nic-secondary

# Open specific ports via CLI
az vm open-port --resource-group $RG --name vm-linux-web --port 80
az vm open-port --resource-group $RG --name vm-linux-web --port 443
az vm open-port --resource-group $RG --name vm-linux-web --port 8080

# Get public IP
az network public-ip show \
  --resource-group $RG \
  --name pip-linux-web \
  --query "{IP:ipAddress, AllocationMethod:publicIPAllocationMethod, Sku:sku.name}" \
  --output json
```

---

## Part 9 — VM Tags and Metadata

```bash
# Tag a VM
az vm update \
  --resource-group $RG \
  --name vm-linux-web \
  --set tags.Environment=Lab tags.Role=Web tags.Owner=DevOps tags.CostCenter=CC-001

# Get all VMs with specific tag
az vm list \
  --query "[?tags.Environment=='Lab'].{Name:name, RG:resourceGroup, State:powerState}" \
  --output table

# Get VM metadata from within the VM (IMDS — Instance Metadata Service)
# Like AWS http://169.254.169.254/latest/meta-data/
# From inside VM:
curl -s -H "Metadata: true" \
  "http://169.254.169.254/metadata/instance?api-version=2021-12-13" \
  | python3 -m json.tool

# Get specific metadata
curl -s -H "Metadata: true" \
  "http://169.254.169.254/metadata/instance/compute/location?api-version=2021-12-13&format=text"
```

---

## Part 10 — VM Automation Script (Full Setup)

```bash
#!/bin/bash
# Script: create-web-server.sh
# Creates a fully configured web server VM with all best practices

set -e

RG="rg-webserver-prod"
LOCATION="eastus"
VM_NAME="vm-web-prod-01"
VNET_NAME="vnet-prod"
SUBNET_NAME="subnet-web"
VM_SIZE="Standard_D2s_v3"
ADMIN_USER="azureuser"

echo "=== Creating Resource Group ==="
az group create --name $RG --location $LOCATION --tags Environment=Production Role=Web

echo "=== Creating VNet and Subnet ==="
az network vnet create \
  --resource-group $RG \
  --name $VNET_NAME \
  --address-prefixes 10.0.0.0/16

az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name $SUBNET_NAME \
  --address-prefixes 10.0.1.0/24

echo "=== Creating NSG ==="
az network nsg create --resource-group $RG --name nsg-web

az network nsg rule create \
  --resource-group $RG --nsg-name nsg-web \
  --name Allow-HTTP --priority 100 --direction Inbound \
  --access Allow --protocol Tcp \
  --destination-port-ranges 80 443

az network vnet subnet update \
  --resource-group $RG --vnet-name $VNET_NAME \
  --name $SUBNET_NAME --network-security-group nsg-web

echo "=== Creating VM ==="
az vm create \
  --resource-group $RG \
  --name $VM_NAME \
  --image Ubuntu2204 \
  --size $VM_SIZE \
  --admin-username $ADMIN_USER \
  --generate-ssh-keys \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_NAME \
  --public-ip-sku Standard \
  --assign-identity \
  --custom-data cloud-init.yml \
  --tags Environment=Production Role=Web ManagedBy=DevOps

echo "=== Getting VM Details ==="
VM_IP=$(az vm show --resource-group $RG --name $VM_NAME \
  --show-details --query publicIps --output tsv)

echo ""
echo "=== ✅ VM Created Successfully ==="
echo "Name: $VM_NAME"
echo "IP:   $VM_IP"
echo "SSH:  ssh $ADMIN_USER@$VM_IP"
echo "URL:  http://$VM_IP"
```

---

## Cleanup

```bash
az group delete --name rg-vm-lab --yes --no-wait
az group delete --name rg-webserver-prod --yes --no-wait
echo "Cleanup initiated!"
```

---

## ✅ Lab Checklist

- [ ] Created Linux VM with SSH key
- [ ] Created Windows VM with password
- [ ] Listed available VM images and sizes
- [ ] Connected via SSH to Linux VM
- [ ] Used `az vm run-command` to run scripts without SSH
- [ ] Started, stopped, deallocated, and restarted VMs
- [ ] Resized a VM
- [ ] Added and managed data disks
- [ ] Created disk snapshot
- [ ] Used cloud-init for bootstrap configuration
- [ ] Used Custom Script Extension
- [ ] Explored VM Instance Metadata Service (IMDS)

---

## 📚 Key Differences: Azure VM vs EC2

| Feature | Azure VM | AWS EC2 |
|---|---|---|
| Billing stop | `deallocate` command | `stop` command |
| User data | cloud-init / Custom Script Extension | EC2 user data |
| Key pairs | Per-VM SSH keys (stored locally) | Region-level key pairs |
| Temp disk | Always included (ephemeral) | Only some instance types |
| Disk resize | Requires deallocation | Online resize supported |
| VM metadata | IMDS at 169.254.169.254 | IMDS at 169.254.169.254 (same!) |
| Remote management | Azure Run Command | AWS SSM Session Manager |
| Maintenance | Azure planned maintenance | AWS maintenance windows |
