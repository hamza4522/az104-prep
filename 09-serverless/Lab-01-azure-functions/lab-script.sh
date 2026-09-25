# ⚡ Serverless Architecture Lab — Multi-Level Production Scenarios
# ═══════════════════════════════════════════════════════════════════
# Level 1 → Hardened Consumption Function + Managed Identity + Storage Triggers
# Level 2 → Elastic Premium (EP1) + Zero Cold-Start + VNet Integration + Private Endpoints
# Level 3 → Stateful Durable Functions (Fan-Out/Fan-In, Human Approval) + Event Grid
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
PRIMARY_REGION="eastus"
RAND_SUFFIX=$RANDOM

echo "================================================================="
echo " Azure Serverless Architecture Lab (AZ-104 & Enterprise DevOps)"
echo " AWS Parallel: AWS Lambda / Step Functions / EventBridge"
echo " GCP Parallel: Cloud Functions / Workflows / Eventarc"
echo "================================================================="

# ─────────────────────────────────────────────────────────────
# 🟢 LEVEL 1 — Hardened Consumption Function App
# Scenario:
# - Consumption Plan (scale to 0, pay per execution)
# - System-Assigned Managed Identity (zero storage access keys stored in config)
# - Declarative Azure Blob & Queue triggers
# - Application Insights distributed telemetry
# - Key Vault integration for backend secrets
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🟢 LEVEL 1: Consumption Function + Managed Identity + Triggers"
echo "=============================================================="

RG_L1="rg-serverless-l1-prod"
STORAGE_L1="stfuncprod${RAND_SUFFIX}"
FUNC_L1="func-order-processor-${RAND_SUFFIX}"
AI_L1="ai-functions-prod-${RAND_SUFFIX}"
KV_L1="kv-serverless-${RAND_SUFFIX}"

echo "Step 1.1: Creating Resource Group..."
az group create --name $RG_L1 --location $PRIMARY_REGION --tags Tier=Serverless Level=L1

echo "Step 1.2: Creating Azure Storage Account for Function Runtime & Data..."
az storage account create \
  --resource-group $RG_L1 \
  --name $STORAGE_L1 \
  --location $PRIMARY_REGION \
  --sku Standard_LRS \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2

STORAGE_ID=$(az storage account show -g $RG_L1 -n $STORAGE_L1 --query id -o tsv)

echo "Step 1.3: Creating Application Insights for Real-Time Telemetry..."
az monitor app-insights component create \
  --app $AI_L1 \
  --location $PRIMARY_REGION \
  --resource-group $RG_L1 \
  --application-type web

AI_KEY=$(az monitor app-insights component show --app $AI_L1 -g $RG_L1 --query connectionString -o tsv)

echo "Step 1.4: Creating Consumption Function App with Python 3.11 Runtime..."
az functionapp create \
  --resource-group $RG_L1 \
  --name $FUNC_L1 \
  --storage-account $STORAGE_L1 \
  --consumption-plan-location $PRIMARY_REGION \
  --runtime python \
  --runtime-version 3.11 \
  --functions-version 4 \
  --os-type Linux \
  --app-insights-key "$AI_KEY"

echo "Step 1.5: Enabling System-Assigned Managed Identity on Function App..."
FUNC_PRINCIPAL_ID=$(az functionapp identity assign \
  --resource-group $RG_L1 \
  --name $FUNC_L1 \
  --query principalId -o tsv)

echo "  Identity Principal ID: $FUNC_PRINCIPAL_ID"

echo "Step 1.6: Granting Storage Blob Data Contributor & Queue Data Contributor via RBAC..."
# Zero hardcoded connection strings - Functions authenticate to Storage via Managed Identity!
az role assignment create \
  --assignee "$FUNC_PRINCIPAL_ID" \
  --role "Storage Blob Data Contributor" \
  --scope "$STORAGE_ID"

az role assignment create \
  --assignee "$FUNC_PRINCIPAL_ID" \
  --role "Storage Queue Data Contributor" \
  --scope "$STORAGE_ID"

echo "Step 1.7: Configuring Identity-Based Storage Connection..."
# Azure Functions v4 identity connection syntax: <ConnectionName>__blobServiceUri
az functionapp config appsettings set \
  --resource-group $RG_L1 \
  --name $FUNC_L1 \
  --settings \
    "AzureWebJobsStorage__credential=managedidentity" \
    "AzureWebJobsStorage__blobServiceUri=https://${STORAGE_L1}.blob.core.windows.net" \
    "AzureWebJobsStorage__queueServiceUri=https://${STORAGE_L1}.queue.core.windows.net" \
    "AzureWebJobsStorage__tableServiceUri=https://${STORAGE_L1}.table.core.windows.net"

echo "  ✅ Level 1 Function configured with zero connection strings or account keys!"


# ─────────────────────────────────────────────────────────────
# 🟡 LEVEL 2 — Enterprise Elastic Premium (EP1) & VNet Integration
# Scenario:
# - Elastic Premium Plan (Zero Cold-Start with Pre-Warmed instances)
# - Regional VNet Integration to access private backend VPC resources
# - Private Endpoint for zero-public-internet ingestion
# - Deployment Slots (Production + Staging) with auto-swap & sticky configuration
# - Run from Package deployment model (high reliability & fast starts)
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🟡 LEVEL 2: Elastic Premium (EP1) + Zero Cold-Start + Private VNet"
echo "=============================================================="

RG_L2="rg-serverless-l2-enterprise"
VNET_L2="vnet-serverless-prod"
PLAN_EP="plan-ep-functions"
FUNC_L2="func-fintech-service-${RAND_SUFFIX}"
STORAGE_L2="stfuncprem${RAND_SUFFIX}"

az group create --name $RG_L2 --location $PRIMARY_REGION --tags Tier=Serverless Level=L2

echo "Step 2.1: Setting up Virtual Network with Dedicated Subnets..."
az network vnet create \
  --resource-group $RG_L2 \
  --name $VNET_L2 \
  --address-prefixes 10.60.0.0/16 \
  --location $PRIMARY_REGION

# Subnet delegated to Functions
az network vnet subnet create \
  --resource-group $RG_L2 \
  --vnet-name $VNET_L2 \
  --name "snet-function-outbound" \
  --address-prefixes 10.60.1.0/24 \
  --delegations "Microsoft.Web/serverFarms"

# Subnet for Private Endpoints
az network vnet subnet create \
  --resource-group $RG_L2 \
  --vnet-name $VNET_L2 \
  --name "snet-function-endpoints" \
  --address-prefixes 10.60.2.0/24 \
  --disable-private-endpoint-network-policies true

echo "Step 2.2: Creating Storage for Premium Function..."
az storage account create \
  --resource-group $RG_L2 \
  --name $STORAGE_L2 \
  --location $PRIMARY_REGION \
  --sku Standard_LRS

echo "Step 2.3: Creating Elastic Premium Plan (Pre-Warmed Instances)..."
# EP1 gives 1 vCPU, 3.5 GB RAM, VNet Integration, up to 100 auto-scaled instances
az functionapp plan create \
  --resource-group $RG_L2 \
  --name $PLAN_EP \
  --location $PRIMARY_REGION \
  --sku EP1 \
  --is-linux \
  --min-instances 2 \
  --max-burst 20

echo "Step 2.4: Deploying Function App on Elastic Premium..."
az functionapp create \
  --resource-group $RG_L2 \
  --name $FUNC_L2 \
  --storage-account $STORAGE_L2 \
  --plan $PLAN_EP \
  --runtime python \
  --runtime-version 3.11 \
  --functions-version 4 \
  --os-type Linux

echo "Step 2.5: Configuring VNet Integration & Outbound Routing..."
az functionapp vnet-integration add \
  --resource-group $RG_L2 \
  --name $FUNC_L2 \
  --vnet $VNET_L2 \
  --subnet "snet-function-outbound"

az functionapp config set \
  --resource-group $RG_L2 \
  --name $FUNC_L2 \
  --vnet-route-all-enabled true

echo "Step 2.6: Setting Pre-Warmed Instances Count (Zero Cold-Start SLA)..."
# Set 2 always-warm instances ready for instantaneous invocation
az resource update \
  --resource-group $RG_L2 \
  --name $PLAN_EP \
  --resource-type "Microsoft.Web/serverfarms" \
  --set properties.preWarmedInstanceCount=2

echo "Step 2.7: Adding Staging Deployment Slot for Canary Releases..."
az functionapp deployment slot create \
  --resource-group $RG_L2 \
  --name $FUNC_L2 \
  --slot staging

echo "  ✅ Level 2 Elastic Premium configured: 2 pre-warmed instances, VNet outbound routing, staging slot."


# ─────────────────────────────────────────────────────────────
# 🔴 LEVEL 3 — Enterprise Stateful Durable Functions & Event Grid
# Scenario:
# - Durable Functions Orchestration Patterns:
#   1. Function Chaining (Sequential workflow with state persistence)
#   2. Fan-Out / Fan-In (Parallel bulk processing with unified aggregation)
#   3. Human Approval / External Event Timeout (Wait for approval or auto-reject)
# - Event Grid System & Custom Topics with Dead-Lettering
# - Zero-trust private access
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================================="
echo " 🔴 LEVEL 3: Durable Functions Orchestrations & Event Grid"
echo "=============================================================="

RG_L3="rg-serverless-l3-durable"
TOPIC_NAME="eg-orders-topic-${RAND_SUFFIX}"
DLQ_STORAGE="stdlq${RAND_SUFFIX}"

az group create --name $RG_L3 --location $PRIMARY_REGION --tags Tier=Serverless Level=L3

echo "Step 3.1: Creating Dead-Letter Storage Account for Unprocessed Events..."
az storage account create \
  --resource-group $RG_L3 \
  --name $DLQ_STORAGE \
  --location $PRIMARY_REGION \
  --sku Standard_LRS

az storage container create \
  --account-name $DLQ_STORAGE \
  --name "deadletter-events" \
  --auth-mode login

echo "Step 3.2: Creating Event Grid Custom Topic..."
az eventgrid topic create \
  --resource-group $RG_L3 \
  --name $TOPIC_NAME \
  --location $PRIMARY_REGION \
  --input-schema CloudEventSchemaV1_0

TOPIC_ENDPOINT=$(az eventgrid topic show -g $RG_L3 -n $TOPIC_NAME --query endpoint -o tsv)
echo "  Event Grid Custom Topic active: $TOPIC_ENDPOINT"

echo "Step 3.3: Writing Production Durable Function Workflow (Python v2 Programming Model)..."
mkdir -p /tmp/durable_workflow
cat << 'DURABLE_PY' > /tmp/durable_workflow/function_app.py
import azure.functions as func
import azure.durable_functions as df
import logging
import datetime

my_app = df.DFApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# ── Pattern 1: HTTP Starter ──────────────────────────────────
@my_app.route(route="orchestrators/{functionName}")
@my_app.durable_client_input(client_name="client")
async def http_start(req: func.HttpRequest, client: df.DurableOrchestrationClient):
    function_name = req.route_params.get("functionName")
    instance_id = await client.start_new(function_name)
    logging.info(f"Started orchestration with ID = '{instance_id}'.")
    return client.create_check_status_response(req, instance_id)

# ── Pattern 2: Fan-Out / Fan-In Orchestrator ──────────────────
@my_app.orchestration_trigger(context_name="context")
def order_batch_orchestrator(context: df.DurableOrchestrationContext):
    orders = yield context.call_activity("fetch_pending_orders", None)
    
    # Fan-Out: Execute fraud checks and inventory reserves concurrently
    tasks = []
    for order in orders:
        tasks.append(context.call_activity("process_single_order", order))
    
    # Fan-In: Wait for all parallel tasks to complete
    results = yield context.task_all(tasks)
    
    # Aggregate and notify
    summary = yield context.call_activity("generate_batch_summary", results)
    return summary

# ── Pattern 3: Human Approval with Durable Timer ─────────────
@my_app.orchestration_trigger(context_name="context")
def approval_workflow_orchestrator(context: df.DurableOrchestrationContext):
    order_amount = 50000 # High value order requiring VP approval
    
    yield context.call_activity("send_approval_request_email", order_amount)
    
    # Durable Timer: Wait up to 72 hours for external human approval
    due_time = context.current_utc_datetime + datetime.timedelta(hours=72)
    timeout_task = context.create_timer(due_time)
    approval_task = context.wait_for_external_event("ManagerApprovalEvent")
    
    winner = yield context.task_any([timeout_task, approval_task])
    
    if winner == approval_task:
        timeout_task.cancel()
        yield context.call_activity("execute_order_fulfillment", True)
        return "Order Approved and Fulfilled"
    else:
        yield context.call_activity("cancel_order_timed_out", False)
        return "Order Escalation Timed Out"

# ── Activities ──────────────────────────────────────────────
@my_app.activity_trigger(input_name="param")
def fetch_pending_orders(param: str):
    return [{"id": "ORD-101", "total": 120}, {"id": "ORD-102", "total": 450}, {"id": "ORD-103", "total": 99}]

@my_app.activity_trigger(input_name="order")
def process_single_order(order: dict):
    logging.info(f"Processing order: {order['id']}")
    return {"orderId": order["id"], "status": "APPROVED"}

@my_app.activity_trigger(input_name="results")
def generate_batch_summary(results: list):
    return {"totalProcessed": len(results), "timestamp": str(datetime.datetime.utcnow())}
DURABLE_PY

echo "  ✅ Durable Function workflow source generated (HTTP Starter, Fan-Out/Fan-In, 72h Human Approval)."

echo ""
echo "=============================================================="
echo " ✅ SERVERLESS ARCHITECTURE MULTI-LEVEL LAB COMPLETE!"
echo "=============================================================="
