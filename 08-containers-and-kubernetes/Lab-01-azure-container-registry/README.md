# 📦 Lab 01 — Azure Container Registry (ACR)

**Difficulty:** 🟢 Beginner  
**Time:** 45 minutes  
**Goal:** Set up ACR, push/pull images, configure security and geo-replication

---

## Part 1 — Create and Configure ACR

```bash
RG="rg-containers-lab"
LOCATION="eastus"
ACR_NAME="acrlab$(date +%s)"  # Globally unique, alphanumeric only

az group create --name $RG --location $LOCATION

# =========================================
# Create Azure Container Registry
# Tiers: Basic, Standard, Premium
# =========================================
az acr create \
  --resource-group $RG \
  --name $ACR_NAME \
  --sku Standard \
  --location $LOCATION \
  --admin-enabled false \
  --tags Environment=Lab

# SKU comparison:
# Basic:    5GB storage, no geo-replication, no private link
# Standard: 100GB storage, no geo-replication, webhooks  ← RECOMMENDED
# Premium:  500GB storage, geo-replication, private link, content trust

# Show ACR details
az acr show \
  --resource-group $RG \
  --name $ACR_NAME \
  --output json

# Get login server URL
ACR_LOGIN_SERVER=$(az acr show \
  --resource-group $RG \
  --name $ACR_NAME \
  --query loginServer \
  --output tsv)
echo "ACR Login Server: $ACR_LOGIN_SERVER"
```

---

## Part 2 — Push Images to ACR

```bash
# =========================================
# Method 1: Login and push with Docker
# =========================================

# Login to ACR (uses Azure AD credentials — no username/password needed!)
az acr login --name $ACR_NAME

# Create a sample Dockerfile
cat > Dockerfile << 'EOF'
FROM nginx:alpine
LABEL maintainer="devops@company.com"
LABEL version="1.0"

# Copy custom HTML
COPY index.html /usr/share/nginx/html/index.html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1
EOF

cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Azure Container Lab</title></head>
<body style="background:#0078D4;color:white;text-align:center;padding:50px;font-family:Arial">
  <h1>🐳 Running in Azure!</h1>
  <p>Container Registry: ACR</p>
  <p>Orchestrator: AKS</p>
</body>
</html>
EOF

# Build image locally
docker build -t myapp:v1.0 .

# Tag with ACR URL
docker tag myapp:v1.0 ${ACR_LOGIN_SERVER}/myapp:v1.0
docker tag myapp:v1.0 ${ACR_LOGIN_SERVER}/myapp:latest

# Push to ACR
docker push ${ACR_LOGIN_SERVER}/myapp:v1.0
docker push ${ACR_LOGIN_SERVER}/myapp:latest

echo "✅ Image pushed to ACR"

# =========================================
# Method 2: ACR Build Tasks (build in cloud — no local Docker needed)
# Like: docker build + push, but runs in Azure
# Equivalent to: CodeBuild + ECR push
# =========================================

# Quick build (from local context)
az acr build \
  --registry $ACR_NAME \
  --image "myapp:v2.0" \
  --file Dockerfile \
  .

# Build from GitHub
az acr build \
  --registry $ACR_NAME \
  --image "myapp-from-github:latest" \
  https://github.com/Azure-Samples/acr-build-helloworld-node.git

# Build multi-platform image
az acr build \
  --registry $ACR_NAME \
  --image "myapp:multiarch" \
  --platform linux/amd64 \
  .
```

---

## Part 3 — Manage Images in ACR

```bash
# List repositories
az acr repository list --name $ACR_NAME --output table

# List tags for a repository
az acr repository show-tags \
  --name $ACR_NAME \
  --repository myapp \
  --output table

# Show image manifest details
az acr repository show-manifests \
  --name $ACR_NAME \
  --repository myapp \
  --detail \
  --output table

# Show image details
az acr repository show \
  --name $ACR_NAME \
  --image myapp:v1.0 \
  --output json

# Delete a specific tag
az acr repository delete \
  --name $ACR_NAME \
  --image myapp:v2.0 \
  --yes

# Delete entire repository
az acr repository delete \
  --name $ACR_NAME \
  --repository myapp \
  --yes

# Run image from ACR (without Docker!)
az acr run \
  --registry $ACR_NAME \
  --cmd "${ACR_LOGIN_SERVER}/myapp:v1.0" \
  /dev/null
```

---

## Part 4 — ACR Tasks (Automated Builds)

```bash
# =========================================
# Create a scheduled task — rebuild image on schedule
# Like CodePipeline with ECR
# =========================================

# Task: Build on git commit
az acr task create \
  --registry $ACR_NAME \
  --name "build-on-commit" \
  --image "myapp:{{.Run.ID}}" \
  --context "https://github.com/YOUR_ORG/YOUR_REPO.git" \
  --branch main \
  --file Dockerfile \
  --git-access-token "GITHUB_PAT_TOKEN"

# Task: Build on base image update (OS patching automation!)
az acr task create \
  --registry $ACR_NAME \
  --name "build-on-base-update" \
  --image "myapp:{{.Run.ID}}" \
  --context "https://github.com/YOUR_ORG/YOUR_REPO.git" \
  --file Dockerfile

# Scheduled task (build every night at midnight)
az acr task create \
  --registry $ACR_NAME \
  --name "nightly-build" \
  --image "myapp:nightly-{{.Run.ID}}" \
  --schedule "0 0 * * *" \
  --context "https://github.com/YOUR_ORG/YOUR_REPO.git" \
  --file Dockerfile

# Run a task manually
az acr task run \
  --registry $ACR_NAME \
  --name "nightly-build"

# List tasks
az acr task list --registry $ACR_NAME --output table

# View task run history
az acr task list-runs --registry $ACR_NAME --output table

# View task run logs
RUN_ID=$(az acr task list-runs --registry $ACR_NAME --query "[0].runId" --output tsv)
az acr task logs --registry $ACR_NAME --run-id $RUN_ID
```

---

## Part 5 — ACR Security

```bash
# =========================================
# Grant AKS access to ACR (RBAC — no passwords!)
# Like IAM role for EKS to pull from ECR
# =========================================

# Attach ACR to AKS (simplest method)
# az aks update --resource-group $RG --name aks-lab --attach-acr $ACR_NAME

# Or manually assign AcrPull role
AKS_KUBELET_ID=$(az aks show \
  --resource-group $RG \
  --name aks-lab \
  --query "identityProfile.kubeletidentity.objectId" \
  --output tsv)

az role assignment create \
  --assignee $AKS_KUBELET_ID \
  --role "AcrPull" \
  --scope $(az acr show --name $ACR_NAME --query id --output tsv)

# Grant CI/CD service principal pull access
SP_APP_ID=$(az ad sp list --display-name "sp-github-actions" --query "[0].appId" --output tsv)

az role assignment create \
  --assignee $SP_APP_ID \
  --role "AcrPush" \
  --scope $(az acr show --name $ACR_NAME --query id --output tsv)

# =========================================
# Content Trust (Image signing — like Docker Notary)
# =========================================
az acr config content-trust update \
  --registry $ACR_NAME \
  --status enabled

# =========================================
# ACR with Private Endpoint
# =========================================
az network private-endpoint create \
  --name pe-acr \
  --resource-group $RG \
  --vnet-name vnet-lab \
  --subnet subnet-private \
  --private-connection-resource-id $(az acr show --name $ACR_NAME --query id --output tsv) \
  --group-id registry \
  --connection-name "pe-acr-connection"

# =========================================
# Vulnerability scanning (Microsoft Defender for Containers)
# =========================================
az security pricing create \
  --name Containers \
  --tier Standard

echo "✅ Defender for Containers enabled — images scanned on push"
```

---

## Part 6 — ACR Geo-Replication (Premium tier only)

```bash
# Upgrade to Premium for geo-replication
az acr update \
  --resource-group $RG \
  --name $ACR_NAME \
  --sku Premium

# Replicate to another region (images available worldwide with low latency)
az acr replication create \
  --registry $ACR_NAME \
  --location westus2

az acr replication create \
  --registry $ACR_NAME \
  --location northeurope

# List replications
az acr replication list \
  --registry $ACR_NAME \
  --output table

# Delete replication
az acr replication delete \
  --name northeurope \
  --registry $ACR_NAME
```

---

## Part 7 — Import Images from Docker Hub / Public Registries

```bash
# Import public image into ACR (air-gap scenario)
# Like copying from Docker Hub to ECR
az acr import \
  --name $ACR_NAME \
  --source docker.io/library/nginx:latest \
  --image nginx:latest

# Import from another ACR
az acr import \
  --name $ACR_NAME \
  --source source-registry.azurecr.io/myapp:latest \
  --image myapp:latest

# Import from GCR
az acr import \
  --name $ACR_NAME \
  --source gcr.io/google-containers/pause:3.1 \
  --image pause:3.1

# Import from ECR (public)
az acr import \
  --name $ACR_NAME \
  --source public.ecr.aws/nginx/nginx:latest \
  --image nginx-ecr:latest

# List all imported images
az acr repository list --name $ACR_NAME --output table
```

---

## Cleanup

```bash
az group delete --name rg-containers-lab --yes --no-wait
rm -f Dockerfile index.html
```

---

## ✅ Lab Checklist

- [ ] Created ACR with Standard SKU
- [ ] Logged in with `az acr login`
- [ ] Built and pushed image with Docker
- [ ] Used `az acr build` (cloud build)
- [ ] Listed and managed images/tags
- [ ] Created ACR build task
- [ ] Assigned AcrPull role to service principal
- [ ] Imported images from Docker Hub
- [ ] Set up geo-replication (Premium)
