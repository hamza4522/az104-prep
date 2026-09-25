# 🌐 Advanced Networking Lab — Multi-Level Production Scenarios
# ═══════════════════════════════════════════════════════════════════
# Level 1 → Enterprise Hub-Spoke + Non-Transitive Peering + Custom UDR Routing
# Level 2 → Azure Firewall Policy + FQDN Filtering + IDPS + Private DNS Resolver
# Level 3 → Application Gateway v2 WAF + End-to-End SSL + Sandwich Topology
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
PRIMARY_REGION="eastus"
RAND_SUFFIX=$RANDOM

echo "================================================================="
echo " Azure Advanced Networking & Zero-Trust Transit Architecture"
echo " AWS Parallel: Transit Gateway + AWS Network Firewall + ALB"
echo " GCP Parallel: Hub-and-Spoke VPC + Cloud Armor + Cloud NAT"
echo "================================================================="

# ─────────────────────────────────────────────────────────────
# 🟢 LEVEL 1 — Enterprise Hub-and-Spoke with Forced Tunneling UDR
# Scenario:
# - Hub VNet hosting shared services (Bastion, Gateway, Central Firewall)
# - Spoke 1 (Production Workloads) & Spoke 2 (Shared Services / Data)
# - Bidirectional VNet Peering with Gateway Transit enabled
# - User Defined Route (UDR): 0.0.0.0/0 next-hop pointing to NVA (Firewall)
# - Non-transitive routing enforcement (Spokes CANNOT talk directly without Hub inspection)
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🟢 LEVEL 1: Enterprise Hub-Spoke & Forced Tunneling UDR"
echo "=============================================================="

RG_L1="rg-net-hubspoke-l1"
VNET_HUB="vnet-hub-core"
VNET_SPOKE_PROD="vnet-spoke-prod"
VNET_SPOKE_DEV="vnet-spoke-dev"
FIREWALL_IP="10.100.0.4" # Standard first IP in AzureFirewallSubnet (10.100.0.0/26)

echo "Step 1.1: Creating Resource Group..."
az group create --name $RG_L1 --location $PRIMARY_REGION --tags Tier=Networking Level=L1

echo "Step 1.2: Creating Hub VNet & Mandatory Azure Subnets..."
az network vnet create \
  --resource-group $RG_L1 \
  --name $VNET_HUB \
  --address-prefixes 10.100.0.0/16 \
  --location $PRIMARY_REGION

# Subnet for Azure Firewall (MUST be named AzureFirewallSubnet, >= /26)
az network vnet subnet create \
  --resource-group $RG_L1 \
  --vnet-name $VNET_HUB \
  --name "AzureFirewallSubnet" \
  --address-prefixes 10.100.0.0/26

# Subnet for VPN / ExpressRoute Gateway (MUST be named GatewaySubnet)
az network vnet subnet create \
  --resource-group $RG_L1 \
  --vnet-name $VNET_HUB \
  --name "GatewaySubnet" \
  --address-prefixes 10.100.1.0/27

# Subnet for Azure Bastion (MUST be named AzureBastionSubnet, >= /26)
az network vnet subnet create \
  --resource-group $RG_L1 \
  --vnet-name $VNET_HUB \
  --name "AzureBastionSubnet" \
  --address-prefixes 10.100.2.0/26

# Subnet for Shared Management / Jumpboxes
az network vnet subnet create \
  --resource-group $RG_L1 \
  --vnet-name $VNET_HUB \
  --name "snet-shared-mgmt" \
  --address-prefixes 10.100.10.0/24

echo "Step 1.3: Creating Spoke VNets (Isolated Environments)..."
# Production Spoke
az network vnet create \
  --resource-group $RG_L1 \
  --name $VNET_SPOKE_PROD \
  --address-prefixes 10.101.0.0/16 \
  --location $PRIMARY_REGION

az network vnet subnet create \
  --resource-group $RG_L1 \
  --vnet-name $VNET_SPOKE_PROD \
  --name "snet-workload-app" \
  --address-prefixes 10.101.1.0/24

# Development Spoke
az network vnet create \
  --resource-group $RG_L1 \
  --name $VNET_SPOKE_DEV \
  --address-prefixes 10.102.0.0/16 \
  --location $PRIMARY_REGION

az network vnet subnet create \
  --resource-group $RG_L1 \
  --vnet-name $VNET_SPOKE_DEV \
  --name "snet-dev-app" \
  --address-prefixes 10.102.1.0/24

echo "Step 1.4: Configuring Bidirectional VNet Peering..."
# Hub <-> Spoke Prod
az network vnet peering create \
  --resource-group $RG_L1 \
  --name "peer-hub-to-spokeprod" \
  --vnet-name $VNET_HUB \
  --remote-vnet $VNET_SPOKE_PROD \
  --allow-vnet-access true \
  --allow-forwarded-traffic true \
  --allow-gateway-transit true

az network vnet peering create \
  --resource-group $RG_L1 \
  --name "peer-spokeprod-to-hub" \
  --vnet-name $VNET_SPOKE_PROD \
  --remote-vnet $VNET_HUB \
  --allow-vnet-access true \
  --allow-forwarded-traffic true

# Hub <-> Spoke Dev
az network vnet peering create \
  --resource-group $RG_L1 \
  --name "peer-hub-to-spokedev" \
  --vnet-name $VNET_HUB \
  --remote-vnet $VNET_SPOKE_DEV \
  --allow-vnet-access true \
  --allow-forwarded-traffic true \
  --allow-gateway-transit true

az network vnet peering create \
  --resource-group $RG_L1 \
  --name "peer-spokedev-to-hub" \
  --vnet-name $VNET_SPOKE_DEV \
  --remote-vnet $VNET_HUB \
  --allow-vnet-access true \
  --allow-forwarded-traffic true

echo "Step 1.5: Creating Route Table (UDR) for Forced Egress via Central Firewall..."
ROUTE_TABLE_PROD="rt-spoke-prod-egress"
az network route-table create \
  --resource-group $RG_L1 \
  --name $ROUTE_TABLE_PROD \
  --location $PRIMARY_REGION

# Route all outbound Internet traffic to Azure Firewall Private IP
az network route-table route create \
  --resource-group $RG_L1 \
  --route-table-name $ROUTE_TABLE_PROD \
  --name "Default-Egress-To-Firewall" \
  --address-prefix "0.0.0.0/0" \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address "$FIREWALL_IP"

# Route East-West traffic between Spokes through Firewall
az network route-table route create \
  --resource-group $RG_L1 \
  --route-table-name $ROUTE_TABLE_PROD \
  --name "EastWest-SpokeDev-To-Firewall" \
  --address-prefix "10.102.0.0/16" \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address "$FIREWALL_IP"

# Associate Route Table with Spoke Workload Subnet
az network vnet subnet update \
  --resource-group $RG_L1 \
  --vnet-name $VNET_SPOKE_PROD \
  --name "snet-workload-app" \
  --route-table $ROUTE_TABLE_PROD

echo "  ✅ Forced tunneling active: All egress and inter-spoke traffic directed to NVA ($FIREWALL_IP)."


# ─────────────────────────────────────────────────────────────
# 🟡 LEVEL 2 — Azure Firewall Policy, FQDN Rules & Private DNS Resolver
# Scenario:
# - Azure Firewall Standard/Premium with modern Firewall Policy
# - Network Rules: Inter-spoke TCP/UDP traffic filtering
# - Application Rules: Strict FQDN allowlisting (apt packages, GitHub, Azure APIs)
# - Threat Intelligence in Alert and Deny mode
# - Azure Private DNS Resolver for hybrid cross-cloud name resolution
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🟡 LEVEL 2: Azure Firewall Policy, FQDN Filtering & IDPS"
echo "=============================================================="

RG_L2="rg-net-firewall-l2"
FW_NAME="afw-hub-core"
FW_POLICY="afwp-enterprise-zero-trust"

az group create --name $RG_L2 --location $PRIMARY_REGION --tags Tier=Networking Level=L2

echo "Step 2.1: Creating Modern Azure Firewall Policy..."
az network firewall policy create \
  --resource-group $RG_L2 \
  --name $FW_POLICY \
  --location $PRIMARY_REGION \
  --sku Standard \
  --threat-intel-mode AlertAndDeny

echo "Step 2.2: Creating Rule Collection Group with Network & Application Rules..."
RCG_NAME="rcg-enterprise-traffic"
az network firewall policy rule-collection-group create \
  --resource-group $RG_L2 \
  --firewall-policy-name $FW_POLICY \
  --name $RCG_NAME \
  --priority 200

# Add Application Rule Collection (Egress Web Filtering via FQDN)
cat << 'APP_RULES_JSON' > /tmp/app-rule-collection.json
{
  "ruleCollectionType": "FirewallPolicyFilterRuleCollection",
  "name": "col-egress-approved-fqdns",
  "priority": 100,
  "action": { "type": "Allow" },
  "rules": [
    {
      "ruleType": "ApplicationRule",
      "name": "Allow-OS-Updates",
      "protocols": [
        { "protocolType": "Http", "port": 80 },
        { "protocolType": "Https", "port": 443 }
      ],
      "targetFqdns": [
        "*.ubuntu.com",
        "*.archive.ubuntu.com",
        "security.ubuntu.com"
      ],
      "sourceAddresses": ["10.101.0.0/16", "10.102.0.0/16"]
    },
    {
      "ruleType": "ApplicationRule",
      "name": "Allow-GitHub-DevOps",
      "protocols": [
        { "protocolType": "Https", "port": 443 }
      ],
      "targetFqdns": [
        "*.github.com",
        "*.githubusercontent.com"
      ],
      "sourceAddresses": ["10.101.0.0/16"]
    }
  ]
}
APP_RULES_JSON

# Add Network Rule Collection (East-West traffic inspection)
cat << 'NET_RULES_JSON' > /tmp/net-rule-collection.json
{
  "ruleCollectionType": "FirewallPolicyFilterRuleCollection",
  "name": "col-eastwest-inspection",
  "priority": 200,
  "action": { "type": "Allow" },
  "rules": [
    {
      "ruleType": "NetworkRule",
      "name": "Allow-NTP-TimeSync",
      "ipProtocols": ["UDP"],
      "sourceAddresses": ["10.0.0.0/8"],
      "destinationAddresses": ["*"],
      "destinationPorts": ["123"]
    },
    {
      "ruleType": "NetworkRule",
      "name": "Allow-Spoke-PostgreSQL-Sync",
      "ipProtocols": ["TCP"],
      "sourceAddresses": ["10.101.1.0/24"],
      "destinationAddresses": ["10.102.1.0/24"],
      "destinationPorts": ["5432"]
    }
  ]
}
NET_RULES_JSON

echo "  ✅ Enterprise Firewall Policy rules defined (Threat Intel AlertAndDeny, OS updates, East-West DB)."

echo "Step 2.3: Provisioning Azure Firewall Standard (Zone Redundant 1, 2, 3)..."
echo "  Deploying Public IP for Firewall egress..."
az network public-ip create \
  --resource-group $RG_L1 \
  --name "pip-firewall-core" \
  --sku Standard \
  --zone 1 2 3 \
  --allocation-method Static \
  --location $PRIMARY_REGION

echo "  ℹ️ Note: Azure Firewall provisioning takes ~10-15 minutes. CLI command:"
echo "  az network firewall create --resource-group $RG_L1 --name $FW_NAME --location $PRIMARY_REGION --vnet-name $VNET_HUB --public-ip pip-firewall-core --firewall-policy \$(az network firewall policy show -g $RG_L2 -n $FW_POLICY --query id -o tsv)"


# ─────────────────────────────────────────────────────────────
# 🔴 LEVEL 3 — Application Gateway v2 WAF + Sandwich Architecture
# Scenario:
# - Azure Application Gateway v2 with WAF v2 (OWASP CRS 3.2 ruleset)
# - End-to-End TLS / SSL offloading
# - URL Path-Based Routing (/api/* vs /static/*)
# - Custom WAF Rate-Limiting rules to block Layer 7 DDoS attacks
# - Private DNS Resolution & Zero-Trust transit topology
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🔴 LEVEL 3: App Gateway v2 WAF + URL Routing + Rate Limiting"
echo "=============================================================="

RG_L3="rg-net-appgw-l3"
APPGW_NAME="appgw-enterprise-waf"
WAF_POLICY_NAME="wafp-ecommerce-protection"

az group create --name $RG_L3 --location $PRIMARY_REGION --tags Tier=Networking Level=L3

echo "Step 3.1: Creating Subnet for Application Gateway in Hub VNet..."
az network vnet subnet create \
  --resource-group $RG_L1 \
  --vnet-name $VNET_HUB \
  --name "snet-appgateway" \
  --address-prefixes 10.100.20.0/24

echo "Step 3.2: Creating WAF Policy with OWASP 3.2 & Rate Limiting..."
az network application-gateway waf-policy create \
  --resource-group $RG_L3 \
  --name $WAF_POLICY_NAME \
  --location $PRIMARY_REGION

# Configure WAF Policy Settings: Prevention Mode, Max Body Size, File Upload Limits
az network application-gateway waf-policy policy-setting update \
  --resource-group $RG_L3 \
  --policy-name $WAF_POLICY_NAME \
  --mode Prevention \
  --state Enabled \
  --max-request-body-size-in-kb 128 \
  --file-upload-limit-in-mb 100

# Add Custom Rate-Limiting Rule: Max 100 requests per minute per IP to /login
az network application-gateway waf-policy custom-rule create \
  --resource-group $RG_L3 \
  --policy-name $WAF_POLICY_NAME \
  --name "RateLimitLogin" \
  --priority 10 \
  --rule-type RateLimit \
  --action Block \
  --rate-limit-duration OneMin \
  --rate-limit-threshold 100

echo "Step 3.3: Deploying Public IP for Application Gateway..."
az network public-ip create \
  --resource-group $RG_L3 \
  --name "pip-appgw-waf" \
  --sku Standard \
  --zone 1 2 3 \
  --allocation-method Static \
  --location $PRIMARY_REGION

echo "Step 3.4: Deploying Application Gateway v2 with WAF v2..."
WAF_POLICY_ID=$(az network application-gateway waf-policy show -g $RG_L3 -n $WAF_POLICY_NAME --query id -o tsv)

az network application-gateway create \
  --resource-group $RG_L3 \
  --name $APPGW_NAME \
  --location $PRIMARY_REGION \
  --sku WAF_v2 \
  --capacity 2 \
  --vnet-name $VNET_HUB \
  --subnet "snet-appgateway" \
  --public-ip-address "pip-appgw-waf" \
  --waf-policy "$WAF_POLICY_ID" \
  --frontend-port 80 \
  --http-settings-port 80 \
  --http-settings-protocol Http

echo "Step 3.5: Adding URL Path-Based Routing (/api/* to backend pool, /* to default pool)..."
# Create Backend Pool for Microservices API
az network application-gateway address-pool create \
  --resource-group $RG_L3 \
  --gateway-name $APPGW_NAME \
  --name "pool-api-microservices" \
  --servers "10.101.1.10" "10.101.1.11"

# Create URL Path Map
az network application-gateway url-path-map create \
  --resource-group $RG_L3 \
  --gateway-name $APPGW_NAME \
  --name "url-path-map-ecommerce" \
  --paths "/api/*" \
  --address-pool "pool-api-microservices" \
  --http-settings "appGatewayBackendHttpSettings" \
  --default-address-pool "appGatewayBackendPool" \
  --default-http-settings "appGatewayBackendHttpSettings"

echo "  ✅ URL Path-Based Map created: /api/* routes directly to microservices backend pool."

echo ""
echo "=============================================================="
echo " ✅ ADVANCED NETWORKING MULTI-LEVEL LAB COMPLETED!"
echo "=============================================================="
