# ⚡ Azure Serverless (Functions & Logic Apps)

> **AWS Parallel:** Lambda + Step Functions + EventBridge → Azure Functions + Durable Functions + Logic Apps  
> **GCP Parallel:** Cloud Functions + Workflows + Cloud Scheduler → Azure Functions + Logic Apps

## Serverless Services Overview

| Azure Service | AWS Equivalent | GCP Equivalent | Purpose |
|---|---|---|---|
| **Azure Functions** | AWS Lambda | Cloud Functions | Event-driven serverless code |
| **Durable Functions** | Step Functions | Cloud Workflows | Stateful workflow orchestration |
| **Logic Apps** | Step Functions + EventBridge | Cloud Workflows + Pub/Sub | Low-code workflow automation |
| **Event Grid** | EventBridge | Eventarc | Event routing (pub/sub) |
| **Event Hubs** | Kinesis Data Streams | Cloud Pub/Sub | Big data event streaming |
| **Service Bus** | SQS + SNS | Pub/Sub | Enterprise messaging |

---

## Labs in This Section

| Lab | Title | Difficulty |
|---|---|---|
| Lab-01 | Azure Functions — HTTP, Timer, Blob Triggers | 🟢 |
| Lab-02 | Durable Functions — Orchestration Patterns | 🔴 |
| Lab-03 | Event Grid — Event Routing | 🟡 |
| Lab-04 | Logic Apps — Low-Code Workflows | 🟡 |
| Lab-05 | Service Bus — Queues & Topics | 🟡 |
