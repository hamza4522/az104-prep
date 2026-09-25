# 🌐 Lab 01 — VNet, Subnets & Network Security Groups (NSGs)

**Difficulty:** 🟢 Beginner-Intermediate  
**Time:** 75 minutes  
**Goal:** Build a production-grade VNet with subnets, NSGs, and proper network segmentation

---

## Architecture

```
VNet: 10.0.0.0/16
├── subnet-public      10.0.1.0/24   (web servers, load balancers)
├── subnet-private     10.0.2.0/24   (application servers — no direct internet)
├── subnet-data        10.0.3.0/24   (databases — most restrictive)
├── subnet-management  10.0.4.0/24   (bastion, jump boxes)
└── AzureBastionSubnet 10.0.5.0/26   (Azure Bastion — MUST use this name)
```

## AWS vs Azure Networking Mapping

```
AWS VPC (10.0.0.0/16)               Azure VNet (10.0.0.0/16)
├── Public Subnet + IGW              ├── Public Subnet (internet via default route)
├── Private Subnet + NAT GW          ├── Private Subnet + NAT Gateway
├── Security Groups (stateful)       ├── NSG (stateful) — applied to subnet or NIC
├── NACLs (stateless)                ├── No equivalent — use NSG for both
├── Route Tables                     ├── Route Tables (UDR — User Defined Routes)
└── VPC Flow Logs                    └── NSG Flow Logs + Network Watcher
```

---

## Part 1 — Create VNet and Subnets

```bash
# Set variables
RG="rg-networking-lab"
LOCATION="eastus"
VNET_NAME="vnet-prod-eastus"
VNET_PREFIX="10.0.0.0/16"

# Create resource group
az group create \
  --name $RG \
  --location $LOCATION \
  --tags Environment=Lab Project=Networking

# Create VNet with primary address space
az network vnet create \
  --resource-group $RG \
  --name $VNET_NAME \
  --location $LOCATION \
  --address-prefixes $VNET_PREFIX \
  --tags Environment=Lab Project=Networking

# Verify
az network vnet show \
  --resource-group $RG \
  --name $VNET_NAME \
  --output json

# =========================================
# Create all subnets
# =========================================

# Public subnet (web tier)
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name subnet-public \
  --address-prefixes 10.0.1.0/24

# Private subnet (app tier)
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name subnet-private \
  --address-prefixes 10.0.2.0/24

# Data subnet (database tier)
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name subnet-data \
  --address-prefixes 10.0.3.0/24

# Management subnet
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name subnet-management \
  --address-prefixes 10.0.4.0/24

# Azure Bastion subnet (MUST be named AzureBastionSubnet, /26 minimum)
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name AzureBastionSubnet \
  --address-prefixes 10.0.5.0/26

# List all subnets
az network vnet subnet list \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --output table

# =========================================
# Add ADDITIONAL address space (Azure VNets support multiple!)
# (Like adding a secondary CIDR to an AWS VPC)
# =========================================
az network vnet update \
  --resource-group $RG \
  --name $VNET_NAME \
  --add addressSpace.addressPrefixes "172.16.0.0/24"

# Add subnet in the new address space
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name subnet-expanded \
  --address-prefixes 172.16.0.0/24
```

---

## Part 2 — Network Security Groups (NSGs)

> NSGs are stateful firewalls (like AWS Security Groups)  
> They can be applied to:  
> 1. A subnet (all resources in subnet)  
> 2. A NIC (individual VM)  
> Best practice: Apply at SUBNET level primarily

```bash
# =========================================
# NSG for Public Subnet (web tier)
# Allow: HTTP (80), HTTPS (443), SSH from management only
# Deny: everything else
# =========================================

az network nsg create \
  --resource-group $RG \
  --name nsg-public \
  --location $LOCATION \
  --tags Environment=Lab Tier=Public

# Allow inbound HTTP (from internet)
az network nsg rule create \
  --resource-group $RG \
  --nsg-name nsg-public \
  --name Allow-HTTP-Inbound \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "*" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 80 \
  --description "Allow HTTP from internet"

# Allow inbound HTTPS (from internet)
az network nsg rule create \
  --resource-group $RG \
  --nsg-name nsg-public \
  --name Allow-HTTPS-Inbound \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "*" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 443 \
  --description "Allow HTTPS from internet"

# Allow SSH only from management subnet
az network nsg rule create \
  --resource-group $RG \
  --nsg-name nsg-public \
  --name Allow-SSH-From-Management \
  --priority 200 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes 10.0.4.0/24 \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 22 \
  --description "Allow SSH from management subnet only"

# Allow Azure Load Balancer probes (REQUIRED or health probes fail!)
az network nsg rule create \
  --resource-group $RG \
  --nsg-name nsg-public \
  --name Allow-Azure-LB \
  --priority 300 \
  --direction Inbound \
  --access Allow \
  --protocol "*" \
  --source-address-prefixes AzureLoadBalancer \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges "*" \
  --description "Allow Azure Load Balancer health probes"

# Deny ALL other inbound (explicit deny — lower priority wins = higher number)
az network nsg rule create \
  --resource-group $RG \
  --nsg-name nsg-public \
  --name Deny-All-Inbound \
  --priority 4096 \
  --direction Inbound \
  --access Deny \
  --protocol "*" \
  --source-address-prefixes "*" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges "*" \
  --description "Deny all other inbound"

# View NSG rules
az network nsg rule list \
  --resource-group $RG \
  --nsg-name nsg-public \
  --output table

echo "✅ NSG for public subnet created"
```

```bash
# =========================================
# NSG for Private Subnet (app tier)
# Allow: inbound from public subnet only on app port
# Allow: outbound to data subnet on DB ports
# =========================================

az network nsg create \
  --resource-group $RG \
  --name nsg-private \
  --location $LOCATION

# Allow inbound from web/public tier
az network nsg rule create \
  --resource-group $RG \
  --nsg-name nsg-private \
  --name Allow-From-Public-Tier \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes 10.0.1.0/24 \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges "8080-8090"

# Allow SSH from management only
az network nsg rule create \
  --resource-group $RG \
  --nsg-name nsg-private \
  --name Allow-SSH-From-Mgmt \
  --priority 200 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes 10.0.4.0/24 \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 22

az network nsg rule create \
  --resource-group $RG \
  --nsg-name nsg-private \
  --name Allow-Azure-LB \
  --priority 300 \
  --direction Inbound \
  --access Allow \
  --protocol "*" \
  --source-address-prefixes AzureLoadBalancer \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges "*"

az network nsg rule create \
  --resource-group $RG \
  --nsg-name nsg-private \
  --name Deny-All-Inbound \
  --priority 4096 \
  --direction Inbound \
  --access Deny \
  --protocol "*" \
  --source-address-prefixes "*" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges "*"

echo "✅ NSG for private subnet created"
```

```bash
# =========================================
# NSG for Data Subnet (database tier)
# Most restrictive — only allow DB ports from app tier
# =========================================

az network nsg create \
  --resource-group $RG \
  --name nsg-data \
  --location $LOCATION

# SQL Server from app tier only
az network nsg rule create \
  --resource-group $RG \
  --nsg-name nsg-data \
  --name Allow-SQL-From-App \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes 10.0.2.0/24 \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 1433

# MySQL from app tier
az network nsg rule create \
  --resource-group $RG \
  --nsg-name nsg-data \
  --name Allow-MySQL-From-App \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes 10.0.2.0/24 \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 3306

# PostgreSQL from app tier
az network nsg rule create \
  --resource-group $RG \
  --nsg-name nsg-data \
  --name Allow-Postgres-From-App \
  --priority 120 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes 10.0.2.0/24 \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 5432

# Deny all other inbound to data tier
az network nsg rule create \
  --resource-group $RG \
  --nsg-name nsg-data \
  --name Deny-All-Inbound \
  --priority 4096 \
  --direction Inbound \
  --access Deny \
  --protocol "*" \
  --source-address-prefixes "*" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges "*"

echo "✅ NSG for data subnet created"
```

---

## Part 3 — Associate NSGs with Subnets

```bash
# Associate NSG with subnet (like attaching NACL in AWS)
az network vnet subnet update \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name subnet-public \
  --network-security-group nsg-public

az network vnet subnet update \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name subnet-private \
  --network-security-group nsg-private

az network vnet subnet update \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name subnet-data \
  --network-security-group nsg-data

# Verify subnet-NSG associations
az network vnet subnet list \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --query "[].{Subnet:name, AddressPrefix:addressPrefix, NSG:networkSecurityGroup.id}" \
  --output table

echo "✅ NSGs associated with subnets"
```

---

## Part 4 — User Defined Routes (UDR) / Route Tables

> UDR = AWS Route Tables = GCP Routes  
> Force traffic through a firewall or NVA (Network Virtual Appliance)

```bash
# Create a route table for private subnet
# Force all internet traffic through Azure Firewall (or NVA)
az network route-table create \
  --resource-group $RG \
  --name rt-private \
  --location $LOCATION \
  --disable-bgp-route-propagation true  # Block BGP routes from VPN/ExpressRoute

# Add a route: force internet traffic to Azure Firewall
# (Firewall private IP — replace with actual value)
FIREWALL_PRIVATE_IP="10.0.0.4"  # Replace with actual firewall IP

az network route-table route create \
  --resource-group $RG \
  --route-table-name rt-private \
  --name route-to-internet \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address $FIREWALL_PRIVATE_IP

# Add a route: force data subnet traffic through firewall
az network route-table route create \
  --resource-group $RG \
  --route-table-name rt-private \
  --name route-to-data-subnet \
  --address-prefix 10.0.3.0/24 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address $FIREWALL_PRIVATE_IP

# Special routes for Azure services (bypass firewall)
az network route-table route create \
  --resource-group $RG \
  --route-table-name rt-private \
  --name route-azure-monitor \
  --address-prefix 168.63.129.16/32 \
  --next-hop-type Internet  # Allow Azure health probes directly

# Associate route table with subnet
az network vnet subnet update \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name subnet-private \
  --route-table rt-private

# View effective routes for a NIC (after deploying a VM)
# az network nic show-effective-route-table --resource-group $RG --name <nic-name>

echo "✅ Route table created and associated"
```

---

## Part 5 — NAT Gateway

> For outbound internet from private subnets (no inbound)
> Like AWS NAT Gateway

```bash
# Create a public IP for NAT Gateway
az network public-ip create \
  --resource-group $RG \
  --name pip-natgw \
  --location $LOCATION \
  --sku Standard \
  --allocation-method Static \
  --zone 1 2 3

# Create NAT Gateway
az network nat gateway create \
  --resource-group $RG \
  --name natgw-private \
  --location $LOCATION \
  --public-ip-addresses pip-natgw \
  --idle-timeout 10

# Associate NAT Gateway with private subnet
az network vnet subnet update \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name subnet-private \
  --nat-gateway natgw-private

# Check the NAT gateway
az network nat gateway show \
  --resource-group $RG \
  --name natgw-private \
  --output json

echo "✅ NAT Gateway created and associated with private subnet"
```

---

## Part 6 — Deploy Test VMs to Validate Connectivity

```bash
# Deploy a VM in public subnet
az vm create \
  --resource-group $RG \
  --name vm-web-01 \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --vnet-name $VNET_NAME \
  --subnet subnet-public \
  --public-ip-address pip-web-01 \
  --nsg "" \
  --size Standard_B1s \
  --no-wait

# Deploy a VM in private subnet (no public IP)
az vm create \
  --resource-group $RG \
  --name vm-app-01 \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --vnet-name $VNET_NAME \
  --subnet subnet-private \
  --public-ip-address "" \
  --nsg "" \
  --size Standard_B1s \
  --no-wait

echo "Waiting for VMs to provision..."
az vm wait --resource-group $RG --name vm-web-01 --created
az vm wait --resource-group $RG --name vm-app-01 --created

# Get public IP of web VM
WEB_IP=$(az vm show --resource-group $RG --name vm-web-01 \
  --show-details --query publicIps --output tsv)
echo "Web VM Public IP: $WEB_IP"

# Get private IP of app VM
APP_PRIVATE_IP=$(az vm show --resource-group $RG --name vm-app-01 \
  --show-details --query privateIps --output tsv)
echo "App VM Private IP: $APP_PRIVATE_IP"

# SSH to web VM (in public subnet)
ssh azureuser@$WEB_IP

# From web VM, try to reach app VM (should work — same VNet)
# ping $APP_PRIVATE_IP
# curl $APP_PRIVATE_IP:8080
```

---

## Part 7 — NSG Flow Logs (Traffic Analysis)

```bash
# Enable NSG flow logs (like VPC Flow Logs in AWS)
# Requires a storage account and Network Watcher

# Create storage account for flow logs
az storage account create \
  --resource-group $RG \
  --name "stflowlogs$(date +%s)" \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2

STORAGE_ID=$(az storage account list --resource-group $RG \
  --query "[?contains(name,'stflowlogs')].id" --output tsv)

NSG_ID=$(az network nsg show --resource-group $RG --name nsg-public --query id --output tsv)

# Enable Network Watcher (if not already enabled)
az network watcher configure \
  --resource-group NetworkWatcherRG \
  --location $LOCATION \
  --enabled true

# Create NSG flow logs
az network watcher flow-log create \
  --resource-group NetworkWatcherRG \
  --name flowlog-nsg-public \
  --nsg $NSG_ID \
  --storage-account $STORAGE_ID \
  --interval 10 \
  --traffic-analytics true \
  --workspace "$(az monitor log-analytics workspace list --query '[0].id' --output tsv)" \
  --retention 30

echo "✅ NSG Flow Logs enabled"
```

---

## Part 8 — Effective Security Rules (Troubleshooting)

```bash
# Check effective NSG rules for a specific VM NIC
# (Combines subnet-level AND NIC-level NSG rules)
NIC_NAME=$(az vm nic list --resource-group $RG --vm-name vm-web-01 --query "[0].id" --output tsv | cut -d/ -f9)

az network nic list-effective-nsg \
  --resource-group $RG \
  --name $NIC_NAME \
  --output table

# Test network connectivity
az network watcher check-connectivity \
  --resource-group $RG \
  --source-resource vm-web-01 \
  --dest-resource vm-app-01 \
  --protocol Tcp \
  --dest-port 8080

# Check IP flow (like checking Security Group rules)
az network watcher test-ip-flow \
  --vm vm-web-01 \
  --resource-group $RG \
  --direction Inbound \
  --protocol TCP \
  --local 10.0.1.4:80 \
  --remote 1.2.3.4:12345
```

---

## Cleanup

```bash
echo "Cleaning up networking lab resources..."
az group delete --name rg-networking-lab --yes --no-wait
echo "Cleanup initiated!"
```

---

## ✅ Lab Checklist

- [ ] Created VNet with multiple address spaces
- [ ] Created 5 subnets (public, private, data, management, bastion)
- [ ] Created NSGs for each tier with appropriate rules
- [ ] Applied NSG service tags (AzureLoadBalancer)
- [ ] Associated NSGs with subnets
- [ ] Created UDR to force traffic through NVA
- [ ] Created NAT Gateway for private subnet internet access
- [ ] Deployed VMs in public and private subnets
- [ ] Enabled NSG Flow Logs
- [ ] Used Network Watcher for troubleshooting

---

## 📚 Key Differences: Azure NSG vs AWS Security Groups

| Feature | Azure NSG | AWS Security Group |
|---|---|---|
| Applied at | Subnet OR NIC | Instance (NIC) |
| Default outbound | All traffic allowed | All traffic allowed |
| Default inbound | All traffic denied (VNet allowed) | All traffic denied |
| Priority | Lower number = higher priority | Rules evaluated, most specific wins |
| Deny rules | YES — explicit deny possible | NO — only allow rules |
| Service tags | YES — AzureLoadBalancer, Internet, VirtualNetwork | NO |
| Application tags | YES — ASG (Application Security Groups) | NO |
| Stateful | YES | YES |
