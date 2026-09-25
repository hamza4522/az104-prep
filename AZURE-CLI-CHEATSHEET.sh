# ⚡ Azure CLI Complete Cheat Sheet
# For AWS/GCP/OCI Engineers transitioning to Azure

# =========================================
# AUTHENTICATION
# =========================================
az login                                          # Interactive browser login
az login --service-principal -u APP_ID -p SECRET --tenant TENANT_ID
az login --identity                               # Managed identity
az account show                                   # Current context (like aws sts get-caller-identity)
az account list --output table                    # List subscriptions
az account set --subscription "NAME_OR_ID"        # Switch subscription

# =========================================
# RESOURCE GROUPS
# =========================================
az group create --name RG_NAME --location eastus --tags env=dev
az group list --output table
az group show --name RG_NAME
az group delete --name RG_NAME --yes --no-wait
az group export --name RG_NAME > template.json   # Export as ARM template

# =========================================
# VIRTUAL MACHINES
# =========================================
az vm create --resource-group RG --name VM_NAME --image Ubuntu2204 \
  --size Standard_D2s_v3 --admin-username azureuser --generate-ssh-keys \
  --assign-identity                               # Enable managed identity

az vm list --output table
az vm show --resource-group RG --name VM_NAME --show-details
az vm start/stop/restart/deallocate --resource-group RG --name VM_NAME
az vm resize --resource-group RG --name VM_NAME --size Standard_D4s_v3
az vm run-command invoke --resource-group RG --name VM_NAME \
  --command-id RunShellScript --scripts "echo hello"

# VM Images
az vm image list --output table                  # Popular images
az vm image list --all --publisher Canonical     # All Ubuntu
az vm list-sizes --location eastus --output table

# =========================================
# NETWORKING
# =========================================
# VNet
az network vnet create --resource-group RG --name VNET --address-prefixes 10.0.0.0/16
az network vnet subnet create --resource-group RG --vnet-name VNET --name SUBNET --address-prefixes 10.0.1.0/24
az network vnet list --output table
az network vnet peering create --resource-group RG --name PEER --vnet-name VNET1 --remote-vnet VNET2 --allow-vnet-access

# NSG
az network nsg create --resource-group RG --name NSG_NAME
az network nsg rule create --resource-group RG --nsg-name NSG --name RULE \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes '*' --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges 80
az network vnet subnet update --resource-group RG --vnet-name VNET --name SUBNET --network-security-group NSG

# Public IP
az network public-ip create --resource-group RG --name PIP --sku Standard --allocation-method Static

# NAT Gateway
az network nat gateway create --resource-group RG --name NATGW --public-ip-addresses PIP

# Load Balancer
az network lb create --resource-group RG --name LB --sku Standard --public-ip-address PIP

# DNS
az network dns zone create --resource-group RG --name domain.com
az network dns record-set a add-record --resource-group RG --zone-name domain.com --record-set-name www --ipv4-address 1.2.3.4
az network private-dns zone create --resource-group RG --name private.local

# =========================================
# STORAGE
# =========================================
az storage account create --resource-group RG --name SA_NAME --sku Standard_LRS \
  --kind StorageV2 --https-only true --min-tls-version TLS1_2
az storage account keys list --resource-group RG --account-name SA_NAME

# Blobs
az storage container create --account-name SA --name CONTAINER
az storage blob upload --account-name SA --container-name C --name BLOB --file FILE
az storage blob download --account-name SA --container-name C --name BLOB --file FILE
az storage blob list --account-name SA --container-name C --output table
az storage blob delete --account-name SA --container-name C --name BLOB

# SAS Token
az storage blob generate-sas --account-name SA --container-name C --name BLOB \
  --permissions r --expiry 2024-12-31T00:00Z --output tsv

# =========================================
# IDENTITY & ACCESS
# =========================================
# Azure AD Users
az ad user create --display-name "Name" --user-principal-name user@domain.com --password Pass
az ad user list --output table
az ad user show --id user@domain.com
az ad user delete --id user@domain.com

# Azure AD Groups
az ad group create --display-name "Group Name" --mail-nickname "groupname"
az ad group member add --group GROUP_NAME --member-id USER_OBJECT_ID
az ad group member list --group GROUP_NAME --output table

# Service Principals
az ad sp create-for-rbac --name SP_NAME --role Contributor \
  --scopes /subscriptions/SUB_ID --sdk-auth
az ad sp list --display-name SP_NAME --output table

# RBAC
az role assignment create --assignee USER_OR_SP --role "Contributor" --scope /subscriptions/SUB
az role assignment list --resource-group RG --output table
az role definition list --query "[?contains(roleName,'Storage')].{Name:roleName}" --output table
az role definition create --role-definition custom-role.json

# Managed Identity
az vm identity assign --resource-group RG --name VM_NAME
az identity create --resource-group RG --name MI_NAME  # User-assigned

# =========================================
# KEY VAULT
# =========================================
az keyvault create --resource-group RG --name KV_NAME --enable-rbac-authorization true
az keyvault secret set --vault-name KV --name SECRET_NAME --value "VALUE"
az keyvault secret show --vault-name KV --name SECRET_NAME --query value --output tsv
az keyvault secret list --vault-name KV --output table
az keyvault key create --vault-name KV --name KEY_NAME --kty RSA --size 2048
az keyvault certificate create --vault-name KV --name CERT_NAME --policy @policy.json

# =========================================
# DATABASES
# =========================================
# SQL Server & Database
az sql server create --resource-group RG --name SQL_SERVER --location eastus \
  --admin-user sqladmin --admin-password Password123!
az sql db create --resource-group RG --server SQL_SERVER --name DB_NAME \
  --edition GeneralPurpose --family Gen5 --capacity 2 --compute-model Serverless
az sql server firewall-rule create --resource-group RG --server SQL_SERVER \
  --name AllowMyIP --start-ip-address 1.2.3.4 --end-ip-address 1.2.3.4

# PostgreSQL
az postgres flexible-server create --resource-group RG --name PG_SERVER \
  --location eastus --admin-user pgadmin --admin-password Password123! \
  --sku-name Standard_D2ds_v4 --tier GeneralPurpose

# =========================================
# CONTAINERS & AKS
# =========================================
# ACR
az acr create --resource-group RG --name ACR_NAME --sku Standard
az acr login --name ACR_NAME
az acr build --registry ACR_NAME --image myapp:latest .
az acr repository list --name ACR_NAME --output table

# AKS
az aks create --resource-group RG --name AKS_NAME \
  --node-count 3 --node-vm-size Standard_D4s_v3 \
  --enable-managed-identity --enable-cluster-autoscaler \
  --min-count 2 --max-count 10 --attach-acr ACR_NAME
az aks get-credentials --resource-group RG --name AKS_NAME   # Like: aws eks update-kubeconfig
az aks nodepool add --resource-group RG --cluster-name AKS --name POOL --node-count 2
az aks upgrade --resource-group RG --name AKS --kubernetes-version 1.29.2

# =========================================
# APP SERVICE
# =========================================
az appservice plan create --resource-group RG --name PLAN --sku P1V3 --is-linux
az webapp create --resource-group RG --plan PLAN --name APP_NAME --runtime "PYTHON:3.11"
az webapp config appsettings set --resource-group RG --name APP --settings KEY=VALUE
az webapp deploy --resource-group RG --name APP --src-path app.zip --type zip
az webapp deployment slot create --resource-group RG --name APP --slot staging
az webapp deployment slot swap --resource-group RG --name APP --slot staging

# =========================================
# FUNCTIONS
# =========================================
az functionapp create --resource-group RG --name FUNC_NAME \
  --storage-account SA --consumption-plan-location eastus \
  --runtime python --runtime-version 3.11 --functions-version 4 --os-type linux
az functionapp config appsettings set --resource-group RG --name FUNC --settings KEY=VALUE
func azure functionapp publish FUNC_NAME                      # Deploy with Core Tools

# =========================================
# MONITORING
# =========================================
az monitor log-analytics workspace create --resource-group RG --workspace-name LAW_NAME
az monitor metrics alert create --resource-group RG --name ALERT_NAME \
  --scopes RESOURCE_ID --condition "avg Percentage CPU > 80" \
  --window-size 5m --evaluation-frequency 1m --severity 2
az monitor action-group create --resource-group RG --name AG_NAME \
  --short-name ag --action email admin admin@company.com
az monitor diagnostic-settings create --name DIAG --resource RESOURCE_ID \
  --workspace LAW_ID --logs '[{"category":"All","enabled":true}]'

# =========================================
# POLICY
# =========================================
az policy definition list --output table
az policy assignment create --name ASSIGNMENT --policy POLICY_ID \
  --scope /subscriptions/SUB_ID
az policy state list --resource-group RG --output table
az policy state summarize --resource-group RG

# =========================================
# BICEP / ARM
# =========================================
az bicep install && az bicep version
az bicep build --file main.bicep
az bicep decompile --file template.json
az deployment group create --resource-group RG --template-file main.bicep \
  --parameters @params.json
az deployment group what-if --resource-group RG --template-file main.bicep   # Like: terraform plan

# =========================================
# USEFUL OUTPUT TRICKS
# =========================================
az vm list --output table                         # Human readable table
az vm list --output json                          # Full JSON
az vm list --output yaml                          # YAML
az vm list --output tsv                           # Tab-separated (for scripting)
az vm list --query "[].{Name:name,RG:resourceGroup,Size:hardwareProfile.vmSize}" --output table
az vm list --query "[?powerState=='VM running'].name" --output tsv

# Get ID of a resource
az vm show --resource-group RG --name VM --query id --output tsv

# Count resources
az resource list --query "length(@)"

# =========================================
# AWS → AZURE COMMAND MAPPING
# =========================================
# aws configure              → az login / az account set
# aws ec2 describe-instances → az vm list
# aws s3 ls                  → az storage blob list
# aws s3 cp                  → az storage blob upload/download
# aws s3 sync                → azcopy sync
# aws eks update-kubeconfig  → az aks get-credentials
# aws iam create-user        → az ad user create
# aws iam create-role        → az ad sp create-for-rbac
# aws cloudwatch put-metric-alarm → az monitor metrics alert create
# aws kms create-key         → az keyvault key create
# aws secretsmanager create-secret → az keyvault secret set
# aws rds create-db-instance → az sql db create
# aws ecr create-repository  → az acr create
# aws lambda create-function → az functionapp create
# aws cloudformation deploy  → az deployment group create
# terraform plan             → az deployment group what-if / bicep what-if
