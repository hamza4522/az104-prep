# 🌐 Advanced Networking

## Labs in This Section

| Lab | Title | Difficulty |
|---|---|---|
| Lab-01 | VNet Peering & Hub-Spoke Topology | 🔴 |
| Lab-02 | Azure Application Gateway & WAF | 🔴 |
| Lab-03 | Azure Front Door — Global Load Balancing | ⭐ |
| Lab-04 | Azure Private Link & Private Endpoints | 🔴 |
| Lab-05 | Azure DNS — Public & Private Zones | 🟡 |

---

## Lab 01 — VNet Peering & Hub-Spoke Topology

```bash
RG="rg-networking-advanced"
LOCATION="eastus"

az group create --name $RG --location $LOCATION

# =========================================
# Create Hub-Spoke Topology
# (Like AWS Transit Gateway concept)
# =========================================

# Hub VNet (shared services, firewall, gateway)
az network vnet create \
  --resource-group $RG \
  --name vnet-hub \
  --address-prefixes 10.0.0.0/16 \
  --location $LOCATION

az network vnet subnet create \
  --resource-group $RG --vnet-name vnet-hub \
  --name AzureFirewallSubnet --address-prefixes 10.0.0.0/26

az network vnet subnet create \
  --resource-group $RG --vnet-name vnet-hub \
  --name GatewaySubnet --address-prefixes 10.0.1.0/27

az network vnet subnet create \
  --resource-group $RG --vnet-name vnet-hub \
  --name AzureBastionSubnet --address-prefixes 10.0.2.0/26

# Spoke 1 — Production workload
az network vnet create \
  --resource-group $RG \
  --name vnet-spoke-prod \
  --address-prefixes 10.1.0.0/16

az network vnet subnet create \
  --resource-group $RG --vnet-name vnet-spoke-prod \
  --name subnet-app --address-prefixes 10.1.1.0/24

# Spoke 2 — Development workload
az network vnet create \
  --resource-group $RG \
  --name vnet-spoke-dev \
  --address-prefixes 10.2.0.0/16

az network vnet subnet create \
  --resource-group $RG --vnet-name vnet-spoke-dev \
  --name subnet-app --address-prefixes 10.2.1.0/24

# Spoke 3 — Shared services (AKS, databases)
az network vnet create \
  --resource-group $RG \
  --name vnet-spoke-shared \
  --address-prefixes 10.3.0.0/16

# =========================================
# Create VNet Peerings (Hub ↔ Each Spoke)
# NOTE: Azure peering is NOT transitive!
# Spoke-to-Spoke traffic must go through Hub
# =========================================

# Hub → Spoke Prod
az network vnet peering create \
  --resource-group $RG \
  --name peer-hub-to-prod \
  --vnet-name vnet-hub \
  --remote-vnet vnet-spoke-prod \
  --allow-vnet-access \
  --allow-forwarded-traffic \
  --allow-gateway-transit  # Allow spokes to use hub's VPN gateway

# Spoke Prod → Hub
az network vnet peering create \
  --resource-group $RG \
  --name peer-prod-to-hub \
  --vnet-name vnet-spoke-prod \
  --remote-vnet vnet-hub \
  --allow-vnet-access \
  --allow-forwarded-traffic \
  --use-remote-gateways  # Use hub's VPN gateway

# Hub → Spoke Dev
az network vnet peering create \
  --resource-group $RG \
  --name peer-hub-to-dev \
  --vnet-name vnet-hub \
  --remote-vnet vnet-spoke-dev \
  --allow-vnet-access \
  --allow-forwarded-traffic \
  --allow-gateway-transit

# Spoke Dev → Hub
az network vnet peering create \
  --resource-group $RG \
  --name peer-dev-to-hub \
  --vnet-name vnet-spoke-dev \
  --remote-vnet vnet-hub \
  --allow-vnet-access \
  --allow-forwarded-traffic \
  --use-remote-gateways

# Hub → Spoke Shared
az network vnet peering create \
  --resource-group $RG \
  --name peer-hub-to-shared \
  --vnet-name vnet-hub \
  --remote-vnet vnet-spoke-shared \
  --allow-vnet-access \
  --allow-forwarded-traffic

az network vnet peering create \
  --resource-group $RG \
  --name peer-shared-to-hub \
  --vnet-name vnet-spoke-shared \
  --remote-vnet vnet-hub \
  --allow-vnet-access

# List all peerings
az network vnet peering list --resource-group $RG --vnet-name vnet-hub --output table
az network vnet peering list --resource-group $RG --vnet-name vnet-spoke-prod --output table

echo "✅ Hub-Spoke topology created!"
echo ""
echo "Topology:"
echo "  vnet-hub (10.0.0.0/16) — Azure Firewall, Bastion, VPN Gateway"
echo "  ├── vnet-spoke-prod (10.1.0.0/16)"
echo "  ├── vnet-spoke-dev (10.2.0.0/16)"
echo "  └── vnet-spoke-shared (10.3.0.0/16)"
```

---

## Lab 02 — Azure DNS: Public & Private Zones

```bash
RG="rg-dns-lab"
LOCATION="eastus"
az group create --name $RG --location $LOCATION

# =========================================
# Public DNS Zone (like Route 53 Public Hosted Zone)
# =========================================
DOMAIN="mycompany.example.com"  # Replace with your actual domain

az network dns zone create \
  --resource-group $RG \
  --name $DOMAIN

# Add DNS records
# A record (like Route 53 A record)
az network dns record-set a add-record \
  --resource-group $RG \
  --zone-name $DOMAIN \
  --record-set-name "www" \
  --ipv4-address "20.10.30.40" \
  --ttl 300

# CNAME record
az network dns record-set cname set-record \
  --resource-group $RG \
  --zone-name $DOMAIN \
  --record-set-name "api" \
  --cname "myapp.azurewebsites.net" \
  --ttl 300

# MX record
az network dns record-set mx add-record \
  --resource-group $RG \
  --zone-name $DOMAIN \
  --record-set-name "@" \
  --exchange "mail.provider.com" \
  --preference 10

# TXT record (domain verification, SPF, DKIM)
az network dns record-set txt add-record \
  --resource-group $RG \
  --zone-name $DOMAIN \
  --record-set-name "@" \
  --value "v=spf1 include:spf.provider.com ~all"

# Get name servers (update at your registrar)
az network dns zone show \
  --resource-group $RG \
  --name $DOMAIN \
  --query nameServers \
  --output table

# =========================================
# Private DNS Zone (like Route 53 Private Hosted Zone)
# =========================================
PRIVATE_DOMAIN="internal.company.local"

az network private-dns zone create \
  --resource-group $RG \
  --name $PRIVATE_DOMAIN

# Link to VNet (auto-resolve within the VNet)
az network private-dns link vnet create \
  --resource-group $RG \
  --zone-name $PRIVATE_DOMAIN \
  --name "link-to-vnet-hub" \
  --virtual-network vnet-hub \
  --registration-enabled true  # Auto-register VM DNS names

# Add internal DNS records
az network private-dns record-set a add-record \
  --resource-group $RG \
  --zone-name $PRIVATE_DOMAIN \
  --record-set-name "sqlserver" \
  --ipv4-address "10.0.3.10"

az network private-dns record-set a add-record \
  --resource-group $RG \
  --zone-name $PRIVATE_DOMAIN \
  --record-set-name "redis" \
  --ipv4-address "10.0.3.20"

az network private-dns record-set cname set-record \
  --resource-group $RG \
  --zone-name $PRIVATE_DOMAIN \
  --record-set-name "db" \
  --cname "sqlserver.internal.company.local"

echo "✅ DNS configured!"
echo "Private DNS: Apps can reach sqlserver.internal.company.local → 10.0.3.10"
```

---

## Lab 03 — Azure Application Gateway (L7 LB + WAF)

```bash
RG="rg-appgw-lab"
LOCATION="eastus"
az group create --name $RG --location $LOCATION

# Create VNet for App Gateway
az network vnet create \
  --resource-group $RG \
  --name vnet-appgw \
  --address-prefixes 10.0.0.0/16

az network vnet subnet create \
  --resource-group $RG --vnet-name vnet-appgw \
  --name subnet-appgw --address-prefixes 10.0.0.0/24  # App Gateway needs its own subnet

az network vnet subnet create \
  --resource-group $RG --vnet-name vnet-appgw \
  --name subnet-backend --address-prefixes 10.0.1.0/24

# Public IP for App Gateway
az network public-ip create \
  --resource-group $RG \
  --name pip-appgw \
  --sku Standard \
  --allocation-method Static \
  --zone 1 2 3

# Create Application Gateway with WAF_v2
az network application-gateway create \
  --resource-group $RG \
  --name appgw-prod \
  --location $LOCATION \
  --sku WAF_v2 \
  --capacity 2 \
  --vnet-name vnet-appgw \
  --subnet subnet-appgw \
  --public-ip-address pip-appgw \
  --frontend-port 80 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --routing-rule-type Basic \
  --priority 100

# Enable WAF
az network application-gateway waf-config set \
  --resource-group $RG \
  --gateway-name appgw-prod \
  --enabled true \
  --firewall-mode Prevention \
  --rule-set-type OWASP \
  --rule-set-version 3.2

# Add backend pool (target servers)
az network application-gateway address-pool create \
  --resource-group $RG \
  --gateway-name appgw-prod \
  --name backend-pool-app \
  --servers 10.0.1.4 10.0.1.5 10.0.1.6

# Add HTTP settings
az network application-gateway http-settings create \
  --resource-group $RG \
  --gateway-name appgw-prod \
  --name http-settings-app \
  --port 8080 \
  --protocol Http \
  --timeout 30 \
  --host-name-from-backend-pool true

# Add listener for HTTPS (port 443)
az network application-gateway frontend-port create \
  --resource-group $RG \
  --gateway-name appgw-prod \
  --name port-443 \
  --port 443

az network application-gateway ssl-cert create \
  --resource-group $RG \
  --gateway-name appgw-prod \
  --name ssl-cert \
  --cert-file cert.pfx \
  --cert-password "password"

az network application-gateway http-listener create \
  --resource-group $RG \
  --gateway-name appgw-prod \
  --name listener-https \
  --frontend-ip appGatewayFrontendIP \
  --frontend-port port-443 \
  --ssl-cert ssl-cert \
  --host-name "myapp.example.com"

# Path-based routing (like ALB path-based rules in AWS)
az network application-gateway url-path-map create \
  --resource-group $RG \
  --gateway-name appgw-prod \
  --name url-path-map \
  --paths "/api/*" \
  --address-pool backend-pool-api \
  --http-settings http-settings-app \
  --default-address-pool backend-pool-app \
  --default-http-settings http-settings-app

# Get App Gateway public IP
az network public-ip show \
  --resource-group $RG \
  --name pip-appgw \
  --query ipAddress \
  --output tsv

echo "✅ Application Gateway with WAF deployed!"
```
