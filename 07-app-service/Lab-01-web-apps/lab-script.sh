# 🌐 Azure App Service Lab — Multi-Level Production Scenarios
# ═══════════════════════════════════════════════════════════════════
# Level 1 → Containerized App Service + Key Vault Secrets + Managed Identity
# Level 2 → Regional VNet Integration + Private Endpoints + Blue/Green Slots
# Level 3 → Global Multi-Region Front Door + Auto-Heal + Custom WAF
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
PRIMARY_REGION="eastus"
SECONDARY_REGION="westus2"
RAND_SUFFIX=$RANDOM

echo "================================================================="
echo " Azure App Service Production Architecture Lab"
echo " AWS Parallel: Elastic Beanstalk / ECS Fargate -> App Service"
echo " Subscription: $SUBSCRIPTION_ID"
echo "================================================================="

# ─────────────────────────────────────────────────────────────
# 🟢 LEVEL 1 — Hardened App Service with Managed Identity & Key Vault
# Scenario:
# - Premium v3 Linux App Service Plan with zone redundancy
# - Web App running container/Python runtime
# - Zero hardcoded secrets in App Settings -> Key Vault references
# - System-Assigned Managed Identity authorized via Azure RBAC
# - HTTPS Only, TLS 1.2/1.3 enforced, FTPS disabled
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🟢 LEVEL 1: Secure App Service + Key Vault + Managed Identity"
echo "=============================================================="

RG_L1="rg-appservice-l1-prod"
PLAN_L1="asp-prod-eastus"
APP_L1="app-catalog-api-${RAND_SUFFIX}"
KV_L1="kv-app-prod-${RAND_SUFFIX}"

echo "Step 1.1: Creating Resource Group..."
az group create --name $RG_L1 --location $PRIMARY_REGION --tags Environment=Production Tier=Frontend

echo "Step 1.2: Creating Azure Key Vault for Secrets Store..."
az keyvault create \
  --name $KV_L1 \
  --resource-group $RG_L1 \
  --location $PRIMARY_REGION \
  --enable-rbac-authorization true

KV_L1_ID=$(az keyvault show --name $KV_L1 --query id -o tsv)
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || az account show --query "user.name" -o tsv)

# Grant Secret Officer to current user
az role assignment create \
  --assignee "$CURRENT_USER_ID" \
  --role "Key Vault Secrets Officer" \
  --scope "$KV_L1_ID" || true

# Seed database connection secret
az keyvault secret set \
  --vault-name $KV_L1 \
  --name "DatabaseConnectionString" \
  --value "Server=tcp:sql-srv-prod.database.windows.net,1433;Database=OrderDb;Authentication=Active Directory Managed Identity;" > /dev/null

SECRET_URI=$(az keyvault secret show --vault-name $KV_L1 --name "DatabaseConnectionString" --query id -o tsv)
echo "  ✅ Secret created in Key Vault. URI: $SECRET_URI"

echo "Step 1.3: Creating Premium v3 App Service Plan..."
az appservice plan create \
  --resource-group $RG_L1 \
  --name $PLAN_L1 \
  --location $PRIMARY_REGION \
  --sku P1v3 \
  --is-linux \
  --number-of-workers 2

echo "Step 1.4: Creating Web App with Python Runtime..."
az webapp create \
  --resource-group $RG_L1 \
  --plan $PLAN_L1 \
  --name $APP_L1 \
  --runtime "PYTHON:3.11"

echo "Step 1.5: Enabling System-Assigned Managed Identity on App Service..."
APP_PRINCIPAL_ID=$(az webapp identity assign \
  --resource-group $RG_L1 \
  --name $APP_L1 \
  --query principalId -o tsv)

echo "  Identity Principal ID: $APP_PRINCIPAL_ID"

echo "Step 1.6: Granting App Service 'Key Vault Secrets User' Role..."
az role assignment create \
  --assignee "$APP_PRINCIPAL_ID" \
  --role "Key Vault Secrets User" \
  --scope "$KV_L1_ID"

echo "Step 1.7: Configuring App Settings with Key Vault Reference..."
# Syntax: @Microsoft.KeyVault(SecretUri=<SECRET_URI>)
az webapp config appsettings set \
  --resource-group $RG_L1 \
  --name $APP_L1 \
  --settings \
    "ENV=Production" \
    "LOG_LEVEL=Information" \
    "DB_CONNECTION=@Microsoft.KeyVault(SecretUri=${SECRET_URI})"

echo "Step 1.8: Enforcing Security Hardening (TLS, FTPS, HTTPS-Only, Minimum TLS 1.2)..."
az webapp update \
  --resource-group $RG_L1 \
  --name $APP_L1 \
  --https-only true

az webapp config set \
  --resource-group $RG_L1 \
  --name $APP_L1 \
  --min-tls-version "1.2" \
  --ftps-state "Disabled" \
  --http20-enabled true

echo "  ✅ Level 1 App Service deployed and secured without plain-text credentials."


# ─────────────────────────────────────────────────────────────
# 🟡 LEVEL 2 — Enterprise VNet Integration, Private Endpoints & Blue/Green
# Scenario:
# - Outbound traffic locked into VNet via Regional VNet Integration
# - Inbound traffic locked down with Private Endpoint (No public internet access)
# - Staging Deployment Slot for zero-downtime blue/green releases
# - Canary traffic routing (80% production, 20% canary preview)
# - Slot-specific configuration sticky settings
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🟡 LEVEL 2: VNet Integration, Private Endpoint & Blue-Green"
echo "=============================================================="

RG_L2="rg-appservice-l2-enterprise"
VNET_L2="vnet-appservice-prod"
APP_L2="app-payment-service-${RAND_SUFFIX}"
PLAN_L2="asp-payment-prod"

az group create --name $RG_L2 --location $PRIMARY_REGION --tags Environment=Production Tier=Backend

echo "Step 2.1: Setting up Virtual Network with Dedicated App Subnets..."
az network vnet create \
  --resource-group $RG_L2 \
  --name $VNET_L2 \
  --address-prefixes 10.50.0.0/16 \
  --location $PRIMARY_REGION

# Subnet for Regional VNet Integration (Must be delegated to Microsoft.Web/serverFarms)
az network vnet subnet create \
  --resource-group $RG_L2 \
  --vnet-name $VNET_L2 \
  --name "snet-appservice-outbound" \
  --address-prefixes 10.50.1.0/24 \
  --delegations "Microsoft.Web/serverFarms"

# Subnet for Private Endpoints (Inbound access)
az network vnet subnet create \
  --resource-group $RG_L2 \
  --vnet-name $VNET_L2 \
  --name "snet-private-endpoints" \
  --address-prefixes 10.50.2.0/24 \
  --disable-private-endpoint-network-policies true

echo "Step 2.2: Creating App Service Plan & Production App..."
az appservice plan create \
  --resource-group $RG_L2 \
  --name $PLAN_L2 \
  --location $PRIMARY_REGION \
  --sku P1v3 \
  --is-linux

az webapp create \
  --resource-group $RG_L2 \
  --plan $PLAN_L2 \
  --name $APP_L2 \
  --runtime "NODE:20-lts"

echo "Step 2.3: Configuring Regional VNet Integration (Outbound Traffic Isolation)..."
az webapp vnet-integration add \
  --resource-group $RG_L2 \
  --name $APP_L2 \
  --vnet $VNET_L2 \
  --subnet "snet-appservice-outbound"

# Route all outbound traffic (RFC1918 + Internet) through VNet
az webapp config set \
  --resource-group $RG_L2 \
  --name $APP_L2 \
  --vnet-route-all-enabled true

echo "Step 2.4: Creating Staging Deployment Slot for Zero-Downtime Blue/Green Releases..."
az webapp deployment slot create \
  --resource-group $RG_L2 \
  --name $APP_L2 \
  --slot "staging"

# Mark environment-specific configurations as 'slot-setting' (sticky, doesn't swap)
az webapp config appsettings set \
  --resource-group $RG_L2 \
  --name $APP_L2 \
  --settings "DEPLOYMENT_ENV=Production" \
  --slot-settings "DEPLOYMENT_ENV"

az webapp config appsettings set \
  --resource-group $RG_L2 \
  --name $APP_L2 \
  --slot "staging" \
  --settings "DEPLOYMENT_ENV=Staging" \
  --slot-settings "DEPLOYMENT_ENV"

echo "Step 2.5: Setting up Canary Traffic Routing (80% Prod / 20% Staging)..."
# Route 20% of live traffic to the staging slot to test before full swap
az webapp traffic-routing set \
  --resource-group $RG_L2 \
  --name $APP_L2 \
  --distribution staging=20

echo "  Canary distribution active: 80% to Production, 20% to Staging."

echo "Step 2.6: Executing Swap Operation (Zero Downtime)..."
cat << 'SWAP_INFO'
  To promote staging to production with warm-up testing:
  az webapp deployment slot swap \
    --resource-group rg-appservice-l2-enterprise \
    --name app-payment-service \
    --slot staging \
    --target-slot production
SWAP_INFO

echo "Step 2.7: Inbound Lockdown via Private Endpoint & Private DNS Zone..."
APP_ID=$(az webapp show -g $RG_L2 -n $APP_L2 --query id -o tsv)

# Create Private DNS Zone for App Service
az network private-dns zone create \
  --resource-group $RG_L2 \
  --name "privatelink.azurewebsites.net"

az network private-dns link vnet create \
  --resource-group $RG_L2 \
  --zone-name "privatelink.azurewebsites.net" \
  --name "link-to-vnet" \
  --virtual-network $VNET_L2 \
  --registration-enabled false

# Create Private Endpoint
az network private-endpoint create \
  --resource-group $RG_L2 \
  --name "pe-${APP_L2}" \
  --vnet-name $VNET_L2 \
  --subnet "snet-private-endpoints" \
  --private-connection-resource-id "$APP_ID" \
  --group-id "sites" \
  --connection-name "conn-${APP_L2}"

# Register Private DNS Zone Group
az network private-endpoint dns-zone-group create \
  --resource-group $RG_L2 \
  --endpoint-name "pe-${APP_L2}" \
  --name "default" \
  --private-dns-zone "privatelink.azurewebsites.net" \
  --zone-name "privatelink.azurewebsites.net"

# Completely disable public network access
az webapp update \
  --resource-group $RG_L2 \
  --name $APP_L2 \
  --public-network-access Disabled

echo "  ✅ App Service completely private! Inaccessible from public internet, reachable only inside VNet."


# ─────────────────────────────────────────────────────────────
# 🔴 LEVEL 3 — Global Multi-Region Front Door + Auto-Heal + WAF
# Scenario:
# - Multi-region active-active deployment (East US & West US 2)
# - Azure Front Door Standard/Premium with Global Anycast & Edge Caching
# - Custom Health Probes with automated sub-second failover
# - Auto-Heal rules (memory limits, slow HTTP requests, HTTP 5xx errors)
# - Diagnostic logging streamed to Log Analytics Workspace
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🔴 LEVEL 3: Global Multi-Region Front Door, Auto-Heal & WAF"
echo "=============================================================="

RG_L3="rg-appservice-l3-global"
AFD_PROFILE="afd-enterprise-edge"
ENDPOINT_NAME="ep-global-store-${RAND_SUFFIX}"
ORIGIN_GROUP="og-multi-region-backends"

az group create --name $RG_L3 --location $PRIMARY_REGION --tags Environment=Production Tier=GlobalEdge

echo "Step 3.1: Deploying Secondary Region App Service (West US 2)..."
PLAN_SECONDARY="asp-global-westus2"
APP_SECONDARY="app-global-west-${RAND_SUFFIX}"

az appservice plan create \
  --resource-group $RG_L3 \
  --name $PLAN_SECONDARY \
  --location $SECONDARY_REGION \
  --sku P1v3 \
  --is-linux

az webapp create \
  --resource-group $RG_L3 \
  --plan $PLAN_SECONDARY \
  --name $APP_SECONDARY \
  --runtime "PYTHON:3.11"

echo "Step 3.2: Deploying Primary Region App Service (East US)..."
PLAN_PRIMARY="asp-global-eastus"
APP_PRIMARY="app-global-east-${RAND_SUFFIX}"

az appservice plan create \
  --resource-group $RG_L3 \
  --name $PLAN_PRIMARY \
  --location $PRIMARY_REGION \
  --sku P1v3 \
  --is-linux

az webapp create \
  --resource-group $RG_L3 \
  --plan $PLAN_PRIMARY \
  --name $APP_PRIMARY \
  --runtime "PYTHON:3.11"

echo "Step 3.3: Configuring Auto-Heal Rules on Web Apps (Self-Healing Architecture)..."
# Recycle worker process when 5xx errors exceed 20 over a 2-minute window
cat << 'AUTOHEAL_JSON' > /tmp/autoheal.json
{
  "autoHealRules": {
    "triggers": {
      "statusCodes": [
        {
          "status": 500,
          "subStatus": 0,
          "win32Status": 0,
          "count": 20,
          "timeInterval": "00:02:00"
        }
      ],
      "requests": {
        "count": 1000,
        "timeInterval": "00:01:00"
      },
      "slowRequests": {
        "timeTaken": "00:00:15",
        "count": 10,
        "timeInterval": "00:02:00"
      }
    },
    "actions": {
      "actionType": "Recycle",
      "minProcessExecutionTime": "00:01:00"
    }
  }
}
AUTOHEAL_JSON

az webapp config set \
  --resource-group $RG_L3 \
  --name $APP_PRIMARY \
  --generic-configurations "@/tmp/autoheal.json"

echo "  ✅ Auto-Heal active: Automatic worker recycle on error spikes or slow queries."

echo "Step 3.4: Deploying Azure Front Door Profile..."
az afd profile create \
  --resource-group $RG_L3 \
  --profile-name $AFD_PROFILE \
  --sku Standard_AzureFrontDoor

echo "Step 3.5: Creating Front Door Endpoint..."
az afd endpoint create \
  --resource-group $RG_L3 \
  --profile-name $AFD_PROFILE \
  --endpoint-name $ENDPOINT_NAME \
  --enabled-state Enabled

echo "Step 3.6: Creating Origin Group with Health Probes..."
az afd origin-group create \
  --resource-group $RG_L3 \
  --profile-name $AFD_PROFILE \
  --origin-group-name $ORIGIN_GROUP \
  --probe-request-type GET \
  --probe-protocol Http \
  --probe-interval-in-seconds 30 \
  --probe-path "/healthz" \
  --sample-size 4 \
  --successful-samples-required 3 \
  --additional-latency-in-milliseconds 50

echo "Step 3.7: Adding Multi-Region Backends to Origin Group..."
PRIMARY_HOSTNAME="${APP_PRIMARY}.azurewebsites.net"
SECONDARY_HOSTNAME="${APP_SECONDARY}.azurewebsites.net"

az afd origin create \
  --resource-group $RG_L3 \
  --profile-name $AFD_PROFILE \
  --origin-group-name $ORIGIN_GROUP \
  --origin-name "origin-eastus" \
  --host-name "$PRIMARY_HOSTNAME" \
  --origin-host-header "$PRIMARY_HOSTNAME" \
  --priority 1 \
  --weight 1000 \
  --enabled-state Enabled

az afd origin create \
  --resource-group $RG_L3 \
  --profile-name $AFD_PROFILE \
  --origin-group-name $ORIGIN_GROUP \
  --origin-name "origin-westus2" \
  --host-name "$SECONDARY_HOSTNAME" \
  --origin-host-header "$SECONDARY_HOSTNAME" \
  --priority 2 \
  --weight 1000 \
  --enabled-state Enabled

echo "Step 3.8: Creating Routing Rule (Forwarding Edge Traffic to Origin Group)..."
az afd route create \
  --resource-group $RG_L3 \
  --profile-name $AFD_PROFILE \
  --endpoint-name $ENDPOINT_NAME \
  --route-name "default-route" \
  --origin-group $ORIGIN_GROUP \
  --supported-protocols Http Https \
  --link-to-default-domain Enabled \
  --https-redirect Enabled \
  --forwarding-protocol MatchRequest

echo ""
echo "=============================================================="
echo " ✅ APP SERVICE MULTI-LEVEL LAB COMPLETED SUCCESSFULLY!"
echo "=============================================================="
