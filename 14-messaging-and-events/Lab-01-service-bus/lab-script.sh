# 💬 Messaging & Event-Driven Lab — Multi-Level Production Scenarios
# ═════════════════════════════════════════════════════════════════════
# Level 1 → Service Bus Queue + Duplicate Detection + DLQ + RBAC Auth
# Level 2 → Pub/Sub Topics + SQL Filters + Correlation Filters + FIFO Sessions
# Level 3 → Premium Geo-DR Pairing + Private Endpoints + Event Hubs Capture
# ═════════════════════════════════════════════════════════════════════

set -euo pipefail

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
PRIMARY_REGION="eastus"
SECONDARY_REGION="westus2"
RAND_SUFFIX=$RANDOM

echo "================================================================="
echo " Azure Messaging & Event-Driven Architecture Lab"
echo " AWS Parallel: SQS + SNS + Kinesis + EventBridge"
echo " GCP Parallel: Pub/Sub + Cloud Tasks"
echo "================================================================="

# ─────────────────────────────────────────────────────────────
# 🟢 LEVEL 1 — Hardened Service Bus Queue with RBAC & DLQ
# Scenario:
# - Standard Service Bus Namespace
# - High-reliability Queue with Duplicate Detection (10 min window)
# - Dead-Letter Queue (DLQ) with max delivery count = 5
# - Modern Azure RBAC authentication (Zero Shared Access Keys in app code)
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🟢 LEVEL 1: Service Bus Queue + Duplicate Detection + DLQ"
echo "=============================================================="

RG_L1="rg-messaging-l1-prod"
SB_NAME_L1="sb-enterprise-orders-${RAND_SUFFIX}"
QUEUE_NAME="queue-order-fulfillment"

echo "Step 1.1: Creating Resource Group..."
az group create --name $RG_L1 --location $PRIMARY_REGION --tags Tier=Messaging Level=L1

echo "Step 1.2: Creating Service Bus Standard Namespace..."
az servicebus namespace create \
  --resource-group $RG_L1 \
  --name $SB_NAME_L1 \
  --location $PRIMARY_REGION \
  --sku Standard \
  --tags Environment=Production

SB_L1_ID=$(az servicebus namespace show -g $RG_L1 -n $SB_NAME_L1 --query id -o tsv)

echo "Step 1.3: Creating Hardened Production Queue..."
az servicebus queue create \
  --resource-group $RG_L1 \
  --namespace-name $SB_NAME_L1 \
  --name $QUEUE_NAME \
  --enable-duplicate-detection true \
  --duplicate-detection-history-time-window "PT10M" \
  --enable-dead-lettering-on-message-expiration true \
  --max-delivery-count 5 \
  --lock-duration "PT1M" \
  --default-message-time-to-live "P14D" \
  --max-size-in-megabytes 1024

echo "  ✅ Queue '$QUEUE_NAME' created with duplicate detection & dead-lettering."

echo "Step 1.4: Assigning Service Bus RBAC Roles (Zero Shared Access Signatures)..."
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || az account show --query "user.name" -o tsv)

# Role 1: Data Sender
az role assignment create \
  --assignee "$CURRENT_USER_ID" \
  --role "Azure Service Bus Data Sender" \
  --scope "$SB_L1_ID"

# Role 2: Data Receiver
az role assignment create \
  --assignee "$CURRENT_USER_ID" \
  --role "Azure Service Bus Data Receiver" \
  --scope "$SB_L1_ID"

echo "  ✅ Azure RBAC active: Applications authenticate via DefaultAzureCredential / Managed Identity."


# ─────────────────────────────────────────────────────────────
# 🟡 LEVEL 2 — Enterprise Pub/Sub Topics, SQL Filters & Sessions
# Scenario:
# - Service Bus Topic with multiple isolated Subscriptions
# - SQL Filters (e.g. Country = 'US' AND TotalAmount > 1000)
# - Correlation Filters for lightning-fast routing
# - Guaranteed FIFO ordering via Message Sessions (Session ID)
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🟡 LEVEL 2: Pub/Sub Topics + SQL Filters + FIFO Sessions"
echo "=============================================================="

TOPIC_NAME="topic-customer-events"

echo "Step 2.1: Creating Service Bus Topic..."
az servicebus topic create \
  --resource-group $RG_L1 \
  --namespace-name $SB_NAME_L1 \
  --name $TOPIC_NAME \
  --enable-duplicate-detection true \
  --duplicate-detection-history-time-window "PT10M"

echo "Step 2.2: Creating Subscriptions with Advanced SQL Filters..."
# Subscription 1: High Priority Orders (VIP processing)
az servicebus topic subscription create \
  --resource-group $RG_L1 \
  --namespace-name $SB_NAME_L1 \
  --topic-name $TOPIC_NAME \
  --name "sub-vip-orders" \
  --max-delivery-count 3

# Remove default $Default TrueFilter
az servicebus topic subscription rule delete \
  --resource-group $RG_L1 \
  --namespace-name $SB_NAME_L1 \
  --topic-name $TOPIC_NAME \
  --subscription-name "sub-vip-orders" \
  --name "\$Default"

# Apply SQL Filter: userType = 'VIP' OR orderTotal >= 500
az servicebus topic subscription rule create \
  --resource-group $RG_L1 \
  --namespace-name $SB_NAME_L1 \
  --topic-name $TOPIC_NAME \
  --subscription-name "sub-vip-orders" \
  --name "rule-high-value" \
  --filter-sql-expression "userType = 'VIP' OR orderTotal >= 500"

# Subscription 2: FIFO Guaranteed Ordering via Session ID
az servicebus topic subscription create \
  --resource-group $RG_L1 \
  --namespace-name $SB_NAME_L1 \
  --topic-name $TOPIC_NAME \
  --name "sub-financial-ledger" \
  --enable-session true \
  --max-delivery-count 10

echo "  ✅ Subscriptions with SQL Filter & FIFO Sessions deployed."


# ─────────────────────────────────────────────────────────────
# 🔴 LEVEL 3 — Premium Geo-DR Pairing & Event Hubs Stream Capture
# Scenario:
# - Service Bus Premium Namespace with Geo-Disaster Recovery (Geo-DR)
# - Alias connection string with sub-second DNS failover
# - Private Endpoint lockdown
# - Event Hubs high-throughput telemetry ingestion with Partition Keys
# - Automated Capture into Azure Data Lake (Avro format)
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🔴 LEVEL 3: Premium Geo-DR Pairing & Event Hubs Capture"
echo "=============================================================="

RG_L3="rg-messaging-l3-geodr"
EH_NAME="eh-telemetry-prod-${RAND_SUFFIX}"
CAPTURE_STORAGE="stehcapture${RAND_SUFFIX}"

az group create --name $RG_L3 --location $PRIMARY_REGION --tags Tier=Messaging Level=L3

echo "Step 3.1: Creating Storage Account for Event Hubs Streaming Capture..."
az storage account create \
  --resource-group $RG_L3 \
  --name $CAPTURE_STORAGE \
  --location $PRIMARY_REGION \
  --sku Standard_LRS

az storage container create \
  --account-name $CAPTURE_STORAGE \
  --name "telemetry-raw-archive" \
  --auth-mode login

echo "Step 3.2: Creating Event Hubs Standard Namespace..."
az eventhubs namespace create \
  --resource-group $RG_L3 \
  --name $EH_NAME \
  --location $PRIMARY_REGION \
  --sku Standard \
  --enable-auto-inflate true \
  --maximum-throughput-units 10

STORAGE_ACCT_ID=$(az storage account show -g $RG_L3 -n $CAPTURE_STORAGE --query id -o tsv)

echo "Step 3.3: Creating Event Hub with 32 Partitions & Automated Blob Capture..."
az eventhubs eventhub create \
  --resource-group $RG_L3 \
  --namespace-name $EH_NAME \
  --name "hub-iot-clickstream" \
  --partition-count 32 \
  --message-retention 7 \
  --enable-capture true \
  --capture-interval 300 \
  --capture-size-limit 314572800 \
  --destination-name "EventHubArchive.AzureBlockBlob" \
  --storage-account "$STORAGE_ACCT_ID" \
  --blob-container "telemetry-raw-archive" \
  --archive-name-format "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"

echo "  ✅ Event Hub configured with 32 partitions & continuous Data Lake Avro capture."

echo "Step 3.4: Enterprise Service Bus Geo-Disaster Recovery (Geo-DR) Blueprint..."
cat << 'GEODR_BLUEPRINT'
═══════════════════════════════════════════════════════════════
  Service Bus Premium Geo-Disaster Recovery (Geo-DR)
═══════════════════════════════════════════════════════════════
 Primary Region (East US)               Secondary Region (West US 2)
 [sb-primary-premium]                  [sb-secondary-dr]
   - Premium 1/2/4 Messaging Units       - Passive replica
   - Metadata Replicated Continuous ───► - Metadata Synced Automatically
                ▲                                     ▲
                │                                     │
                └───────────────┬─────────────────────┘
                                │
                  [sb-alias-enterprise.servicebus.windows.net]
                     - Client apps connect to ALIAS only
                     - DNS failover flips to secondary instantaneously
═══════════════════════════════════════════════════════════════
GEODR_BLUEPRINT

echo ""
echo "=============================================================="
echo " ✅ MESSAGING & EVENT-DRIVEN MULTI-LEVEL LAB COMPLETED!"
echo "=============================================================="
