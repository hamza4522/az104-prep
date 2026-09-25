# 💾 Azure Storage

> **AWS Parallel:** S3 / EBS / EFS → Azure Blob / Managed Disk / Files  
> **GCP Parallel:** GCS / Persistent Disk / Filestore → Azure Blob / Managed Disk / Files

## Storage Services Overview

| Azure Service | AWS Equivalent | GCP Equivalent | Use Case |
|---|---|---|---|
| **Blob Storage** | S3 | Cloud Storage (GCS) | Object/unstructured data |
| **Azure Files** | EFS | Filestore | SMB/NFS file shares |
| **Azure Disks** | EBS | Persistent Disk | VM block storage |
| **Queue Storage** | SQS | Cloud Tasks | Message queuing |
| **Table Storage** | DynamoDB (limited) | Datastore | NoSQL key-value |
| **Data Lake Gen2** | S3 + Athena | GCS + BigQuery | Big data analytics |

## Blob Storage Tiers

| Tier | AWS Equivalent | Access | Cost |
|---|---|---|---|
| Hot | S3 Standard | Frequent | Low access cost, High storage cost |
| Cool | S3 Standard-IA | Infrequent (once/month) | Medium |
| Cold | S3 Glacier Instant | Rarely (once/quarter) | Low |
| Archive | S3 Glacier Deep Archive | Rare (once/year) | Lowest storage, High access cost |

---

## Labs in This Section

| Lab | Title | Difficulty |
|---|---|---|
| Lab-01 | Storage Accounts & Blob Storage | 🟢 |
| Lab-02 | Azure Files & File Sync | 🟡 |
| Lab-03 | Storage Security — SAS, Keys, RBAC | 🟡 |
| Lab-04 | Lifecycle Management & Tiering | 🟡 |
| Lab-05 | Static Website Hosting + CDN | 🟡 |
| Lab-06 | Azure Data Lake Storage Gen2 | 🔴 |
| Lab-07 | Storage Replication & Geo-Redundancy | 🟡 |
| Lab-08 | Azure Backup & Recovery Services Vault | 🔴 |
