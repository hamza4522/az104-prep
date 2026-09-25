# 💬 Lab 01 — Azure Service Bus: Queues & Topics

**Difficulty:** 🟡 Intermediate  
**Time:** 60 minutes  
**Goal:** Master Azure Service Bus for enterprise messaging — the SQS+SNS equivalent

---

## Background

| Feature | Service Bus Queue | SQS | Service Bus Topic |
|---|---|---|---|
| Pattern | Point-to-point | Point-to-point | Pub/Sub (fan-out) |
| Message max size | 256 KB (standard) / 100 MB (premium) | 256 KB | Same |
| Retention | Up to 14 days | Up to 14 days | Up to 14 days |
| Dead letter queue | Built-in | Separate SQS DLQ | Built-in |
| Message sessions | Yes (FIFO guaranteed) | FIFO queue (separate) | Yes |
| Transactions | Yes | No | Yes |
| Duplicate detection | Yes | No (SQS FIFO only) | Yes |

---

## Part 1 — Create Service Bus Namespace

```bash
RG="rg-messaging-lab"
LOCATION="eastus"
SB_NAMESPACE="sb-lab-$(date +%s)"

az group create --name $RG --location $LOCATION

# Create Service Bus namespace
az servicebus namespace create \
  --resource-group $RG \
  --name $SB_NAMESPACE \
  --location $LOCATION \
  --sku Standard \
  --tags Environment=Lab

# SKUs:
# Basic:   Queues only, no topics, 256KB messages
# Standard: Queues + Topics, 256KB messages
# Premium: 100MB messages, geo-disaster recovery, VNet integration

# Get connection string
CONN_STRING=$(az servicebus namespace authorization-rule keys list \
  --resource-group $RG \
  --namespace-name $SB_NAMESPACE \
  --name RootManageSharedAccessKey \
  --query primaryConnectionString \
  --output tsv)

echo "Connection string: $CONN_STRING"

# View namespace
az servicebus namespace show \
  --resource-group $RG \
  --name $SB_NAMESPACE \
  --output json
```

---

## Part 2 — Service Bus Queues

```bash
# =========================================
# Create Queues
# =========================================

# Basic queue
az servicebus queue create \
  --resource-group $RG \
  --namespace-name $SB_NAMESPACE \
  --name "order-processing" \
  --max-size 1024 \
  --default-message-time-to-live P14D \
  --lock-duration PT30S \
  --dead-lettering-on-message-expiration true \
  --enable-duplicate-detection true \
  --duplicate-detection-history-time-window PT10M

# Session-enabled queue (guarantees FIFO per session)
az servicebus queue create \
  --resource-group $RG \
  --namespace-name $SB_NAMESPACE \
  --name "sequential-orders" \
  --requires-session true \
  --max-delivery-count 5

# High-throughput queue with partitioning
az servicebus queue create \
  --resource-group $RG \
  --namespace-name $SB_NAMESPACE \
  --name "high-volume-events" \
  --enable-partitioning true \
  --max-size 4096

# List queues
az servicebus queue list \
  --resource-group $RG \
  --namespace-name $SB_NAMESPACE \
  --output table

# Show queue details
az servicebus queue show \
  --resource-group $RG \
  --namespace-name $SB_NAMESPACE \
  --name "order-processing" \
  --output json
```

### Python — Send and Receive Messages

```python
# requirements: pip install azure-servicebus

from azure.servicebus import ServiceBusClient, ServiceBusMessage
from azure.identity import DefaultAzureCredential
import json
import time

# Connection options:
# 1. Connection string (simple, for dev)
CONN_STRING = "Endpoint=sb://sb-lab.servicebus.windows.net/;SharedAccessKeyName=..."

# 2. Azure AD (recommended for production — no secrets!)
NAMESPACE = "sb-lab-123456.servicebus.windows.net"
credential = DefaultAzureCredential()

# =========================================
# SEND MESSAGES
# =========================================
def send_messages():
    with ServiceBusClient.from_connection_string(CONN_STRING) as client:
        with client.get_queue_sender("order-processing") as sender:
            
            # Send single message
            order = {
                "order_id": "ORD-001",
                "customer": "Alice Smith",
                "items": [
                    {"product": "Widget A", "qty": 2, "price": 25.99},
                    {"product": "Widget B", "qty": 1, "price": 45.99}
                ],
                "total": 97.97,
                "status": "pending"
            }
            
            message = ServiceBusMessage(
                json.dumps(order),
                content_type="application/json",
                subject="OrderCreated",
                message_id="ORD-001",
                application_properties={
                    "source": "web-frontend",
                    "priority": "normal",
                    "region": "eastus"
                }
            )
            
            sender.send_messages(message)
            print(f"✅ Sent: {order['order_id']}")
            
            # Send batch of messages (like SQS SendMessageBatch)
            batch = sender.create_message_batch()
            for i in range(1, 11):
                order = {
                    "order_id": f"ORD-{i:04d}",
                    "customer": f"Customer {i}",
                    "total": i * 10.99
                }
                msg = ServiceBusMessage(
                    json.dumps(order),
                    subject="OrderCreated",
                    application_properties={"batch": True}
                )
                batch.add_message(msg)
            
            sender.send_messages(batch)
            print(f"✅ Sent batch of 10 messages")
            
            # Scheduled message (delay delivery)
            future_order = ServiceBusMessage(
                json.dumps({"order_id": "FUTURE-001", "note": "Scheduled"}),
                subject="ScheduledOrder"
            )
            scheduled_time = time.time() + 300  # 5 minutes from now
            sender.schedule_messages(future_order, scheduled_time)
            print("✅ Scheduled message for 5 minutes from now")

# =========================================
# RECEIVE AND PROCESS MESSAGES
# =========================================
def receive_messages():
    with ServiceBusClient.from_connection_string(CONN_STRING) as client:
        with client.get_queue_receiver("order-processing", max_wait_time=5) as receiver:
            
            # Receive messages (peek-lock by default — like SQS visibility timeout)
            messages = receiver.receive_messages(max_message_count=10, max_wait_time=5)
            
            for msg in messages:
                try:
                    order = json.loads(str(msg))
                    print(f"Processing: {order['order_id']} - ${order['total']}")
                    
                    # Process the order...
                    process_order(order)
                    
                    # Complete (delete) — like SQS DeleteMessage
                    receiver.complete_message(msg)
                    print(f"✅ Completed: {order['order_id']}")
                    
                except Exception as e:
                    print(f"❌ Error: {e}")
                    # Dead-letter the message (like SQS DLQ after max retries)
                    receiver.dead_letter_message(
                        msg,
                        reason="ProcessingFailed",
                        error_description=str(e)
                    )
                    
                    # Or: abandon (make visible again — increment delivery count)
                    # receiver.abandon_message(msg)
                    
                    # Or: defer (hold for later processing)
                    # seq_num = receiver.defer_message(msg)

def process_order(order):
    # Simulate processing
    time.sleep(0.1)
    print(f"  → Processed order {order['order_id']}")

# Read dead-letter queue
def read_dead_letter_queue():
    with ServiceBusClient.from_connection_string(CONN_STRING) as client:
        with client.get_queue_receiver(
            "order-processing",
            sub_queue=ServiceBusSubQueue.DEAD_LETTER,
            max_wait_time=5
        ) as receiver:
            messages = receiver.receive_messages(max_message_count=10, max_wait_time=5)
            for msg in messages:
                print(f"DLQ Message: {str(msg)}")
                print(f"  Reason: {msg.dead_letter_reason}")
                # Re-process or discard
                receiver.complete_message(msg)

# Run
send_messages()
receive_messages()
```

---

## Part 3 — Service Bus Topics (Pub/Sub)

```bash
# =========================================
# Create Topic (like SNS Topic)
# =========================================
az servicebus topic create \
  --resource-group $RG \
  --namespace-name $SB_NAMESPACE \
  --name "domain-events" \
  --max-size 4096 \
  --default-message-time-to-live P7D \
  --enable-duplicate-detection true

# =========================================
# Create Subscriptions (like SNS Subscriptions)
# Each subscription gets its own copy of the message
# =========================================

# Email notifications subscription
az servicebus topic subscription create \
  --resource-group $RG \
  --namespace-name $SB_NAMESPACE \
  --topic-name "domain-events" \
  --name "email-notifications" \
  --max-delivery-count 3 \
  --dead-lettering-on-message-expiration true

# Analytics subscription
az servicebus topic subscription create \
  --resource-group $RG \
  --namespace-name $SB_NAMESPACE \
  --topic-name "domain-events" \
  --name "analytics-pipeline" \
  --max-delivery-count 10

# Audit log subscription
az servicebus topic subscription create \
  --resource-group $RG \
  --namespace-name $SB_NAMESPACE \
  --topic-name "domain-events" \
  --name "audit-log" \
  --max-delivery-count 5

# =========================================
# Add Subscription Filters (like SNS filter policy)
# Only receive messages matching the filter
# =========================================

# SQL Filter: only OrderCreated events
az servicebus topic subscription rule create \
  --resource-group $RG \
  --namespace-name $SB_NAMESPACE \
  --topic-name "domain-events" \
  --subscription-name "email-notifications" \
  --name "order-created-filter" \
  --filter-sql-expression "subject = 'OrderCreated' AND priority = 'high'"

# Correlation filter (more efficient than SQL filter)
az servicebus topic subscription rule create \
  --resource-group $RG \
  --namespace-name $SB_NAMESPACE \
  --topic-name "domain-events" \
  --subscription-name "analytics-pipeline" \
  --name "all-orders-filter" \
  --action-sql-expression "SET label = 'analytics'" \
  --filter-sql-expression "subject LIKE 'Order%'"

# List subscriptions
az servicebus topic subscription list \
  --resource-group $RG \
  --namespace-name $SB_NAMESPACE \
  --topic-name "domain-events" \
  --output table
```

### Topic Publisher and Subscriber

```python
# Topic publisher (same as queue, just different entity name)
def publish_domain_event(event_type: str, payload: dict):
    with ServiceBusClient.from_connection_string(CONN_STRING) as client:
        with client.get_topic_sender("domain-events") as sender:
            message = ServiceBusMessage(
                json.dumps(payload),
                subject=event_type,
                content_type="application/json",
                application_properties={
                    "source": "order-service",
                    "priority": "high" if payload.get("total", 0) > 1000 else "normal",
                    "region": "eastus"
                }
            )
            sender.send_messages(message)
            print(f"✅ Published {event_type}")

# Topic subscriber
def subscribe_to_topic(subscription_name: str):
    with ServiceBusClient.from_connection_string(CONN_STRING) as client:
        with client.get_subscription_receiver(
            "domain-events",
            subscription_name,
            max_wait_time=5
        ) as receiver:
            messages = receiver.receive_messages(max_message_count=10, max_wait_time=5)
            for msg in messages:
                event = json.loads(str(msg))
                print(f"[{subscription_name}] Received: {msg.subject} - {event}")
                receiver.complete_message(msg)

# Publish events
publish_domain_event("OrderCreated", {"order_id": "ORD-001", "total": 1500, "customer": "Alice"})
publish_domain_event("OrderShipped", {"order_id": "ORD-001", "tracking": "TRK-XYZ"})
publish_domain_event("PaymentProcessed", {"order_id": "ORD-001", "amount": 1500})

# Each subscription independently receives
subscribe_to_topic("email-notifications")
subscribe_to_topic("analytics-pipeline")
subscribe_to_topic("audit-log")
```

---

## Part 4 — RBAC for Service Bus

```bash
# =========================================
# Grant access via RBAC (no connection strings needed!)
# Like SQS IAM policy
# =========================================

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
SB_ID=$(az servicebus namespace show --resource-group $RG --name $SB_NAMESPACE --query id --output tsv)

# Grant Sender permission (Azure Service Bus Data Sender role)
az role assignment create \
  --assignee "sp-app@${DOMAIN}" \
  --role "Azure Service Bus Data Sender" \
  --scope "$SB_ID/queues/order-processing"

# Grant Receiver permission
az role assignment create \
  --assignee "sp-worker@${DOMAIN}" \
  --role "Azure Service Bus Data Receiver" \
  --scope "$SB_ID/queues/order-processing"

# Owner permission (send + receive + manage)
az role assignment create \
  --assignee "sp-admin@${DOMAIN}" \
  --role "Azure Service Bus Data Owner" \
  --scope "$SB_ID"
```

---

## Cleanup

```bash
az group delete --name rg-messaging-lab --yes --no-wait
```

---

## ✅ Lab Checklist

- [ ] Created Service Bus namespace
- [ ] Created queue with dead-lettering
- [ ] Created session-enabled queue (FIFO)
- [ ] Sent single and batch messages via Python
- [ ] Received and processed messages with peek-lock
- [ ] Dead-lettered failed messages
- [ ] Created Topic (pub/sub)
- [ ] Created multiple subscriptions
- [ ] Added SQL filters to subscriptions
- [ ] Configured RBAC for queue access
