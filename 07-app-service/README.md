# 🌐 Azure App Service

> **AWS Parallel:** Elastic Beanstalk + Amplify → Azure App Service  
> **GCP Parallel:** App Engine → Azure App Service

## Labs in This Section

| Lab | Title | Difficulty |
|---|---|---|
| Lab-01 | App Service Plan & Web App | 🟢 |
| Lab-02 | Deployment Slots (Blue-Green) | 🟡 |
| Lab-03 | App Service — Custom Domains & SSL | 🟡 |
| Lab-04 | App Service — VNet Integration | 🔴 |

---

## Lab 01 — App Service: Deploy Web App

```bash
RG="rg-appservice-lab"
LOCATION="eastus"
APP_NAME="webapp-$(date +%s)"
PLAN_NAME="plan-webapp"

az group create --name $RG --location $LOCATION

# Create App Service Plan (defines compute resources)
# Like EC2 instance class for Elastic Beanstalk
az appservice plan create \
  --resource-group $RG \
  --name $PLAN_NAME \
  --location $LOCATION \
  --sku P1V3 \
  --is-linux \
  --number-of-workers 2

# SKUs:
# F1  — Free (no SLA, shared, 60 min/day compute)
# B1  — Basic (no auto-scale, 1 instance)
# S1  — Standard (auto-scale, custom domains, SSL)
# P1V3 — Premium V3 (faster, more RAM, AZ support)
# I1  — Isolated (ASE — dedicated hardware, VNet injection)

# Create Web App (Python)
az webapp create \
  --resource-group $RG \
  --plan $PLAN_NAME \
  --name $APP_NAME \
  --runtime "PYTHON:3.11" \
  --tags Environment=Lab

# Create Web App (Node.js)
az webapp create \
  --resource-group $RG \
  --plan $PLAN_NAME \
  --name "${APP_NAME}-node" \
  --runtime "NODE:20-lts"

# Create Web App (Docker container)
az webapp create \
  --resource-group $RG \
  --plan $PLAN_NAME \
  --name "${APP_NAME}-docker" \
  --deployment-container-image-name "nginx:alpine"

echo "✅ Web App URL: https://${APP_NAME}.azurewebsites.net"

# Configure app settings (environment variables)
az webapp config appsettings set \
  --resource-group $RG \
  --name $APP_NAME \
  --settings \
    ENVIRONMENT="production" \
    DATABASE_URL="postgresql://user:pass@server/db" \
    SECRET_KEY="my-secret-key" \
    DEBUG="false"

# View app settings
az webapp config appsettings list \
  --resource-group $RG \
  --name $APP_NAME \
  --output table

# Configure connection strings (separate from app settings for security)
az webapp config connection-string set \
  --resource-group $RG \
  --name $APP_NAME \
  --settings \
    DefaultConnection="Server=tcp:sqlsrv.database.windows.net;Database=mydb;..." \
  --connection-string-type SQLAzure
```

### Deploy Application Code

```bash
# Method 1: Deploy from local ZIP
zip -r app.zip . -x "*.pyc" "__pycache__/*" ".git/*"
az webapp deploy \
  --resource-group $RG \
  --name $APP_NAME \
  --src-path app.zip \
  --type zip

# Method 2: Deploy from GitHub (continuous deployment)
az webapp deployment source config \
  --resource-group $RG \
  --name $APP_NAME \
  --repo-url "https://github.com/YOUR_ORG/YOUR_REPO" \
  --branch main \
  --manual-integration

# Method 3: Deploy via Git push
DEPLOY_URL=$(az webapp deployment source config-local-git \
  --resource-group $RG \
  --name $APP_NAME \
  --query url \
  --output tsv)
echo "Git remote: $DEPLOY_URL"

git remote add azure $DEPLOY_URL
git push azure main:master

# Method 4: Deploy Docker image
az webapp config container set \
  --resource-group $RG \
  --name $APP_NAME \
  --docker-image-name "myacr.azurecr.io/myapp:latest" \
  --docker-registry-server-url "https://myacr.azurecr.io"

# Enable managed identity and grant ACR pull
az webapp identity assign --resource-group $RG --name $APP_NAME
IDENTITY_ID=$(az webapp identity show --resource-group $RG --name $APP_NAME --query principalId --output tsv)
az role assignment create --assignee $IDENTITY_ID --role AcrPull \
  --scope $(az acr show --name myacr --query id --output tsv)
az webapp config container set \
  --resource-group $RG \
  --name $APP_NAME \
  --docker-registry-server-url "https://myacr.azurecr.io" \
  --docker-registry-server-user "" \
  --docker-registry-server-password ""  # Use managed identity, no password needed
```

---

## Lab 02 — Deployment Slots (Blue-Green Deployments)

```bash
# Deployment slots = different environments on same App Service Plan
# Like Elastic Beanstalk environments with traffic splitting

# Create staging slot
az webapp deployment slot create \
  --resource-group $RG \
  --name $APP_NAME \
  --slot staging \
  --configuration-source $APP_NAME  # Copy settings from production

# Deploy to staging slot (not production!)
az webapp deploy \
  --resource-group $RG \
  --name $APP_NAME \
  --slot staging \
  --src-path new-version.zip \
  --type zip

# Staging URL (always separate from production):
echo "Staging: https://${APP_NAME}-staging.azurewebsites.net"
echo "Production: https://${APP_NAME}.azurewebsites.net"

# Test staging...
curl "https://${APP_NAME}-staging.azurewebsites.net/health"

# Traffic splitting (canary deployment — send 20% to new version)
az webapp traffic-routing set \
  --resource-group $RG \
  --name $APP_NAME \
  --distribution staging=20  # 20% to staging, 80% to production

# After validation: Full swap (instant, no downtime!)
az webapp deployment slot swap \
  --resource-group $RG \
  --name $APP_NAME \
  --slot staging \
  --target-slot production

echo "✅ Blue-green swap complete!"

# If issues: Swap back immediately (instant rollback)
az webapp deployment slot swap \
  --resource-group $RG \
  --name $APP_NAME \
  --slot production \
  --target-slot staging

echo "✅ Rollback complete!"

# Sticky settings (stay in slot, don't swap)
az webapp config appsettings set \
  --resource-group $RG \
  --name $APP_NAME \
  --slot-settings ENVIRONMENT=staging  # Sticky — stays "staging" even after swap
```

---

## Lab 03 — VNet Integration

```bash
# Connect App Service to VNet for accessing private resources
# Like VPC endpoint for Elastic Beanstalk

# Enable VNet integration
az webapp vnet-integration add \
  --resource-group $RG \
  --name $APP_NAME \
  --vnet vnet-hub \
  --subnet subnet-private

# List VNet integrations
az webapp vnet-integration list \
  --resource-group $RG \
  --name $APP_NAME \
  --output table

# Route ALL traffic through VNet (including internet traffic via firewall)
az webapp config appsettings set \
  --resource-group $RG \
  --name $APP_NAME \
  --settings WEBSITE_VNET_ROUTE_ALL=1

# Enable private endpoint for App Service (no public access)
APP_ID=$(az webapp show --resource-group $RG --name $APP_NAME --query id --output tsv)

az network private-endpoint create \
  --name "pe-webapp" \
  --resource-group $RG \
  --vnet-name vnet-hub \
  --subnet subnet-private \
  --private-connection-resource-id $APP_ID \
  --group-id sites \
  --connection-name "pe-webapp-connection"

# Disable public access (only accessible via private endpoint)
az webapp update \
  --resource-group $RG \
  --name $APP_NAME \
  --public-network-access Disabled

echo "✅ App Service now only accessible via private endpoint"
```

---

## Lab 04 — Auto-Scaling

```bash
# App Service auto-scale (scale out = add instances)
az monitor autoscale create \
  --resource-group $RG \
  --resource-type Microsoft.Web/serverFarms \
  --resource $PLAN_NAME \
  --name "autoscale-webapp" \
  --min-count 2 \
  --max-count 20 \
  --count 2

# Scale out: CPU > 70%
az monitor autoscale rule create \
  --resource-group $RG \
  --autoscale-name autoscale-webapp \
  --condition "CpuPercentage > 70 avg 5m" \
  --scale out 2 \
  --cooldown 10

# Scale in: CPU < 30%
az monitor autoscale rule create \
  --resource-group $RG \
  --autoscale-name autoscale-webapp \
  --condition "CpuPercentage < 30 avg 15m" \
  --scale in 1 \
  --cooldown 10

# Scale based on HTTP queue length
az monitor autoscale rule create \
  --resource-group $RG \
  --autoscale-name autoscale-webapp \
  --condition "HttpQueueLength > 100 avg 5m" \
  --scale out 4 \
  --cooldown 5
```

---

## Cleanup

```bash
az group delete --name rg-appservice-lab --yes --no-wait
```

## ✅ Lab Checklist

- [ ] Created App Service Plan (P1V3 Premium)
- [ ] Created Web Apps (Python, Node.js, Docker)
- [ ] Configured app settings and connection strings
- [ ] Deployed code via ZIP
- [ ] Deployed via GitHub continuous deployment
- [ ] Created staging deployment slot
- [ ] Performed traffic splitting (20/80)
- [ ] Performed blue-green slot swap
- [ ] Configured VNet integration
- [ ] Enabled private endpoint
- [ ] Set up auto-scaling rules
