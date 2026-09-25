# 🚀 Lab 01 — Azure DevOps: Organization Setup & First Pipeline

**Difficulty:** 🟢 Beginner  
**Time:** 60 minutes  
**Goal:** Set up Azure DevOps, create a project, and build your first CI/CD pipeline

---

## Part 1 — Azure DevOps Setup

```bash
# Install Azure DevOps CLI extension
az extension add --name azure-devops

# Login
az login
az devops configure --defaults organization="https://dev.azure.com/YOUR_ORG"

# Create a project
az devops project create \
  --name "azure-labs-cicd" \
  --description "Azure CI/CD learning project" \
  --visibility private \
  --process Agile

# List projects
az devops project list --output table

# Get project details
az devops project show --project "azure-labs-cicd" --output json
```

---

## Part 2 — Azure Repos (Git)

```bash
# List repositories
az repos list --project "azure-labs-cicd" --output table

# Create a new repository
az repos create \
  --name "webapp-api" \
  --project "azure-labs-cicd"

# Get repository clone URL
az repos show --repository "webapp-api" --project "azure-labs-cicd" \
  --query remoteUrl --output tsv

# Clone the repo
git clone $(az repos show --repository "webapp-api" \
  --project "azure-labs-cicd" \
  --query remoteUrl --output tsv) webapp-api

cd webapp-api

# Initialize with sample app
cat > app.py << 'EOF'
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        "message": "Hello from Azure DevOps CI/CD!",
        "version": os.environ.get("APP_VERSION", "1.0.0"),
        "environment": os.environ.get("ENVIRONMENT", "development")
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "webapp-api"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
EOF

cat > requirements.txt << 'EOF'
flask==3.0.0
pytest==7.4.0
pytest-cov==4.1.0
gunicorn==21.2.0
EOF

cat > test_app.py << 'EOF'
import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_endpoint(client):
    response = client.get('/')
    assert response.status_code == 200
    data = response.get_json()
    assert 'message' in data

def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'
EOF

cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app
COPY . .

# Non-root user (security best practice)
RUN useradd -m -r appuser && chown -R appuser /app
USER appuser

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "4", "app:app"]
EOF

# Push to Azure Repos
git add .
git commit -m "Initial app commit"
git push origin main
```

---

## Part 3 — CI Pipeline (Build & Test)

```yaml
# azure-pipelines.yml — Save this to root of repo
trigger:
  branches:
    include:
      - main
      - feature/*
  paths:
    exclude:
      - README.md
      - docs/*

pr:
  branches:
    include:
      - main

variables:
  # Azure Container Registry
  ACR_NAME: 'acrlab$(Build.BuildId)'
  IMAGE_NAME: 'webapp-api'
  IMAGE_TAG: '$(Build.BuildId)'
  PYTHON_VERSION: '3.11'

pool:
  vmImage: 'ubuntu-latest'

stages:
# =========================================
# STAGE 1: BUILD & TEST
# =========================================
- stage: BuildAndTest
  displayName: 'Build and Test'
  jobs:
  
  - job: Lint
    displayName: 'Code Quality Check'
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '$(PYTHON_VERSION)'
    
    - script: |
        pip install flake8 black isort bandit
        
        echo "=== Running flake8 (style check) ==="
        flake8 . --max-line-length=120 --exclude=.venv,__pycache__
        
        echo "=== Running black (format check) ==="
        black --check .
        
        echo "=== Running bandit (security check) ==="
        bandit -r . -ll
        
        echo "✅ Code quality checks passed!"
      displayName: 'Run linters'
  
  - job: UnitTests
    displayName: 'Unit Tests'
    dependsOn: Lint
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '$(PYTHON_VERSION)'
    
    - script: |
        pip install -r requirements.txt
        
        echo "=== Running Unit Tests ==="
        pytest test_app.py \
          --cov=app \
          --cov-report=xml:coverage.xml \
          --cov-report=html:htmlcov \
          --junitxml=test-results.xml \
          --cov-fail-under=80 \
          -v
      displayName: 'Run unit tests'
    
    - task: PublishTestResults@2
      condition: always()
      inputs:
        testResultsFormat: 'JUnit'
        testResultsFiles: 'test-results.xml'
        testRunTitle: 'Python Unit Tests'
    
    - task: PublishCodeCoverageResults@1
      condition: always()
      inputs:
        codeCoverageTool: 'Cobertura'
        summaryFileLocation: 'coverage.xml'

# =========================================
# STAGE 2: BUILD DOCKER IMAGE
# =========================================
- stage: BuildImage
  displayName: 'Build Docker Image'
  dependsOn: BuildAndTest
  condition: succeeded()
  jobs:
  
  - job: Docker
    displayName: 'Build and Push to ACR'
    steps:
    - task: AzureCLI@2
      displayName: 'Build and push to ACR'
      inputs:
        azureSubscription: 'azure-service-connection'  # Configure in Project Settings
        scriptType: bash
        scriptLocation: inlineScript
        inlineScript: |
          # Build in cloud using ACR Tasks (no Docker daemon needed!)
          az acr build \
            --registry $(ACR_NAME) \
            --image $(IMAGE_NAME):$(IMAGE_TAG) \
            --image $(IMAGE_NAME):latest \
            --file Dockerfile \
            .
          
          echo "##vso[task.setvariable variable=IMAGE_URI;isOutput=true]$(ACR_NAME).azurecr.io/$(IMAGE_NAME):$(IMAGE_TAG)"
          echo "✅ Image pushed: $(ACR_NAME).azurecr.io/$(IMAGE_NAME):$(IMAGE_TAG)"
    
    - script: |
        # Security scan with Trivy
        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
          aquasec/trivy image \
          --severity HIGH,CRITICAL \
          --exit-code 1 \
          $(ACR_NAME).azurecr.io/$(IMAGE_NAME):$(IMAGE_TAG)
      displayName: 'Security scan (Trivy)'
      continueOnError: true  # Don't fail pipeline on scan findings (report only)

# =========================================
# STAGE 3: DEPLOY TO STAGING
# =========================================
- stage: DeployStaging
  displayName: 'Deploy to Staging'
  dependsOn: BuildImage
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  
  - deployment: DeployToStaging
    displayName: 'Deploy to Staging AKS'
    environment: 'staging'  # Defines approval gates
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureCLI@2
            displayName: 'Deploy to AKS Staging'
            inputs:
              azureSubscription: 'azure-service-connection'
              scriptType: bash
              scriptLocation: inlineScript
              inlineScript: |
                # Get AKS credentials
                az aks get-credentials \
                  --resource-group rg-aks-staging \
                  --name aks-staging \
                  --overwrite-existing
                
                # Deploy using helm
                helm upgrade --install webapp-api ./charts/webapp-api \
                  --namespace staging \
                  --create-namespace \
                  --set image.repository=$(ACR_NAME).azurecr.io/$(IMAGE_NAME) \
                  --set image.tag=$(Build.BuildId) \
                  --set environment=staging \
                  --set replicaCount=2 \
                  --wait \
                  --timeout 5m0s
                
                # Wait for rollout
                kubectl rollout status deployment/webapp-api -n staging
                
                echo "✅ Deployed to staging!"

# =========================================
# STAGE 4: DEPLOY TO PRODUCTION (with manual approval)
# =========================================
- stage: DeployProduction
  displayName: 'Deploy to Production'
  dependsOn: DeployStaging
  condition: succeeded()
  jobs:
  
  - deployment: DeployToProduction
    displayName: 'Deploy to Production AKS'
    environment: 'production'  # Requires manual approval in Azure DevOps UI
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureCLI@2
            displayName: 'Deploy to AKS Production'
            inputs:
              azureSubscription: 'azure-service-connection'
              scriptType: bash
              scriptLocation: inlineScript
              inlineScript: |
                az aks get-credentials \
                  --resource-group rg-aks-prod \
                  --name aks-prod \
                  --overwrite-existing
                
                # Blue-green deployment
                helm upgrade --install webapp-api ./charts/webapp-api \
                  --namespace production \
                  --create-namespace \
                  --set image.repository=$(ACR_NAME).azurecr.io/$(IMAGE_NAME) \
                  --set image.tag=$(Build.BuildId) \
                  --set environment=production \
                  --set replicaCount=5 \
                  --wait \
                  --timeout 10m0s
                
                kubectl rollout status deployment/webapp-api -n production
                
                # Verify deployment
                APP_URL=$(kubectl get svc webapp-api -n production \
                  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
                
                curl -f http://$APP_URL/health || exit 1
                
                echo "✅ Production deployment successful!"
                echo "App URL: http://$APP_URL"
```

---

## Part 4 — Configure Service Connection

```bash
# Create service connection (Azure DevOps → Azure subscription)
# This is like setting up AWS CLI credentials in CodeBuild

# Via CLI:
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
SUBSCRIPTION_NAME=$(az account show --query name --output tsv)
TENANT_ID=$(az account show --query tenantId --output tsv)

# Create service principal for the pipeline
az ad sp create-for-rbac \
  --name "sp-azure-devops-$(date +%s)" \
  --role Contributor \
  --scopes "/subscriptions/${SUBSCRIPTION_ID}" \
  --sdk-auth

# Output: clientId, clientSecret, subscriptionId, tenantId
# Add these in Azure DevOps:
# Project Settings → Service Connections → New → Azure Resource Manager → Service Principal (manual)

# Or create via Azure DevOps CLI:
az devops service-endpoint azurerm create \
  --azure-rm-service-principal-id "CLIENT_ID" \
  --azure-rm-subscription-id $SUBSCRIPTION_ID \
  --azure-rm-subscription-name "$SUBSCRIPTION_NAME" \
  --azure-rm-tenant-id $TENANT_ID \
  --name "azure-service-connection" \
  --project "azure-labs-cicd"
```

---

## Part 5 — Variable Groups & Secrets

```bash
# Create variable group (like AWS CodePipeline parameter store integration)
az pipelines variable-group create \
  --name "global-config" \
  --variables \
    ACR_NAME="myacrlab" \
    AKS_RESOURCE_GROUP="rg-aks-prod" \
    AKS_CLUSTER_NAME="aks-prod-eastus" \
  --project "azure-labs-cicd"

# Add secret variable (masked in logs)
az pipelines variable-group variable create \
  --group-id 1 \
  --name "DB_PASSWORD" \
  --value "SuperSecret123!" \
  --secret true \
  --project "azure-labs-cicd"

# Link Key Vault to variable group (preferred — no secrets in DevOps at all)
az pipelines variable-group create \
  --name "keyvault-secrets" \
  --authorize true \
  --variables-from-keyvault \
    --key-vault "kv-devops" \
    --secrets "DB-PASSWORD,API-KEY,ACR-PASSWORD" \
  --project "azure-labs-cicd" \
  --service-endpoint "azure-service-connection"
```

---

## Part 6 — Pipeline Triggers & Schedules

```yaml
# azure-pipelines-scheduled.yml
schedules:
- cron: "0 2 * * *"           # 2 AM UTC every day
  displayName: Nightly Build
  branches:
    include:
    - main
  always: true                  # Run even if no code changes

- cron: "0 0 * * 0"           # Sunday midnight
  displayName: Weekly Full Test
  branches:
    include:
    - main

# Build Completion trigger (trigger B when pipeline A completes)
resources:
  pipelines:
  - pipeline: upstream-pipeline
    source: 'infrastructure-pipeline'
    trigger:
      branches:
        include:
        - main

trigger:
  batch: true                   # Queue runs instead of running in parallel
  branches:
    include:
    - main
    - release/*
  tags:
    include:
    - v*.*.*                    # Trigger on semantic version tags
```

---

## ✅ Lab Checklist

- [ ] Set up Azure DevOps organization and project
- [ ] Created Azure Repos repository
- [ ] Pushed sample Python Flask app
- [ ] Created `azure-pipelines.yml`
- [ ] Configured service connection to Azure subscription
- [ ] Ran CI pipeline (lint + test + coverage)
- [ ] Built Docker image with ACR Tasks
- [ ] Set up staging and production environments with approvals
- [ ] Created variable groups and linked Key Vault secrets
- [ ] Configured scheduled pipeline triggers
