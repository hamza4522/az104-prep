# 💾 Lab 01 — Storage Accounts & Blob Storage

**Difficulty:** 🟢 Beginner  
**Time:** 60 minutes  
**Goal:** Master Azure Blob Storage — the equivalent of AWS S3 / GCP GCS

---

## Part 1 — Create Storage Account

```bash
RG="rg-storage-lab"
LOCATION="eastus"
# Storage account name: 3-24 chars, lowercase letters and numbers only
STORAGE_NAME="st$(date +%s)lab"

az group create --name $RG --location $LOCATION

# =========================================
# Create Storage Account
# =========================================
az storage account create \
  --resource-group $RG \
  --name $STORAGE_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2 \
  --https-only true \
  --tags Environment=Lab

# Storage SKUs (Redundancy):
# Standard_LRS   — Locally Redundant Storage (3 copies in 1 datacenter)  — like S3 default
# Standard_ZRS   — Zone Redundant Storage (across 3 AZs)
# Standard_GRS   — Geo-Redundant Storage (LRS + replicated to pair region)  — like S3 Cross-Region Replication
# Standard_GZRS  — Geo-Zone Redundant (ZRS + pair region)
# Premium_LRS    — Premium (SSD) for block blobs, file shares
# Premium_ZRS    — Premium Zone Redundant

# View storage account
az storage account show \
  --resource-group $RG \
  --name $STORAGE_NAME \
  --output json

# List all storage accounts
az storage account list --resource-group $RG --output table

# Get storage account keys (like AWS access keys for S3)
az storage account keys list \
  --resource-group $RG \
  --account-name $STORAGE_NAME \
  --output table

# Get connection string
az storage account show-connection-string \
  --resource-group $RG \
  --name $STORAGE_NAME \
  --output tsv
```

---

## Part 2 — Blob Storage Operations

```bash
# Get storage key for authentication
STORAGE_KEY=$(az storage account keys list \
  --resource-group $RG \
  --account-name $STORAGE_NAME \
  --query "[0].value" \
  --output tsv)

# =========================================
# Create Containers (like S3 buckets — but containers are sub-entities)
# =========================================

# Public read for blobs (for website hosting)
az storage container create \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --name "public-assets" \
  --public-access blob

# Private container (default)
az storage container create \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --name "private-data" \
  --public-access off

# Container with full public access (anyone can list blobs)
az storage container create \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --name "downloads" \
  --public-access container

# Backups container
az storage container create \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --name "backups"

# List containers
az storage container list \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --output table
```

### Upload and Manage Blobs

```bash
# =========================================
# Upload files (like aws s3 cp / gsutil cp)
# =========================================

# Create test files
echo "Hello Azure Blob Storage!" > test-file.txt
echo '{"service":"azure","type":"blob","date":"2024"}' > data.json
dd if=/dev/urandom bs=1M count=10 of=large-file.bin 2>/dev/null

# Upload single file
az storage blob upload \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "private-data" \
  --name "test-file.txt" \
  --file test-file.txt \
  --overwrite

# Upload with metadata
az storage blob upload \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "private-data" \
  --name "data/2024/data.json" \
  --file data.json \
  --metadata author=devops project=azure-labs \
  --content-type "application/json"

# Upload with specific blob tier
az storage blob upload \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "backups" \
  --name "backup-$(date +%Y%m%d).bin" \
  --file large-file.bin \
  --tier Cool

# Bulk upload (like aws s3 sync / gsutil -m cp)
mkdir -p local-files
for i in {1..5}; do echo "File $i content" > local-files/file-$i.txt; done

az storage blob upload-batch \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --destination "private-data" \
  --source local-files/ \
  --pattern "*.txt"

echo "✅ Files uploaded"
```

### List and Download Blobs

```bash
# List blobs in container
az storage blob list \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "private-data" \
  --output table

# List with specific prefix (like S3 --prefix for "folders")
az storage blob list \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "private-data" \
  --prefix "data/" \
  --output table

# Show blob properties
az storage blob show \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "private-data" \
  --name "test-file.txt" \
  --output json

# Download single file
az storage blob download \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "private-data" \
  --name "test-file.txt" \
  --file downloaded-test.txt

# Bulk download
az storage blob download-batch \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --source "private-data" \
  --destination ./downloaded-files/ \
  --pattern "*.txt"

# Copy between containers
az storage blob copy start \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --destination-container "backups" \
  --destination-blob "copy-of-test.txt" \
  --source-container "private-data" \
  --source-blob "test-file.txt"

# Copy from URL (e.g., another storage account)
az storage blob copy start \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --destination-container "public-assets" \
  --destination-blob "remote-file.txt" \
  --source-uri "https://otherstorage.blob.core.windows.net/container/file.txt"
```

---

## Part 3 — Blob Tiers (Lifecycle Management)

```bash
# Change blob tier (like S3 storage class)
# Hot → Cool (after 30 days infrequent access)
az storage blob set-tier \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "backups" \
  --name "backup-$(date +%Y%m%d).bin" \
  --tier Cool

# Hot → Archive (for long-term retention)
az storage blob set-tier \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "backups" \
  --name "backup-$(date +%Y%m%d).bin" \
  --tier Archive

# Archive → Hot (rehydration — takes hours!)
az storage blob set-tier \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "backups" \
  --name "backup-$(date +%Y%m%d).bin" \
  --tier Hot \
  --rehydrate-priority High  # High = 1 hour, Standard = 15 hours

# =========================================
# Lifecycle Management Policy (automated tiering)
# Like S3 Lifecycle Rules
# =========================================

cat > lifecycle-policy.json << 'EOF'
{
  "rules": [
    {
      "name": "move-to-cool-after-30-days",
      "enabled": true,
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["data/"]
        },
        "actions": {
          "baseBlob": {
            "tierToCool": {
              "daysAfterModificationGreaterThan": 30
            },
            "tierToArchive": {
              "daysAfterModificationGreaterThan": 90
            },
            "delete": {
              "daysAfterModificationGreaterThan": 365
            }
          },
          "snapshot": {
            "delete": {
              "daysAfterCreationGreaterThan": 90
            }
          }
        }
      }
    },
    {
      "name": "delete-temp-files",
      "enabled": true,
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["temp/"]
        },
        "actions": {
          "baseBlob": {
            "delete": {
              "daysAfterModificationGreaterThan": 7
            }
          }
        }
      }
    }
  ]
}
EOF

# Apply lifecycle policy
az storage account management-policy create \
  --account-name $STORAGE_NAME \
  --resource-group $RG \
  --policy @lifecycle-policy.json

echo "✅ Lifecycle policy applied"
```

---

## Part 4 — SAS Tokens (Signed Access Signatures)

> SAS = Pre-signed URLs in AWS S3 / Signed URLs in GCP GCS

```bash
# =========================================
# Account SAS (full account access with restrictions)
# =========================================
az storage account generate-sas \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --services b \
  --resource-types co \
  --permissions rwdlc \
  --expiry $(date -u -d "1 hour" '+%Y-%m-%dT%H:%MZ') \
  --output tsv

# =========================================
# Container SAS (access to specific container)
# =========================================
CONTAINER_SAS=$(az storage container generate-sas \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --name "public-assets" \
  --permissions rwdl \
  --expiry $(date -u -d "24 hours" '+%Y-%m-%dT%H:%MZ') \
  --output tsv)
echo "Container SAS: $CONTAINER_SAS"

# =========================================
# Blob SAS (access to specific file)
# Like S3 pre-signed URL
# =========================================
BLOB_SAS=$(az storage blob generate-sas \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "private-data" \
  --name "test-file.txt" \
  --permissions r \
  --expiry $(date -u -d "1 hour" '+%Y-%m-%dT%H:%MZ') \
  --output tsv)

# Construct full URL
BLOB_URL="https://${STORAGE_NAME}.blob.core.windows.net/private-data/test-file.txt?${BLOB_SAS}"
echo "Blob SAS URL: $BLOB_URL"

# Test the URL (works without credentials!)
curl "$BLOB_URL"

# =========================================
# Service SAS via User Delegation Key (more secure — uses AAD instead of account key)
# Like S3 pre-signed URLs with IAM role
# =========================================
az storage blob generate-sas \
  --account-name $STORAGE_NAME \
  --container-name "private-data" \
  --name "test-file.txt" \
  --permissions r \
  --expiry $(date -u -d "1 hour" '+%Y-%m-%dT%H:%MZ') \
  --auth-mode login \
  --as-user \
  --output tsv
```

---

## Part 5 — Static Website Hosting

```bash
# Enable static website (like S3 static website hosting)
az storage blob service-properties update \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --static-website \
  --index-document "index.html" \
  --404-document "404.html"

# Get the static website URL
az storage account show \
  --resource-group $RG \
  --name $STORAGE_NAME \
  --query "primaryEndpoints.web" \
  --output tsv

# Create sample website files
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Azure Static Website</title>
  <style>
    body { font-family: Arial; text-align: center; padding: 50px; background: #0078D4; color: white; }
    h1 { font-size: 3em; }
  </style>
</head>
<body>
  <h1>🚀 Hosted on Azure Blob Storage!</h1>
  <p>This static website is powered by Azure Storage.</p>
  <p>Equivalent to S3 static website hosting.</p>
</body>
</html>
EOF

cat > 404.html << 'EOF'
<!DOCTYPE html>
<html><body><h1>404 - Page Not Found</h1></body></html>
EOF

# Upload to the $web container (auto-created when static site enabled)
az storage blob upload \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "\$web" \
  --name "index.html" \
  --file index.html \
  --content-type "text/html"

az storage blob upload \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "\$web" \
  --name "404.html" \
  --file 404.html \
  --content-type "text/html"

WEBSITE_URL=$(az storage account show \
  --resource-group $RG \
  --name $STORAGE_NAME \
  --query "primaryEndpoints.web" \
  --output tsv)

echo "✅ Static website available at: $WEBSITE_URL"
```

---

## Part 6 — Versioning and Soft Delete

```bash
# Enable blob versioning (like S3 versioning)
az storage account blob-service-properties update \
  --account-name $STORAGE_NAME \
  --resource-group $RG \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 30 \
  --enable-container-delete-retention true \
  --container-delete-retention-days 7

# Upload multiple versions of the same blob
echo "Version 1 content" > versioned-file.txt
az storage blob upload \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "private-data" \
  --name "versioned-file.txt" \
  --file versioned-file.txt \
  --overwrite

echo "Version 2 content - updated!" > versioned-file.txt
az storage blob upload \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "private-data" \
  --name "versioned-file.txt" \
  --file versioned-file.txt \
  --overwrite

# List blob versions
az storage blob list \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "private-data" \
  --prefix "versioned-file" \
  --include v \
  --output table

# "Delete" a blob (with soft delete, it's recoverable for 30 days)
az storage blob delete \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "private-data" \
  --name "versioned-file.txt"

# List deleted blobs
az storage blob list \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "private-data" \
  --include d \
  --output table

# Undelete (restore soft-deleted blob)
az storage blob undelete \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --container-name "private-data" \
  --name "versioned-file.txt"
```

---

## Part 7 — Blob Storage Security & Networking

```bash
# Disable public access entirely (recommended for production)
az storage account update \
  --resource-group $RG \
  --name $STORAGE_NAME \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2

# Restrict network access (like S3 bucket policy VPC endpoint condition)
az storage account update \
  --resource-group $RG \
  --name $STORAGE_NAME \
  --default-action Deny \
  --bypass AzureServices

# Allow specific VNet/Subnet
SUBNET_ID="/subscriptions/$(az account show --query id --output tsv)/resourceGroups/rg-networking-lab/providers/Microsoft.Network/virtualNetworks/vnet-prod-eastus/subnets/subnet-private"

az storage account network-rule add \
  --resource-group $RG \
  --account-name $STORAGE_NAME \
  --subnet $SUBNET_ID

# Allow specific IP range
az storage account network-rule add \
  --resource-group $RG \
  --account-name $STORAGE_NAME \
  --ip-address 203.0.113.0/24

# List network rules
az storage account network-rule list \
  --resource-group $RG \
  --account-name $STORAGE_NAME \
  --output json

# Enable CORS (for web applications)
az storage cors add \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY \
  --services b \
  --methods GET HEAD \
  --origins "https://mywebapp.azurewebsites.net" \
  --allowed-headers "*" \
  --exposed-headers "*" \
  --max-age 3600
```

---

## Part 8 — azcopy (High-Performance Data Transfer)

```bash
# Install azcopy
# Windows: https://aka.ms/downloadazcopy-v10-windows
# Linux: 
wget https://aka.ms/downloadazcopy-v10-linux -O azcopy.tar.gz
tar -xf azcopy.tar.gz
chmod +x azcopy*/azcopy
sudo mv azcopy*/azcopy /usr/local/bin/

# Login to azcopy
azcopy login

# Copy local file to blob
azcopy copy 'local-file.txt' "https://${STORAGE_NAME}.blob.core.windows.net/private-data/uploaded.txt"

# Copy blob to local
azcopy copy "https://${STORAGE_NAME}.blob.core.windows.net/private-data/test-file.txt" './downloaded.txt'

# Sync directories (like aws s3 sync)
azcopy sync './local-folder' "https://${STORAGE_NAME}.blob.core.windows.net/private-data/"

# Copy between storage accounts (extremely fast — server-side)
azcopy copy \
  "https://source.blob.core.windows.net/container/blob?SAS_TOKEN" \
  "https://destination.blob.core.windows.net/container/blob?SAS_TOKEN"

# Copy from S3 to Azure (cross-cloud migration!)
azcopy copy \
  "https://mybucket.s3.amazonaws.com/prefix/" \
  "https://${STORAGE_NAME}.blob.core.windows.net/migrated/?${BLOB_SAS}" \
  --recursive

# Show job status
azcopy jobs list
azcopy jobs show <job-id>
```

---

## Cleanup

```bash
az group delete --name rg-storage-lab --yes --no-wait
rm -f test-file.txt data.json large-file.bin index.html 404.html versioned-file.txt lifecycle-policy.json
rm -rf local-files downloaded-files
echo "Cleanup initiated!"
```

---

## ✅ Lab Checklist

- [ ] Created storage account with correct SKU and settings
- [ ] Created containers with different access levels
- [ ] Uploaded single files with metadata
- [ ] Bulk uploaded files with upload-batch
- [ ] Listed and downloaded blobs
- [ ] Changed blob storage tiers
- [ ] Created lifecycle management policy
- [ ] Generated SAS tokens (account, container, blob)
- [ ] Set up static website hosting
- [ ] Enabled blob versioning
- [ ] Used soft delete and restored a blob
- [ ] Configured network firewall rules
- [ ] Used azcopy for high-performance transfer

---

## 📚 Quick Reference: Azure Blob vs AWS S3

| Feature | Azure Blob | AWS S3 |
|---|---|---|
| Container | Container | Bucket |
| URL format | `storageaccount.blob.core.windows.net/container/blob` | `bucket.s3.amazonaws.com/key` |
| Pre-signed URL | SAS Token | Pre-signed URL |
| Versioning | Blob Versioning | S3 Versioning |
| Replication | GRS/GZRS built-in | S3 CRR (separate config) |
| Static website | `$web` container | S3 static website |
| Transfer tool | azcopy | aws s3 sync |
| CLI sync | `az storage blob upload-batch` | `aws s3 sync` |
| Lifecycle | Management Policy | S3 Lifecycle Rules |
| Cold tier | Archive tier | S3 Glacier |
