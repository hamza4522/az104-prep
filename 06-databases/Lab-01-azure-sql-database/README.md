# 🗄️ Lab 01 — Azure SQL Database: Create, Connect & Manage

**Difficulty:** 🟢 Beginner-Intermediate  
**Time:** 60 minutes  
**Goal:** Deploy and manage Azure SQL Database — Azure's fully managed SQL Server PaaS

---

## Background

| Concept | Azure SQL Database | AWS RDS SQL Server | GCP Cloud SQL |
|---|---|---|---|
| Service tier | DTU / vCore model | Instance class | Machine type |
| High availability | Built-in (99.99%) | Multi-AZ | HA replica |
| Backups | Automatic (7–35 days) | Automated backups | Automated backups |
| Geo-replication | Active Geo-Replication | Read Replicas + Cross-region | Cross-region replicas |
| Serverless | Serverless tier | — | — |
| Managed Instance | SQL Managed Instance | RDS SQL Server | — |

---

## Part 1 — Create SQL Server and Database

```bash
RG="rg-database-lab"
LOCATION="eastus"
SQL_SERVER="sqlsrv-lab-$(date +%s)"  # Must be globally unique
DB_NAME="db-sampleapp"
SQL_ADMIN="sqladmin"
SQL_PASSWORD="SecureP@ss2024!"

az group create --name $RG --location $LOCATION

# =========================================
# Create Azure SQL Server (the logical server)
# Like creating an RDS instance
# =========================================
az sql server create \
  --resource-group $RG \
  --name $SQL_SERVER \
  --location $LOCATION \
  --admin-user $SQL_ADMIN \
  --admin-password $SQL_PASSWORD

echo "✅ SQL Server created: ${SQL_SERVER}.database.windows.net"

# =========================================
# Create Database (serverless — auto-pauses when idle)
# =========================================
az sql db create \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name $DB_NAME \
  --edition GeneralPurpose \
  --family Gen5 \
  --capacity 2 \
  --compute-model Serverless \
  --auto-pause-delay 60 \
  --min-capacity 0.5 \
  --backup-storage-redundancy Local \
  --tags Environment=Lab Project=Demo

# View database details
az sql db show \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name $DB_NAME \
  --output json

# List databases on server
az sql db list \
  --resource-group $RG \
  --server $SQL_SERVER \
  --output table

# Check service objective (performance tier)
az sql db show \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name $DB_NAME \
  --query "{Name:name, Edition:edition, ServiceObjective:currentServiceObjectiveName, MaxSizeGB:maxSizeBytes}" \
  --output json
```

### Other Database Tiers

```bash
# Basic tier (DTU-based — simple workloads)
az sql db create \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name "db-basic" \
  --edition Basic \
  --capacity 5   # 5 DTUs

# Standard tier
az sql db create \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name "db-standard" \
  --edition Standard \
  --capacity 50   # S2 = 50 DTUs

# Business Critical (highest performance, built-in HA)
az sql db create \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name "db-businesscritical" \
  --edition BusinessCritical \
  --family Gen5 \
  --capacity 4   # 4 vCores

# Hyperscale (up to 100TB, auto-scaling storage)
az sql db create \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name "db-hyperscale" \
  --edition Hyperscale \
  --family Gen5 \
  --capacity 4 \
  --read-replicas 1
```

---

## Part 2 — Firewall Rules

```bash
# =========================================
# Configure firewall rules (like RDS Security Groups)
# By default: NO connections allowed
# =========================================

# Allow Azure services (like enabling "Allow public access from Azure services" in RDS)
az sql server firewall-rule create \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name "AllowAzureServices" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Allow your current public IP
MY_IP=$(curl -s https://api.ipify.org)
az sql server firewall-rule create \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name "AllowMyIP" \
  --start-ip-address $MY_IP \
  --end-ip-address $MY_IP

# Allow IP range (e.g., office network)
az sql server firewall-rule create \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name "AllowOfficeNetwork" \
  --start-ip-address 203.0.113.0 \
  --end-ip-address 203.0.113.255

# List firewall rules
az sql server firewall-rule list \
  --resource-group $RG \
  --server $SQL_SERVER \
  --output table

# Delete a rule
az sql server firewall-rule delete \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name "AllowOfficeNetwork"
```

---

## Part 3 — Connect to Azure SQL Database

```bash
# =========================================
# Connection string formats
# =========================================
echo "JDBC:    jdbc:sqlserver://${SQL_SERVER}.database.windows.net:1433;database=${DB_NAME};user=${SQL_ADMIN}@${SQL_SERVER};password=${SQL_PASSWORD}"
echo "ODBC:    Server=tcp:${SQL_SERVER}.database.windows.net,1433;Initial Catalog=${DB_NAME};Uid=${SQL_ADMIN};Pwd=${SQL_PASSWORD};"
echo ".NET:    Server=tcp:${SQL_SERVER}.database.windows.net,1433;Initial Catalog=${DB_NAME};User ID=${SQL_ADMIN};Password=${SQL_PASSWORD};"
echo "Python:  mssql+pyodbc://${SQL_ADMIN}@${SQL_SERVER}:${SQL_PASSWORD}@${SQL_SERVER}.database.windows.net/${DB_NAME}?driver=ODBC+Driver+18+for+SQL+Server"

# =========================================
# Connect using sqlcmd (install if needed)
# =========================================

# Install sqlcmd on Ubuntu/Debian
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
sudo apt-get update
sudo apt-get install -y mssql-tools unixodbc-dev
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc

# Connect to database
sqlcmd -S "${SQL_SERVER}.database.windows.net" \
  -d "$DB_NAME" \
  -U "$SQL_ADMIN" \
  -P "$SQL_PASSWORD" \
  -Q "SELECT @@VERSION"

# Run T-SQL commands
sqlcmd -S "${SQL_SERVER}.database.windows.net" \
  -d "$DB_NAME" \
  -U "$SQL_ADMIN" \
  -P "$SQL_PASSWORD" << 'EOF'
-- Create tables
CREATE TABLE Employees (
  EmployeeID INT PRIMARY KEY IDENTITY(1,1),
  FirstName NVARCHAR(50) NOT NULL,
  LastName NVARCHAR(50) NOT NULL,
  Email NVARCHAR(100) UNIQUE,
  Department NVARCHAR(50),
  Salary DECIMAL(10,2),
  HireDate DATE DEFAULT GETDATE()
);

-- Insert test data
INSERT INTO Employees (FirstName, LastName, Email, Department, Salary)
VALUES
  ('Alice', 'Smith', 'alice@company.com', 'Engineering', 95000),
  ('Bob', 'Johnson', 'bob@company.com', 'DevOps', 85000),
  ('Carol', 'Williams', 'carol@company.com', 'Security', 90000),
  ('Dave', 'Brown', 'dave@company.com', 'Engineering', 80000),
  ('Eve', 'Davis', 'eve@company.com', 'Management', 120000);

-- Query data
SELECT * FROM Employees;
SELECT Department, COUNT(*) AS Count, AVG(Salary) AS AvgSalary
FROM Employees
GROUP BY Department
ORDER BY AvgSalary DESC;
GO
EOF

# =========================================
# Connect using Python (install pyodbc)
# =========================================
pip install pyodbc

python3 << EOF
import pyodbc

conn_str = (
    f"DRIVER={{ODBC Driver 18 for SQL Server}};"
    f"SERVER={SQL_SERVER}.database.windows.net,1433;"
    f"DATABASE={DB_NAME};"
    f"UID={SQL_ADMIN};"
    f"PWD={SQL_PASSWORD};"
    f"Encrypt=yes;"
    f"TrustServerCertificate=no;"
)

conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

# Query
cursor.execute("SELECT * FROM Employees")
rows = cursor.fetchall()
for row in rows:
    print(row)

conn.close()
print("Connection successful!")
EOF
```

---

## Part 4 — Database Operations

```bash
# =========================================
# Backup and Restore
# =========================================

# Azure SQL automatically backs up every 5-10 minutes!
# Retention: 1-35 days (default 7)

# Change backup retention period
az sql db update \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name $DB_NAME \
  --backup-storage-redundancy Geo

# List restore points
az sql db list-deleted \
  --resource-group $RG \
  --server $SQL_SERVER

# Point-in-time restore (go back to any point in retention window)
RESTORE_TIME=$(date -u -d "10 minutes ago" '+%Y-%m-%dT%H:%M:%SZ')

az sql db restore \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name "db-restored" \
  --dest-name "db-restored-$(date +%s)" \
  --deleted-time "$RESTORE_TIME" \
  --source-db-name $DB_NAME

# =========================================
# Scale Database Up/Down
# =========================================

# Scale up (like resizing RDS instance class)
az sql db update \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name $DB_NAME \
  --capacity 4  # Change vCores

# Scale storage
az sql db update \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name $DB_NAME \
  --max-size 64GB
```

---

## Part 5 — Active Geo-Replication (High Availability)

```bash
# =========================================
# Create a read replica in another region
# Like RDS Read Replicas + Cross-Region
# =========================================

SECONDARY_REGION="westus2"
SECONDARY_SERVER="sqlsrv-secondary-$(date +%s)"

# Create secondary SQL Server
az sql server create \
  --resource-group $RG \
  --name $SECONDARY_SERVER \
  --location $SECONDARY_REGION \
  --admin-user $SQL_ADMIN \
  --admin-password $SQL_PASSWORD

# Configure firewall on secondary
az sql server firewall-rule create \
  --resource-group $RG \
  --server $SECONDARY_SERVER \
  --name "AllowAzureServices" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

az sql server firewall-rule create \
  --resource-group $RG \
  --server $SECONDARY_SERVER \
  --name "AllowMyIP" \
  --start-ip-address $MY_IP \
  --end-ip-address $MY_IP

# Create geo-replica
az sql db replica create \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name $DB_NAME \
  --partner-resource-group $RG \
  --partner-server $SECONDARY_SERVER \
  --partner-database "db-sampleapp-replica"

# View replication details
az sql db replica list-links \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name $DB_NAME \
  --output table

# =========================================
# Failover (promote replica to primary)
# Like RDS Failover / Aurora Failover
# =========================================
az sql db replica set-primary \
  --resource-group $RG \
  --server $SECONDARY_SERVER \
  --name "db-sampleapp-replica"

echo "✅ Failover complete — secondary is now primary!"

# Failback to original region
az sql db replica set-primary \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name $DB_NAME
```

---

## Part 6 — Azure SQL Elastic Pool

```bash
# =========================================
# Elastic Pool — share resources across multiple databases
# Like RDS Multi-tenant setup
# =========================================

# Create an elastic pool
az sql elastic-pool create \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name "epool-shared" \
  --edition GeneralPurpose \
  --family Gen5 \
  --capacity 4 \
  --db-min-capacity 0 \
  --db-max-capacity 2

# Move existing database to elastic pool
az sql db update \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name $DB_NAME \
  --elastic-pool "epool-shared"

# Create new database directly in elastic pool
az sql db create \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name "db-tenant2" \
  --elastic-pool "epool-shared"

az sql db create \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name "db-tenant3" \
  --elastic-pool "epool-shared"

# List databases in pool
az sql elastic-pool list-dbs \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name "epool-shared" \
  --output table
```

---

## Part 7 — Database Security & Azure AD Auth

```bash
# =========================================
# Enable Azure AD authentication (more secure than SQL auth)
# Like RDS IAM authentication
# =========================================

# Set Azure AD admin for the SQL Server
CURRENT_USER=$(az ad signed-in-user show --query userPrincipalName --output tsv)
CURRENT_USER_ID=$(az ad signed-in-user show --query id --output tsv)

az sql server ad-admin create \
  --resource-group $RG \
  --server-name $SQL_SERVER \
  --display-name "AzureAD Admin" \
  --object-id $CURRENT_USER_ID

# Connect with Azure AD credentials
sqlcmd -S "${SQL_SERVER}.database.windows.net" \
  -d "$DB_NAME" \
  -G \
  -U "$CURRENT_USER" \
  -Q "SELECT SYSTEM_USER, SESSION_USER"

# =========================================
# Transparent Data Encryption (TDE) — enabled by default
# Like RDS encryption at rest
# =========================================
az sql db tde show \
  --resource-group $RG \
  --server $SQL_SERVER \
  --database $DB_NAME

# Use customer-managed key (BYOK)
# First create Key Vault and key, then:
# az sql server tde-key set --resource-group $RG --server $SQL_SERVER \
#   --server-key-type AzureKeyVault --kid "https://myvault.vault.azure.net/keys/mykey/..."

# =========================================
# Advanced Threat Protection (like AWS GuardDuty for RDS)
# =========================================
az sql server threat-policy update \
  --resource-group $RG \
  --server $SQL_SERVER \
  --state Enabled \
  --email-addresses "security@company.com" \
  --email-account-admins true

# =========================================
# Audit logging (like RDS audit log)
# =========================================
STORAGE_ACCOUNT=$(az storage account list --resource-group $RG --query "[0].name" --output tsv)

az sql server audit-policy update \
  --resource-group $RG \
  --name $SQL_SERVER \
  --state Enabled \
  --blob-storage-target-state Enabled \
  --storage-account "$STORAGE_ACCOUNT"
```

---

## Cleanup

```bash
az group delete --name rg-database-lab --yes --no-wait
echo "Database lab cleanup initiated!"
```

---

## ✅ Lab Checklist

- [ ] Created Azure SQL Server (logical server)
- [ ] Created database with Serverless tier
- [ ] Configured firewall rules
- [ ] Connected using sqlcmd
- [ ] Created and queried tables with T-SQL
- [ ] Connected via Python/pyodbc
- [ ] Performed point-in-time restore
- [ ] Set up Active Geo-Replication
- [ ] Performed manual failover
- [ ] Created Elastic Pool
- [ ] Enabled Azure AD authentication
- [ ] Configured audit logging
