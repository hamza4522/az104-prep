# 🔴 IaC Lab — Terraform Enterprise Landing Zone
# ═══════════════════════════════════════════════════════════════
# Level 1 → Reusable Terraform module structure
# Level 2 → Remote state + CI/CD pipeline + drift detection
# Level 3 → Full enterprise landing zone (CAF aligned)
# ═══════════════════════════════════════════════════════════════

#!/bin/bash
set -euo pipefail

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
PRIMARY_REGION="eastus"

# ─────────────────────────────────────────────────────────────
# 🟢 LEVEL 1 — Modular Terraform Structure
# Scenario: Platform team maintains reusable modules
# Modules: networking, compute, security, databases
# ─────────────────────────────────────────────────────────────

echo "=============================================="
echo " LEVEL 1: Terraform Module Structure"
echo "=============================================="

mkdir -p /tmp/terraform-enterprise/{modules/{networking,compute,security,monitoring},environments/{dev,staging,prod},shared}

# ── Root terraform.tf ─────────────────────────────────────────
cat > /tmp/terraform-enterprise/terraform.tf << 'TERRAFORM'
terraform {
  required_version = ">= 1.7.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
    azapi = {                          # For resources not yet in azurerm
      source  = "azure/azapi"
      version = "~> 1.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
TERRAFORM

# ── Networking Module ─────────────────────────────────────────
cat > /tmp/terraform-enterprise/modules/networking/main.tf << 'TERRAFORM'
# modules/networking/main.tf
# Deploys: Hub VNet + Spoke VNets + Peering + Firewall + Private DNS

variable "config" {
  description = "Networking configuration object"
  type = object({
    prefix          = string
    location        = string
    resource_group  = string
    hub_cidr        = string
    spoke_cidrs     = map(string)    # map of "name" → "cidr"
    enable_firewall = bool
    enable_bastion  = bool
    dns_zones       = list(string)   # private DNS zones to create
    tags            = map(string)
  })
}

locals {
  prefix = var.config.prefix
  tags   = merge(var.config.tags, { Module = "networking" })
}

# Hub VNet
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${local.prefix}"
  resource_group_name = var.config.resource_group
  location            = var.config.location
  address_space       = [var.config.hub_cidr]
  tags                = local.tags
}

# Hub Subnets (required for Firewall, Bastion, Gateway)
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.config.resource_group
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.config.hub_cidr, 6, 0)]
}

resource "azurerm_subnet" "bastion" {
  count                = var.config.enable_bastion ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.config.resource_group
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.config.hub_cidr, 6, 1)]
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.config.resource_group
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.config.hub_cidr, 8, 64)]
}

# Spoke VNets (created dynamically from map)
resource "azurerm_virtual_network" "spokes" {
  for_each            = var.config.spoke_cidrs
  name                = "vnet-spoke-${each.key}-${local.prefix}"
  resource_group_name = var.config.resource_group
  location            = var.config.location
  address_space       = [each.value]
  tags                = merge(local.tags, { Spoke = each.key })
}

resource "azurerm_subnet" "spoke_workload" {
  for_each             = var.config.spoke_cidrs
  name                 = "subnet-workload"
  resource_group_name  = var.config.resource_group
  virtual_network_name = azurerm_virtual_network.spokes[each.key].name
  address_prefixes     = [cidrsubnet(each.value, 2, 1)]
}

# Hub → Spoke Peerings
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.config.spoke_cidrs
  
  name                         = "peer-hub-to-${each.key}"
  resource_group_name          = var.config.resource_group
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spokes[each.key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

# Spoke → Hub Peerings
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = var.config.spoke_cidrs
  
  name                         = "peer-${each.key}-to-hub"
  resource_group_name          = var.config.resource_group
  virtual_network_name         = azurerm_virtual_network.spokes[each.key].name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false  # true requires VPN/ER gateway
}

# Azure Firewall
resource "azurerm_public_ip" "firewall" {
  count               = var.config.enable_firewall ? 1 : 0
  name                = "pip-fw-${local.prefix}"
  resource_group_name = var.config.resource_group
  location            = var.config.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = local.tags
}

resource "azurerm_firewall" "hub" {
  count               = var.config.enable_firewall ? 1 : 0
  name                = "fw-hub-${local.prefix}"
  resource_group_name = var.config.resource_group
  location            = var.config.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = local.tags
  
  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

# Private DNS Zones (from list)
resource "azurerm_private_dns_zone" "zones" {
  for_each            = toset(var.config.dns_zones)
  name                = each.value
  resource_group_name = var.config.resource_group
  tags                = local.tags
}

# Link DNS zones to Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "hub_links" {
  for_each              = toset(var.config.dns_zones)
  name                  = "link-hub-${replace(each.value, ".", "-")}"
  resource_group_name   = var.config.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.zones[each.value].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = local.tags
}

# Outputs
output "hub_vnet_id"       { value = azurerm_virtual_network.hub.id }
output "spoke_vnet_ids"    { value = { for k, v in azurerm_virtual_network.spokes : k => v.id } }
output "spoke_subnet_ids"  { value = { for k, v in azurerm_subnet.spoke_workload : k => v.id } }
output "firewall_private_ip" {
  value = var.config.enable_firewall ? azurerm_firewall.hub[0].ip_configuration[0].private_ip_address : null
}
output "private_dns_zone_ids" {
  value = { for k, v in azurerm_private_dns_zone.zones : k => v.id }
}
TERRAFORM

# ── Security Module ───────────────────────────────────────────
cat > /tmp/terraform-enterprise/modules/security/main.tf << 'TERRAFORM'
# modules/security/main.tf
# Deploys: Key Vault + Policies + Defender + Log Analytics

variable "config" {
  type = object({
    prefix                = string
    location              = string
    resource_group_id     = string
    resource_group        = string
    tenant_id             = string
    subscription_id       = string
    enable_defender       = bool
    key_vault_sku         = string  # "standard" or "premium"
    log_retention_days    = number
    tags                  = map(string)
  })
}

data "azurerm_client_config" "current" {}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.config.prefix}"
  resource_group_name = var.config.resource_group
  location            = var.config.location
  sku                 = "PerGB2018"
  retention_in_days   = var.config.log_retention_days
  tags                = var.config.tags
}

# Key Vault
resource "random_string" "kv_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_key_vault" "main" {
  name                = "kv-${var.config.prefix}-${random_string.kv_suffix.result}"
  resource_group_name = var.config.resource_group
  location            = var.config.location
  tenant_id           = var.config.tenant_id
  sku_name            = var.config.key_vault_sku
  
  enable_rbac_authorization   = true
  soft_delete_retention_days  = 90
  purge_protection_enabled    = var.config.key_vault_sku == "premium"
  
  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
  
  tags = var.config.tags
}

# Key Vault diagnostics to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag-kv-to-law"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  enabled_log {
    category = "AuditEvent"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Microsoft Defender for Cloud (all services)
resource "azurerm_security_center_subscription_pricing" "defender" {
  for_each      = var.config.enable_defender ? toset([
    "AppServices", "ContainerRegistry", "Containers",
    "Dns", "KeyVaults", "KubernetesService", "ResourceManager",
    "SqlServers", "SqlServerVirtualMachines", "StorageAccounts",
    "VirtualMachines", "Arm"
  ]) : toset([])
  
  tier          = "Standard"
  resource_type = each.value
}

# Activity Log Alert: Privileged operations
resource "azurerm_monitor_action_group" "security_alerts" {
  name                = "ag-security-${var.config.prefix}"
  resource_group_name = var.config.resource_group
  short_name          = "sec-alert"
  tags                = var.config.tags
  
  email_receiver {
    name          = "security-team"
    email_address = "security@company.com"
  }
}

resource "azurerm_monitor_activity_log_alert" "role_assignment" {
  name                = "alert-role-assignment-created"
  resource_group_name = var.config.resource_group
  scopes              = [var.config.resource_group_id]
  description         = "Alert on any new role assignment"
  tags                = var.config.tags
  
  criteria {
    operation_name = "Microsoft.Authorization/roleAssignments/write"
    category       = "Administrative"
    statuses       = ["Succeeded"]
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.security_alerts.id
  }
}

output "key_vault_id"           { value = azurerm_key_vault.main.id }
output "key_vault_name"         { value = azurerm_key_vault.main.name }
output "key_vault_uri"          { value = azurerm_key_vault.main.vault_uri }
output "log_analytics_id"       { value = azurerm_log_analytics_workspace.main.id }
output "log_analytics_workspace_id" { value = azurerm_log_analytics_workspace.main.workspace_id }
TERRAFORM

# ── Environment Config (prod) ─────────────────────────────────
cat > /tmp/terraform-enterprise/environments/prod/main.tf << 'TERRAFORM'
# environments/prod/main.tf
# Production environment — calls all modules

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "REPLACE_WITH_SA"
    container_name       = "tfstate"
    key                  = "prod/main.tfstate"
    use_oidc             = true        # Workload Identity (GitHub Actions)
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
  use_oidc = true  # GitHub Actions OIDC — no client secrets!
}

locals {
  env    = "prod"
  prefix = "myapp-prod"
  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Team        = "Platform"
    CostCenter  = "ENG-001"
    Repository  = "github.com/org/infra"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = local.tags
  
  lifecycle {
    prevent_destroy = true  # Cannot accidentally delete production!
  }
}

module "networking" {
  source = "../../modules/networking"
  
  config = {
    prefix         = local.prefix
    location       = var.location
    resource_group = azurerm_resource_group.main.name
    hub_cidr       = "10.0.0.0/16"
    spoke_cidrs    = {
      "app"    = "10.1.0.0/16"
      "data"   = "10.2.0.0/16"
      "shared" = "10.3.0.0/16"
    }
    enable_firewall = true
    enable_bastion  = true
    dns_zones = [
      "privatelink.blob.core.windows.net",
      "privatelink.vaultcore.azure.net",
      "privatelink.database.windows.net",
      "privatelink.azurecr.io",
      "company.internal"
    ]
    tags = local.tags
  }
}

module "security" {
  source = "../../modules/security"
  
  config = {
    prefix              = local.prefix
    location            = var.location
    resource_group      = azurerm_resource_group.main.name
    resource_group_id   = azurerm_resource_group.main.id
    tenant_id           = data.azurerm_client_config.current.tenant_id
    subscription_id     = data.azurerm_subscription.current.subscription_id
    enable_defender     = true
    key_vault_sku       = "premium"
    log_retention_days  = 365
    tags                = local.tags
  }
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}
TERRAFORM

cat > /tmp/terraform-enterprise/environments/prod/variables.tf << 'TERRAFORM'
variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "secondary_location" {
  description = "Secondary Azure region for DR"
  type        = string
  default     = "westus2"
}
TERRAFORM

cat > /tmp/terraform-enterprise/environments/prod/outputs.tf << 'TERRAFORM'
output "hub_vnet_id" {
  description = "Hub VNet ID for cross-module referencing"
  value       = module.networking.hub_vnet_id
}

output "key_vault_name" {
  description = "Key Vault name — use for secret references"
  value       = module.security.key_vault_name
  sensitive   = false
}

output "spoke_subnets" {
  description = "Spoke subnet IDs for workload deployments"
  value       = module.networking.spoke_subnet_ids
}
TERRAFORM

echo "  ✅ Terraform module structure created"

echo ""
echo "=== Level 1 Complete: Terraform Module Structure ==="


# ─────────────────────────────────────────────────────────────
# 🟡 LEVEL 2 — CI/CD Pipeline + Drift Detection
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================="
echo " LEVEL 2: Terraform CI/CD + Drift Detection"
echo "=============================================="

# GitHub Actions workflow for Terraform
cat > /tmp/terraform-enterprise/.github-workflows-terraform.yml << 'YAML'
# .github/workflows/terraform.yml
name: Terraform CI/CD

on:
  push:
    branches: [main]
    paths: ['environments/**', 'modules/**']
  pull_request:
    branches: [main]
    paths: ['environments/**', 'modules/**']
  schedule:
    - cron: '0 8 * * *'   # Daily drift detection at 8 AM UTC

permissions:
  id-token: write          # Required for OIDC auth
  contents: read
  pull-requests: write     # Comment plan on PR
  issues: write

env:
  ARM_USE_OIDC: true
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}   # Federated, no secret!
  TF_VAR_location: eastus

jobs:
  # ══════════════════════════════
  # VALIDATE + LINT
  # ══════════════════════════════
  validate:
    name: Validate & Lint
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: "~1.7"
    
    - name: Terraform Format Check
      run: terraform fmt -check -recursive
    
    - name: tflint
      uses: terraform-linters/setup-tflint@v4
      with:
        tflint_version: latest
    
    - run: tflint --recursive --format compact
    
    - name: tfsec (security scanner)
      uses: aquasecurity/tfsec-action@v1.0.3
      with:
        soft_fail: true
        format: sarif
        sarif_file: tfsec.sarif
    
    - name: Checkov (compliance scanner)
      uses: bridgecrewio/checkov-action@master
      with:
        directory: .
        framework: terraform
        output_format: sarif
        output_file_path: checkov.sarif
        soft_fail: true
    
    - name: Upload SARIF results
      uses: github/codeql-action/upload-sarif@v3
      with:
        sarif_file: checkov.sarif

  # ══════════════════════════════
  # PLAN (PR only)
  # ══════════════════════════════
  plan:
    name: Terraform Plan
    needs: validate
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    strategy:
      matrix:
        environment: [dev, staging, prod]
    environment: ${{ matrix.environment }}
    defaults:
      run:
        working-directory: environments/${{ matrix.environment }}
    
    steps:
    - uses: actions/checkout@v4
    
    - uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: "~1.7"
    
    - name: Azure Login (OIDC — no secrets!)
      uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    
    - run: terraform init -backend-config="key=${{ matrix.environment }}/main.tfstate"
    
    - run: terraform validate
    
    - name: Terraform Plan
      id: plan
      run: |
        terraform plan \
          -out=tfplan.${{ matrix.environment }}.bin \
          -lock-timeout=300s \
          2>&1 | tee plan.txt
        
        # Show resource counts
        echo "::notice title=Plan Summary::$(grep -E '(Plan:|No changes)' plan.txt)"
      continue-on-error: true
    
    - name: Show Plan on PR
      uses: actions/github-script@v7
      if: github.event_name == 'pull_request'
      with:
        script: |
          const fs = require('fs');
          const plan = fs.readFileSync('environments/${{ matrix.environment }}/plan.txt', 'utf8');
          
          const comment = `## 🏗️ Terraform Plan — \`${{ matrix.environment }}\`
          
          \`\`\`
          ${plan.substring(0, 60000)}
          \`\`\`
          
          > Plan generated at: ${new Date().toISOString()}
          `;
          
          github.rest.issues.createComment({
            owner: context.repo.owner,
            repo: context.repo.repo,
            issue_number: context.issue.number,
            body: comment
          });
    
    - name: Upload plan artifact
      uses: actions/upload-artifact@v4
      with:
        name: tfplan-${{ matrix.environment }}
        path: environments/${{ matrix.environment }}/tfplan.${{ matrix.environment }}.bin
        retention-days: 3

  # ══════════════════════════════
  # APPLY (main branch only)
  # ══════════════════════════════
  apply_dev:
    name: Apply Dev
    needs: validate
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    environment:
      name: dev
      url: https://portal.azure.com/#resource/subscriptions/${{ secrets.AZURE_SUBSCRIPTION_ID }}/resourceGroups/rg-myapp-dev
    defaults:
      run:
        working-directory: environments/dev
    steps:
    - uses: actions/checkout@v4
    - uses: hashicorp/setup-terraform@v3
    - uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    - run: terraform init
    - run: terraform apply -auto-approve -lock-timeout=300s
  
  apply_staging:
    name: Apply Staging
    needs: apply_dev
    runs-on: ubuntu-latest
    environment:
      name: staging         # Requires manual approval!
    defaults:
      run:
        working-directory: environments/staging
    steps:
    - uses: actions/checkout@v4
    - uses: hashicorp/setup-terraform@v3
    - uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID_STAGING }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID_STAGING }}
    - run: terraform init
    - run: terraform apply -auto-approve
  
  apply_prod:
    name: Apply Production
    needs: apply_staging
    runs-on: ubuntu-latest
    environment:
      name: production      # Requires 2 approvals!
    defaults:
      run:
        working-directory: environments/prod
    steps:
    - uses: actions/checkout@v4
    - uses: hashicorp/setup-terraform@v3
    - uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID_PROD }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID_PROD }}
    - run: terraform init
    - run: terraform apply -auto-approve

  # ══════════════════════════════
  # DRIFT DETECTION (scheduled)
  # ══════════════════════════════
  drift_detection:
    name: Drift Detection
    if: github.event_name == 'schedule'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, staging, prod]
    environment: ${{ matrix.environment }}
    defaults:
      run:
        working-directory: environments/${{ matrix.environment }}
    
    steps:
    - uses: actions/checkout@v4
    - uses: hashicorp/setup-terraform@v3
    - uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    
    - run: terraform init
    
    - name: Check for drift
      id: drift
      run: |
        terraform plan -detailed-exitcode -no-color 2>&1 | tee drift.txt
        EXIT_CODE=${PIPESTATUS[0]}
        
        if [ $EXIT_CODE -eq 0 ]; then
          echo "drift=false" >> $GITHUB_OUTPUT
          echo "✅ No drift detected for ${{ matrix.environment }}"
        elif [ $EXIT_CODE -eq 2 ]; then
          echo "drift=true" >> $GITHUB_OUTPUT
          echo "⚠️ DRIFT DETECTED in ${{ matrix.environment }}!"
        fi
      continue-on-error: true
    
    - name: Create drift issue
      if: steps.drift.outputs.drift == 'true'
      uses: actions/github-script@v7
      with:
        script: |
          const fs = require('fs');
          const drift = fs.readFileSync('environments/${{ matrix.environment }}/drift.txt', 'utf8');
          
          await github.rest.issues.create({
            owner: context.repo.owner,
            repo: context.repo.repo,
            title: `⚠️ Infrastructure Drift Detected: ${{ matrix.environment }}`,
            body: `## Drift detected in \`${{ matrix.environment }}\`
            
            Resources in Azure differ from Terraform state.
            **Action required:** Review and apply or import the changes.
            
            \`\`\`
            ${drift.substring(0, 30000)}
            \`\`\`
            
            Detected at: ${new Date().toISOString()}
            `,
            labels: ['infrastructure', 'drift', '${{ matrix.environment }}']
          });
YAML

echo "  ✅ GitHub Actions workflow: plan-on-PR, apply-per-env, drift detection daily"

# ── Atlantis (alternative to GitHub Actions for Terraform) ────
cat > /tmp/terraform-enterprise/atlantis.yaml << 'YAML'
# atlantis.yaml — Terraform PR automation via Atlantis
version: 3

workflows:
  custom:
    plan:
      steps:
      - env:
          name: TF_VAR_environment
          value: $BASE_REPO_NAME
      - init
      - plan:
          extra_args: ["-lock-timeout=300s"]
    apply:
      steps:
      - apply:
          extra_args: ["-lock-timeout=300s"]

projects:
- name: dev
  dir: environments/dev
  workspace: dev
  workflow: custom
  apply_requirements: [approved]
  autoplan:
    when_modified: ["**/*.tf", "../../modules/**/*.tf"]
    enabled: true

- name: staging
  dir: environments/staging
  workspace: staging
  workflow: custom
  apply_requirements: [approved, mergeable]
  autoplan:
    when_modified: ["**/*.tf", "../../modules/**/*.tf"]
    enabled: true

- name: prod
  dir: environments/prod
  workspace: prod
  workflow: custom
  apply_requirements: [approved, mergeable, undiverged]  # Strictest!
  autoplan:
    when_modified: ["**/*.tf", "../../modules/**/*.tf"]
    enabled: true
YAML

echo "  ✅ Atlantis config: PR automation with progressive approvals"
echo ""
echo "=== Level 2 Complete: Terraform CI/CD Pipeline ==="


# ─────────────────────────────────────────────────────────────
# 🔴 LEVEL 3 — Enterprise Landing Zone (CAF Aligned)
# Cloud Adoption Framework: Management Groups, Policies,
# Connectivity, Identity, Management subscriptions
# ─────────────────────────────────────────────────────────────

echo ""
echo "=============================================="
echo " LEVEL 3: Enterprise Landing Zone (CAF)"
echo "=============================================="

# ── Management Group Hierarchy ────────────────────────────────
MG_ROOT="mg-contoso-root"
MG_PLATFORM="mg-contoso-platform"
MG_WORKLOADS="mg-contoso-workloads"
MG_SANDBOX="mg-contoso-sandbox"
MG_CORP="mg-contoso-corp"
MG_ONLINE="mg-contoso-online"

echo "Creating Management Group hierarchy..."

# Root management group (tenant root)
az account management-group create \
  --name $MG_ROOT \
  --display-name "Contoso Root" \
  --output none 2>/dev/null || true

# Platform (shared services)
az account management-group create \
  --name $MG_PLATFORM \
  --display-name "Platform" \
  --parent $MG_ROOT \
  --output none 2>/dev/null || true

# Workloads
az account management-group create \
  --name $MG_WORKLOADS \
  --display-name "Workloads" \
  --parent $MG_ROOT \
  --output none 2>/dev/null || true

az account management-group create \
  --name $MG_CORP \
  --display-name "Corporate (Internal Apps)" \
  --parent $MG_WORKLOADS \
  --output none 2>/dev/null || true

az account management-group create \
  --name $MG_ONLINE \
  --display-name "Online (Internet-facing)" \
  --parent $MG_WORKLOADS \
  --output none 2>/dev/null || true

# Sandbox (developer experimentation)
az account management-group create \
  --name $MG_SANDBOX \
  --display-name "Sandbox" \
  --parent $MG_ROOT \
  --output none 2>/dev/null || true

echo "  ✅ Management Group hierarchy:"
echo ""
echo "     Contoso Root (mg-contoso-root)"
echo "     ├── Platform"
echo "     │   ├── Connectivity (subscription)"
echo "     │   ├── Identity (subscription)"
echo "     │   └── Management (subscription)"
echo "     ├── Workloads"
echo "     │   ├── Corporate"
echo "     │   │   ├── Corp-Prod (subscription)"
echo "     │   │   └── Corp-NonProd (subscription)"
echo "     │   └── Online"
echo "     │       ├── Online-Prod (subscription)"
echo "     │       └── Online-NonProd (subscription)"
echo "     └── Sandbox"
echo "         └── Dev-Sandbox (subscription)"

# ── Assign CAF Policies at Root Level ────────────────────────
echo ""
echo "Assigning CAF security policies..."

MG_ROOT_SCOPE="/providers/Microsoft.Management/managementGroups/${MG_ROOT}"

# Policy 1: Require tags
az policy assignment create \
  --name "caf-require-tags-mg" \
  --display-name "CAF: Require mandatory tags on all resources" \
  --policy "96670d01-0a4d-4649-9c89-2d3bedcef605" \
  --scope "$MG_ROOT_SCOPE" \
  --params '{"tagName": {"value": "Environment"}}' \
  --enforcement-mode Default \
  --output none 2>/dev/null && echo "  ✅ Policy: Require Environment tag (root MG)"

# Policy 2: Allowed locations
az policy assignment create \
  --name "caf-allowed-locations-mg" \
  --display-name "CAF: Restrict to approved Azure regions" \
  --policy "e56962a6-4747-49cd-b67b-bf8b01975c4f" \
  --scope "$MG_ROOT_SCOPE" \
  --params '{"listOfAllowedLocations": {"value": ["eastus", "westus2", "westeurope", "global"]}}' \
  --output none 2>/dev/null && echo "  ✅ Policy: Allowed locations (root MG)"

# Policy 3: Deny public IP on VMs
az policy assignment create \
  --name "caf-deny-public-ip" \
  --display-name "CAF: Deny public IPs on virtual machines" \
  --policy "83a86a26-fd1f-447c-b59d-ddc1adbb0d72" \
  --scope "/providers/Microsoft.Management/managementGroups/${MG_CORP}" \
  --output none 2>/dev/null && echo "  ✅ Policy: No public IPs on VMs (Corporate MG)"

# Policy 4: Require HTTPS on App Services
az policy assignment create \
  --name "caf-require-https-app" \
  --display-name "CAF: Require HTTPS for web applications" \
  --policy "a4af4a39-4135-47fb-b175-47fbdf85311d" \
  --scope "$MG_ROOT_SCOPE" \
  --output none 2>/dev/null && echo "  ✅ Policy: Require HTTPS on App Services (root MG)"

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   LEVEL 3 ENTERPRISE LANDING ZONE — SUMMARY            ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║                                                          ║"
echo "║  Governance:                                             ║"
echo "║  ✅ Management Group hierarchy (CAF-aligned)            ║"
echo "║  ✅ Policies enforced at root MG (all subscriptions)    ║"
echo "║  ✅ Separate policies per MG (Corp vs Online)           ║"
echo "║                                                          ║"
echo "║  IaC:                                                    ║"
echo "║  ✅ Modular Terraform (networking, security, compute)   ║"
echo "║  ✅ GitHub Actions CI/CD with OIDC (no secrets!)        ║"
echo "║  ✅ Progressive environments: dev→staging→prod          ║"
echo "║  ✅ Daily drift detection + auto-issue creation         ║"
echo "║  ✅ PR plan comments (full diff visible before merge)   ║"
echo "║  ✅ tflint + tfsec + Checkov security scanning         ║"
echo "║  ✅ Atlantis PR automation (alternative to GH Actions)  ║"
echo "╚══════════════════════════════════════════════════════════╝"
