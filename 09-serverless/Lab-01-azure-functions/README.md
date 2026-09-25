# ⚡ Lab 01 — Azure Functions: HTTP, Timer & Blob Triggers

**Difficulty:** 🟢 Beginner-Intermediate  
**Time:** 60 minutes  
**Goal:** Create Azure Functions with multiple triggers — the Azure Lambda equivalent

---

## Background

| Azure Functions | AWS Lambda | GCP Cloud Functions |
|---|---|---|
| Consumption plan | On-demand | On-demand |
| Premium plan | Provisioned Concurrency | Min instances |
| App Service plan | EC2 always-on | Always-on |
| Durable Functions | Step Functions | Cloud Workflows |
| Triggers | Event sources | Triggers |
| Bindings | — (manual SDK) | — (manual SDK) |

**Key Advantage: Bindings** — Functions can connect to Storage, Service Bus, Cosmos DB etc. WITH ZERO connection code!

---

## Part 1 — Setup Azure Functions

```bash
RG="rg-serverless-lab"
LOCATION="eastus"
STORAGE_NAME="stfunc$(date +%s)"
FUNC_APP_NAME="func-lab-$(date +%s)"

az group create --name $RG --location $LOCATION

# Create storage account (required for Functions)
az storage account create \
  --resource-group $RG \
  --name $STORAGE_NAME \
  --location $LOCATION \
  --sku Standard_LRS

# Create Function App
az functionapp create \
  --resource-group $RG \
  --name $FUNC_APP_NAME \
  --storage-account $STORAGE_NAME \
  --consumption-plan-location $LOCATION \
  --runtime python \
  --runtime-version 3.11 \
  --functions-version 4 \
  --os-type linux \
  --tags Environment=Lab

echo "✅ Function App created: $FUNC_APP_NAME"
echo "URL: https://${FUNC_APP_NAME}.azurewebsites.net"

# Create a Premium Plan (always warm, VNet integrated)
az functionapp plan create \
  --resource-group $RG \
  --name "plan-functions-premium" \
  --location $LOCATION \
  --sku EP1 \
  --min-instances 1 \
  --max-burst 10

az functionapp create \
  --resource-group $RG \
  --name "${FUNC_APP_NAME}-premium" \
  --storage-account $STORAGE_NAME \
  --plan "plan-functions-premium" \
  --runtime python \
  --runtime-version 3.11 \
  --functions-version 4 \
  --os-type linux
```

---

## Part 2 — Local Development with Azure Functions Core Tools

```bash
# Install Azure Functions Core Tools
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Or on Ubuntu:
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'
sudo apt-get update && sudo apt-get install -y azure-functions-core-tools-4

# Create new function project
mkdir azure-functions-lab && cd azure-functions-lab

func init . --python

# Create functions
func new --name HttpTriggerFunction --template "HTTP trigger" --authlevel "Function"
func new --name TimerFunction --template "Timer trigger"
func new --name BlobTriggerFunction --template "Blob trigger"
func new --name QueueTriggerFunction --template "Azure Queue Storage trigger"
```

---

## Part 3 — HTTP Trigger Function

```python
# HttpTriggerFunction/__init__.py
import azure.functions as func
import json
import logging
import datetime

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('HTTP trigger function processed a request.')
    
    # Get parameters
    name = req.params.get('name')
    if not name:
        try:
            req_body = req.get_json()
            name = req_body.get('name')
        except (ValueError, AttributeError):
            pass
    
    action = req.params.get('action', 'greet')
    
    if name:
        if action == 'greet':
            response = {
                "message": f"Hello, {name}! Welcome to Azure Functions!",
                "timestamp": datetime.datetime.utcnow().isoformat(),
                "method": req.method,
                "url": str(req.url),
                "provider": "Azure Functions",
                "equivalent": "AWS Lambda"
            }
        elif action == 'upper':
            response = {"result": name.upper()}
        else:
            response = {"error": f"Unknown action: {action}"}
        
        return func.HttpResponse(
            json.dumps(response),
            status_code=200,
            mimetype="application/json",
            headers={"Content-Type": "application/json"}
        )
    else:
        return func.HttpResponse(
            json.dumps({"error": "Please pass a name parameter"}),
            status_code=400,
            mimetype="application/json"
        )
```

```json
// HttpTriggerFunction/function.json
{
  "scriptFile": "__init__.py",
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": ["get", "post"],
      "route": "greet/{name?}"
    },
    {
      "type": "http",
      "direction": "out",
      "name": "$return"
    }
  ]
}
```

---

## Part 4 — Timer Trigger Function (Cron)

```python
# TimerFunction/__init__.py
import azure.functions as func
import logging
import datetime
import json

def main(mytimer: func.TimerRequest) -> None:
    utc_timestamp = datetime.datetime.utcnow().replace(
        tzinfo=datetime.timezone.utc
    ).isoformat()
    
    if mytimer.past_due:
        logging.warning('The timer is past due!')
    
    logging.info('Timer function executed at: %s', utc_timestamp)
    
    # Example: cleanup old records
    cleanup_old_data()
    
    # Example: send health report
    send_daily_report()
    
    logging.info('Timer function completed successfully')

def cleanup_old_data():
    # Your cleanup logic here
    logging.info("Cleaning up old data...")
    
def send_daily_report():
    # Your reporting logic here
    logging.info("Sending daily report...")
```

```json
// TimerFunction/function.json
{
  "scriptFile": "__init__.py",
  "bindings": [
    {
      "name": "mytimer",
      "type": "timerTrigger",
      "direction": "in",
      "schedule": "0 0 9 * * 1-5"
    }
  ]
}
```

**Cron expression format for Azure Functions:**
```
{second} {minute} {hour} {day} {month} {day-of-week}

Examples:
"0 */5 * * * *"    — every 5 minutes
"0 0 * * * *"      — every hour
"0 0 9 * * 1-5"    — 9 AM Monday-Friday
"0 30 9 * * *"     — 9:30 AM every day
"0 0 0 1 * *"      — midnight first day of month
```

---

## Part 5 — Blob Trigger + Input/Output Bindings

```python
# BlobProcessorFunction/__init__.py
import azure.functions as func
import logging
import json
import datetime

def main(
    inputBlob: func.InputStream,
    outputBlob: func.Out[str]
) -> None:
    """
    Triggered when a blob is uploaded to the 'raw-data' container.
    Processes it and writes output to 'processed-data' container.
    
    This is the POWER of Azure Function Bindings:
    - No storage SDK initialization code needed
    - No connection string handling
    - Just declare in function.json and use!
    """
    logging.info(f'Blob trigger: {inputBlob.name} ({inputBlob.length} bytes)')
    
    # Read blob content
    content = inputBlob.read().decode('utf-8')
    
    try:
        data = json.loads(content)
        
        # Process the data
        processed = {
            "original_file": inputBlob.name,
            "processed_at": datetime.datetime.utcnow().isoformat(),
            "record_count": len(data) if isinstance(data, list) else 1,
            "data": data,
            "processed_by": "Azure Functions"
        }
        
        # Write to output blob (auto-handled by binding!)
        outputBlob.set(json.dumps(processed, indent=2))
        logging.info(f'✅ Successfully processed and saved output')
        
    except json.JSONDecodeError as e:
        logging.error(f'❌ Invalid JSON: {str(e)}')
        # Write error file
        error_record = {
            "error": str(e),
            "file": inputBlob.name,
            "timestamp": datetime.datetime.utcnow().isoformat()
        }
        outputBlob.set(json.dumps(error_record))
```

```json
// BlobProcessorFunction/function.json
{
  "scriptFile": "__init__.py",
  "bindings": [
    {
      "name": "inputBlob",
      "type": "blobTrigger",
      "direction": "in",
      "path": "raw-data/{name}",
      "connection": "AzureWebJobsStorage"
    },
    {
      "name": "outputBlob",
      "type": "blob",
      "direction": "out",
      "path": "processed-data/{name}",
      "connection": "AzureWebJobsStorage"
    }
  ]
}
```

---

## Part 6 — Cosmos DB Trigger + Service Bus Output Binding

```python
# CosmosDbTriggerFunction/__init__.py
import azure.functions as func
import logging
import json
from typing import List

def main(
    documents: List[func.Document],
    outMessage: func.Out[str]
) -> None:
    """
    Triggered on changes to Cosmos DB collection.
    Sends notifications to Service Bus queue.
    Like DynamoDB Streams → Lambda → SQS
    """
    for document in documents:
        logging.info(f'Processing document: {document["id"]}')
        
        # Create notification message
        notification = {
            "event_type": "document_changed",
            "document_id": document["id"],
            "collection": "orders",
            "timestamp": document.get("_ts", 0),
            "payload": dict(document)
        }
        
        # Send to Service Bus (output binding — no SDK code!)
        outMessage.set(json.dumps(notification))
        logging.info(f'✅ Notification sent for document: {document["id"]}')
```

```json
// CosmosDbTriggerFunction/function.json
{
  "scriptFile": "__init__.py",
  "bindings": [
    {
      "type": "cosmosDBTrigger",
      "name": "documents",
      "direction": "in",
      "connectionStringSetting": "CosmosDBConnection",
      "databaseName": "OrdersDB",
      "containerName": "Orders",
      "leaseContainerName": "leases",
      "createLeaseContainerIfNotExists": true,
      "startFromBeginning": false
    },
    {
      "type": "serviceBus",
      "name": "outMessage",
      "direction": "out",
      "queueName": "order-notifications",
      "connection": "ServiceBusConnection"
    }
  ]
}
```

---

## Part 7 — Deploy and Configure

```bash
# Deploy to Azure
cd azure-functions-lab
func azure functionapp publish $FUNC_APP_NAME

# Or deploy via zip
zip -r function-app.zip . -x "*.pyc" "__pycache__/*" ".venv/*"
az functionapp deployment source config-zip \
  --resource-group $RG \
  --name $FUNC_APP_NAME \
  --src function-app.zip

# Configure app settings (environment variables)
az functionapp config appsettings set \
  --resource-group $RG \
  --name $FUNC_APP_NAME \
  --settings \
    ENVIRONMENT="production" \
    DATABASE_URL="Server=tcp:sqlsrv.database.windows.net" \
    MAX_RETRIES="3"

# Get function URL with key
FUNC_KEY=$(az functionapp function keys list \
  --resource-group $RG \
  --name $FUNC_APP_NAME \
  --function-name HttpTriggerFunction \
  --query "default" \
  --output tsv)

FUNC_URL="https://${FUNC_APP_NAME}.azurewebsites.net/api/HttpTriggerFunction?code=${FUNC_KEY}"
echo "Function URL: $FUNC_URL"

# Test the function
curl "${FUNC_URL}&name=DevOps"
curl -X POST $FUNC_URL \
  -H "Content-Type: application/json" \
  -d '{"name": "Azure Engineer"}'

# View function logs (like CloudWatch Logs)
az monitor app-insights events show \
  --app $FUNC_APP_NAME \
  --type trace \
  --resource-group $RG

# Stream logs (like aws logs tail)
func azure functionapp logstream $FUNC_APP_NAME
```

---

## Part 8 — Function App Settings & Configuration

```bash
# Enable Application Insights (like CloudWatch Metrics)
az monitor app-insights component create \
  --resource-group $RG \
  --app "appi-${FUNC_APP_NAME}" \
  --location $LOCATION \
  --kind web

APP_INSIGHTS_KEY=$(az monitor app-insights component show \
  --resource-group $RG \
  --app "appi-${FUNC_APP_NAME}" \
  --query instrumentationKey \
  --output tsv)

az functionapp config appsettings set \
  --resource-group $RG \
  --name $FUNC_APP_NAME \
  --settings APPINSIGHTS_INSTRUMENTATIONKEY=$APP_INSIGHTS_KEY

# Enable managed identity for Function App
az functionapp identity assign \
  --resource-group $RG \
  --name $FUNC_APP_NAME

IDENTITY_ID=$(az functionapp identity show \
  --resource-group $RG \
  --name $FUNC_APP_NAME \
  --query principalId \
  --output tsv)

# Grant function access to storage
az role assignment create \
  --assignee $IDENTITY_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$RG"

# Configure scaling
az functionapp config set \
  --resource-group $RG \
  --name $FUNC_APP_NAME \
  --min-worker-count 1 \
  --max-worker-count 10

# Set slot settings (deployment slots like Lambda aliases)
az functionapp deployment slot create \
  --resource-group $RG \
  --name $FUNC_APP_NAME \
  --slot staging

# Swap slots (like Lambda version promotion)
az functionapp deployment slot swap \
  --resource-group $RG \
  --name $FUNC_APP_NAME \
  --slot staging \
  --target-slot production
```

---

## Cleanup

```bash
az group delete --name rg-serverless-lab --yes --no-wait
rm -rf azure-functions-lab function-app.zip
```

---

## ✅ Lab Checklist

- [ ] Created Function App (Consumption plan)
- [ ] Set up local development with Core Tools
- [ ] Created HTTP trigger function
- [ ] Created Timer trigger (cron) function
- [ ] Used input/output bindings (Blob Storage)
- [ ] Used Cosmos DB trigger + Service Bus output binding
- [ ] Deployed function to Azure
- [ ] Configured App Settings (environment variables)
- [ ] Enabled Application Insights
- [ ] Enabled Managed Identity for Function App
- [ ] Set up deployment slots (staging/prod)
