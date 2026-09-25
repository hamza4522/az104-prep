# 💬 Messaging and Events

> **AWS Parallel:** SQS + SNS + Kinesis → Azure Service Bus + Event Grid + Event Hubs  
> **GCP Parallel:** Pub/Sub + Eventarc → Azure Service Bus + Event Grid

## When to Use Which Service

| Scenario | Use | AWS Equiv | GCP Equiv |
|---|---|---|---|
| Decouple microservices (queue) | Service Bus Queue | SQS | Cloud Tasks |
| Fan-out to multiple subscribers | Service Bus Topic | SNS | Pub/Sub |
| React to Azure resource events | Event Grid | EventBridge | Eventarc |
| Big data streaming | Event Hubs | Kinesis Data Streams | Pub/Sub |
| IoT telemetry at scale | Event Hubs / IoT Hub | IoT Core | Cloud IoT Core |
| Simple app notification | Notification Hubs | SNS Mobile Push | Firebase |

---

## Labs in This Section

| Lab | Title | Difficulty |
|---|---|---|
| Lab-01 | Azure Service Bus — Queues & Topics | 🟡 |
| Lab-02 | Azure Event Grid — Resource Events | 🟡 |
| Lab-03 | Azure Event Hubs — Big Data Streaming | 🔴 |
