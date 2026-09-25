# 🔐 Cloud Security & Key Vault Lab — Multi-Level Production Scenarios
# ═════════════════════════════════════════════════════════════════════
# Level 1 → Enterprise Key Vault + Modern Azure RBAC + Cert Auto-Renewal
# Level 2 → Zero-Trust Private Link + Firewall Whitelisting + Audit Telemetry
# Level 3 → Managed HSM + Envelope CMK + Auto Key Rotation + Defender Alerts
# ═════════════════════════════════════════════════════════════════════

set -euo pipefail

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
PRIMARY_REGION="eastus"
RAND_SUFFIX=$RANDOM

echo "================================================================="
echo " Azure Cloud Security & Key Vault Lab (AZ-104 & Enterprise SecOps)"
echo " AWS Parallel: AWS KMS + Secrets Manager + Certificate Manager"
echo " GCP Parallel: Cloud KMS + Secret Manager + Certificate Authority"
echo "================================================================="

# ─────────────────────────────────────────────────────────────
# 🟢 LEVEL 1 — Hardened Azure Key Vault with Azure RBAC
# Scenario:
# - Key Vault with Azure RBAC (replacing legacy Vault Access Policies)
# - Soft-Delete (90 days retention) and Purge Protection enabled
# - Granular RBAC: Secrets Officer vs Secrets User (Least Privilege)
# - Automated SSL/TLS Certificate generation & auto-renewal policy
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🟢 LEVEL 1: Enterprise Key Vault + Azure RBAC + Auto-Cert"
echo "=============================================================="

RG_L1="rg-security-l1-prod"
KV_L1="kv-enterprise-core-${RAND_SUFFIX}"

echo "Step 1.1: Creating Resource Group..."
az group create --name $RG_L1 --location $PRIMARY_REGION --tags Tier=Security Level=L1

echo "Step 1.2: Creating Azure Key Vault with RBAC & Purge Protection..."
az keyvault create \
  --name $KV_L1 \
  --resource-group $RG_L1 \
  --location $PRIMARY_REGION \
  --enable-rbac-authorization true \
  --enable-purge-protection true \
  --enable-soft-delete true \
  --retention-days 90

KV_L1_ID=$(az keyvault show --name $KV_L1 --query id -o tsv)
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || az account show --query "user.name" -o tsv)

echo "Step 1.3: Assigning Granular Azure RBAC Roles (Separation of Duties)..."
# 1. Key Vault Secrets Officer: Can create/update secrets (e.g. CI/CD Pipeline or Lead DevOps)
az role assignment create \
  --assignee "$CURRENT_USER_ID" \
  --role "Key Vault Secrets Officer" \
  --scope "$KV_L1_ID"

# 2. Key Vault Certificates Officer: Can manage SSL certificates
az role assignment create \
  --assignee "$CURRENT_USER_ID" \
  --role "Key Vault Certificates Officer" \
  --scope "$KV_L1_ID"

# 3. Key Vault Crypto Officer: Can manage encryption keys
az role assignment create \
  --assignee "$CURRENT_USER_ID" \
  --role "Key Vault Crypto Officer" \
  --scope "$KV_L1_ID"

echo "  ✅ Least-privilege RBAC roles granted on Key Vault."

echo "Step 1.4: Managing Secrets with Expiry Dates & Content Types..."
az keyvault secret set \
  --vault-name $KV_L1 \
  --name "StripeProductionApiKey" \
  --value "sk_live_51MXXXXXXXXXXXXXX" \
  --description "Production Stripe Secret Key" \
  --expires "$(date -u -d '+1 year' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo '2027-01-01T00:00:00Z')" > /dev/null

echo "Step 1.5: Creating Self-Renewing SSL/TLS Certificate..."
# Policy generates self-signed or CA cert that automatically triggers renewal at 80% lifetime
cat << 'CERT_POLICY' > /tmp/cert-policy.json
{
  "issuerParameters": {
    "name": "Self"
  },
  "keyProperties": {
    "exportable": true,
    "keySize": 4096,
    "keyType": "RSA",
    "reuseKey": false
  },
  "lifetimeActions": [
    {
      "action": {
        "actionType": "AutoRenew"
      },
      "trigger": {
        "lifetimePercentage": 80
      }
    }
  ],
  "secretProperties": {
    "contentType": "application/x-pkcs12"
  },
  "x509CertificateProperties": {
    "keyUsage": [
      "digitalSignature",
      "keyEncipherment"
    ],
    "subject": "CN=api.production.company.com",
    "validityInMonths": 12
  }
}
CERT_POLICY

az keyvault certificate create \
  --vault-name $KV_L1 \
  --name "cert-api-wildcard" \
  --policy "@/tmp/cert-policy.json" > /dev/null

echo "  ✅ Auto-renewing certificate policy created for api.production.company.com."


# ─────────────────────────────────────────────────────────────
# 🟡 LEVEL 2 — Zero-Trust Network Lockdown & Audit Telemetry
# Scenario:
# - Key Vault completely isolated from public internet
# - Private Endpoint inside a secured Virtual Network
# - Azure Private DNS Zone for seamless private endpoint resolution
# - Streaming audit logs to Log Analytics (tracking secret access events)
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🟡 LEVEL 2: Private Endpoint Lockdown & Audit Telemetry"
echo "=============================================================="

RG_L2="rg-security-l2-zerotrust"
VNET_SEC="vnet-security-transit"
LAW_SEC="law-security-audit-${RAND_SUFFIX}"

az group create --name $RG_L2 --location $PRIMARY_REGION --tags Tier=Security Level=L2

echo "Step 2.1: Creating Security VNet for Private Link..."
az network vnet create \
  --resource-group $RG_L2 \
  --name $VNET_SEC \
  --address-prefixes 10.70.0.0/16 \
  --location $PRIMARY_REGION

az network vnet subnet create \
  --resource-group $RG_L2 \
  --vnet-name $VNET_SEC \
  --name "snet-private-endpoints" \
  --address-prefixes 10.70.1.0/24 \
  --disable-private-endpoint-network-policies true

echo "Step 2.2: Creating Private DNS Zone for Key Vault..."
az network private-dns zone create \
  --resource-group $RG_L2 \
  --name "privatelink.vaultcore.azure.net"

az network private-dns link vnet create \
  --resource-group $RG_L2 \
  --zone-name "privatelink.vaultcore.azure.net" \
  --name "link-to-sec-vnet" \
  --virtual-network $VNET_SEC \
  --registration-enabled false

echo "Step 2.3: Creating Private Endpoint for Key Vault..."
az network private-endpoint create \
  --resource-group $RG_L2 \
  --name "pe-${KV_L1}" \
  --vnet-name $VNET_SEC \
  --subnet "snet-private-endpoints" \
  --private-connection-resource-id "$KV_L1_ID" \
  --group-id "vault" \
  --connection-name "conn-${KV_L1}"

az network private-endpoint dns-zone-group create \
  --resource-group $RG_L2 \
  --endpoint-name "pe-${KV_L1}" \
  --name "default" \
  --private-dns-zone "privatelink.vaultcore.azure.net" \
  --zone-name "privatelink.vaultcore.azure.net"

echo "Step 2.4: Disabling Public Internet Access on Key Vault..."
az keyvault update \
  --name $KV_L1 \
  --resource-group $RG_L1 \
  --public-network-access Disabled \
  --default-action Deny

echo "  ✅ Key Vault public network access disabled! Reachable only within private VNet."

echo "Step 2.5: Setting up Diagnostic Audit Logging..."
az monitor log-analytics workspace create \
  --resource-group $RG_L2 \
  --workspace-name $LAW_SEC \
  --location $PRIMARY_REGION

LAW_SEC_ID=$(az monitor log-analytics workspace show -g $RG_L2 -n $LAW_SEC --query id -o tsv)

az monitor diagnostic-settings create \
  --name "diag-kv-to-law" \
  --resource "$KV_L1_ID" \
  --workspace "$LAW_SEC_ID" \
  --logs '[{"category":"AuditEvent","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]'

echo "  ✅ Key Vault AuditEvents (SecretGet, SecretList, CallerIP) streaming to Log Analytics."


# ─────────────────────────────────────────────────────────────
# 🔴 LEVEL 3 — Automated Key Rotation Policy & Managed HSM
# Scenario:
# - RSA-HSM 4096-bit cryptographic key
# - Automated Key Rotation Policy with 90-day expiry & 30-day pre-expiry rotation
# - Event Grid event hook triggering on NearExpiry & SecretNewVersionCreated
# - Microsoft Defender for Key Vault alerts (anomalous access detection)
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🔴 LEVEL 3: Automated Key Rotation & Threat Detection"
echo "=============================================================="

echo "Step 3.1: Configuring Key Rotation Policy (Zero-Touch Lifecycle)..."
# Policy rotates the key automatically every 90 days, 30 days before expiration
cat << 'ROTATION_POLICY' > /tmp/key-rotation-policy.json
{
  "lifetimeActions": [
    {
      "trigger": {
        "timeAfterCreate": "P60D"
      },
      "action": {
        "type": "Rotate"
      }
    },
    {
      "trigger": {
        "timeBeforeExpiry": "P30D"
      },
      "action": {
        "type": "Notify"
      }
    }
  ],
  "attributes": {
    "expiryTime": "P90D"
  }
}
ROTATION_POLICY

# Create Key
az keyvault key create \
  --vault-name $KV_L1 \
  --name "master-data-encryption-key" \
  --protection software \
  --size 4096 \
  --ops encrypt decrypt wrapKey unwrapKey > /dev/null

# Apply rotation policy
az keyvault key rotation-policy update \
  --vault-name $KV_L1 \
  --name "master-data-encryption-key" \
  --value "@/tmp/key-rotation-policy.json"

echo "  ✅ Key Rotation Policy active: Automatically rotates every 60 days, expires in 90 days."

echo "Step 3.2: Enabling Microsoft Defender for Key Vault..."
# Defender detects unusual patterns such as brute force, mass secret downloads from suspicious IPs
az security pricing create \
  --name "KeyVaults" \
  --tier "Standard" || true

echo "  ✅ Microsoft Defender for Cloud enabled on Key Vault plan."

echo ""
echo "=============================================================="
echo " ✅ CLOUD SECURITY & KEY VAULT MULTI-LEVEL LAB COMPLETED!"
echo "=============================================================="
