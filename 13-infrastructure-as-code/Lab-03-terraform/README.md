# 🏗️ Lab 03 — Terraform on Azure: Full Infrastructure

**Difficulty:** 🔴 Advanced  
**Time:** 120 minutes  
**Goal:** Deploy complete Azure infrastructure using Terraform — same workflow as AWS/GCP Terraform

---

## Background

Terraform on Azure uses the **AzureRM provider** (and **AzureAD provider** for IAM).

```hcl
# AWS:   provider "aws" {}
# GCP:   provider "google" {}
# Azure: provider "azurerm" {}
#        provider "azuread" {}
```

---

## Part 1 — Terraform Setup for Azure

```bash
# Install Terraform
# Windows:
winget install HashiCorp.Terraform

# macOS:
brew install terraform

# Linux:
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install -y terraform

# Verify
terraform version

# Create state storage (Terraform remote state — like S3 backend)
RG="rg-terraform-state"
LOCATION="eastus"
STORAGE_ACCOUNT="stterraformstate$(date +%s)"
CONTAINER_NAME="tfstate"

az group create --name $RG --location $LOCATION

az storage account create \
  --resource-group $RG \
  --name $STORAGE_ACCOUNT \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2

# Enable versioning for state file recovery
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --resource-group $RG \
  --enable-versioning true

az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT

echo "Terraform state storage ready:"
echo "Resource Group: $RG"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Container: $CONTAINER_NAME"
```

---

## Part 2 — Provider Configuration

```hcl
# providers.tf
terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.46"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  
  # Remote state in Azure Storage (like S3 backend in AWS)
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "REPLACE_WITH_STORAGE_ACCOUNT"
    container_name       = "tfstate"
    key                  = "prod/main.tfstate"
    
    # These can also be set via env vars:
    # ARM_ACCESS_KEY or ARM_SAS_TOKEN or ARM_USE_MSI=true
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
      graceful_shutdown = true
    }
  }
  
  # Auth: Use environment variables
  # ARM_SUBSCRIPTION_ID, ARM_TENANT_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET
  # Or: ARM_USE_MSI=true for managed identity
}

provider "azuread" {
  # tenant_id = var.tenant_id
  # Or use ARM_TENANT_ID env var
}
```

---

## Part 3 — Variables and Locals

```hcl
# variables.tf
variable "environment" {
  type        = string
  description = "Environment name"
  validation {
    condition     = contains(["dev", "test", "staging", "prod"], var.environment)
    error_message = "Environment must be: dev, test, staging, or prod"
  }
}

variable "project_name" {
  type        = string
  description = "Project name (3-10 chars, lowercase)"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,9}$", var.project_name))
    error_message = "Project name must be 3-10 lowercase alphanumeric chars starting with a letter"
  }
}

variable "location" {
  type        = string
  description = "Primary Azure region"
  default     = "eastus"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "vm_count" {
  type    = number
  default = 2
}

variable "enable_bastion" {
  type    = bool
  default = false
}

# terraform.tfvars (don't commit sensitive values!)
# environment    = "dev"
# project_name   = "myapp"
# location       = "eastus"
# admin_username = "azureuser"
# vm_count       = 2
```

```hcl
# locals.tf
locals {
  prefix       = "${var.project_name}-${var.environment}"
  short_prefix = substr(replace("${var.project_name}${var.environment}", "-", ""), 0, 14)
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Network configuration
  vnet_cidr = "10.0.0.0/16"
  subnets = {
    public     = { cidr = "10.0.1.0/24", tier = "web" }
    private    = { cidr = "10.0.2.0/24", tier = "app" }
    data       = { cidr = "10.0.3.0/24", tier = "data" }
    management = { cidr = "10.0.4.0/24", tier = "mgmt" }
    bastion    = { cidr = "10.0.5.0/26", tier = "bastion" }
  }
  
  # VM sizes per environment
  vm_size = {
    dev     = "Standard_B2s"
    test    = "Standard_B2s"
    staging = "Standard_D2s_v3"
    prod    = "Standard_D4s_v3"
  }
  
  # Storage redundancy per environment
  storage_replication = {
    dev     = "LRS"
    test    = "LRS"
    staging = "GRS"
    prod    = "GZRS"
  }
}
```

---

## Part 4 — Core Resources

```hcl
# main.tf

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = local.tags
}

# Random suffix for globally unique names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# =========================================
# NETWORKING
# =========================================
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [local.vnet_cidr]
  tags                = local.tags
}

resource "azurerm_subnet" "subnets" {
  for_each = local.subnets
  
  name                 = "subnet-${each.key}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.cidr]
  
  # Enable service endpoints for data subnet
  dynamic "service_endpoints" {
    for_each = each.key == "data" ? ["Microsoft.Sql", "Microsoft.Storage"] : []
    content {
      service = service_endpoints.value
    }
  }
}

resource "azurerm_network_security_group" "web" {
  name                = "nsg-web-${local.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-AzureLoadBalancer"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.subnets["public"].id
  network_security_group_id = azurerm_network_security_group.web.id
}

# NAT Gateway
resource "azurerm_public_ip" "natgw" {
  name                = "pip-natgw-${local.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = local.tags
}

resource "azurerm_nat_gateway" "main" {
  name                    = "natgw-${local.prefix}"
  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  idle_timeout_in_minutes = 10
  tags                    = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.natgw.id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  subnet_id      = azurerm_subnet.subnets["private"].id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

# =========================================
# STORAGE ACCOUNT
# =========================================
resource "azurerm_storage_account" "main" {
  name                     = "st${local.short_prefix}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = local.storage_replication[var.environment]
  account_kind             = "StorageV2"
  access_tier              = "Hot"
  
  min_tls_version          = "TLS1_2"
  https_traffic_only_enabled = true
  allow_nested_items_to_be_public = false
  
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 7
    }
  }
  
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [azurerm_subnet.subnets["private"].id]
  }
  
  tags = local.tags
}

# =========================================
# KEY VAULT
# =========================================
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "kv-${substr(local.prefix, 0, 21)}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  
  enable_rbac_authorization   = true
  soft_delete_retention_days  = 90
  purge_protection_enabled    = var.environment == "prod" ? true : false
  
  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
  
  tags = local.tags
}

# Grant current user Key Vault Administrator
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# =========================================
# VIRTUAL MACHINES
# =========================================
resource "azurerm_network_interface" "vm" {
  count = var.vm_count
  
  name                = "nic-vm-${local.prefix}-${count.index + 1}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnets["private"].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count = var.vm_count
  
  name                = "vm-app-${local.prefix}-${count.index + 1}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = local.vm_size[var.environment]
  admin_username      = var.admin_username
  
  # Use SSH key in production
  admin_password                  = var.admin_password
  disable_password_authentication = false
  
  network_interface_ids = [azurerm_network_interface.vm[count.index].id]
  
  identity {
    type = "SystemAssigned"
  }
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  
  custom_data = base64encode(<<-CLOUDINIT
    #cloud-config
    package_upgrade: true
    packages:
      - nginx
      - curl
      - htop
    runcmd:
      - systemctl enable nginx
      - systemctl start nginx
  CLOUDINIT
  )
  
  tags = merge(local.tags, {
    Role  = "AppServer"
    Index = tostring(count.index + 1)
  })
}
```

---

## Part 5 — Outputs

```hcl
# outputs.tf
output "resource_group_name" {
  description = "Resource Group name"
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value = {
    for k, v in azurerm_subnet.subnets : k => v.id
  }
}

output "storage_account_name" {
  description = "Storage Account name"
  value       = azurerm_storage_account.main.name
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

output "vm_private_ips" {
  description = "VM private IP addresses"
  value       = [for nic in azurerm_network_interface.vm : nic.private_ip_address]
}

output "vm_managed_identity_ids" {
  description = "VM managed identity principal IDs"
  value       = [for vm in azurerm_linux_virtual_machine.vm : vm.identity[0].principal_id]
}
```

---

## Part 6 — Terraform Workflow

```bash
# Initialize Terraform (download providers, configure backend)
terraform init

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan (like Bicep what-if / CloudFormation change set)
terraform plan \
  -var="environment=dev" \
  -var="project_name=myapp" \
  -var="admin_password=SecureP@ss2024!" \
  -out=tfplan.dev

# Apply
terraform apply tfplan.dev

# Or combined:
terraform apply \
  -var="environment=dev" \
  -var="project_name=myapp" \
  -var="admin_password=SecureP@ss2024!" \
  -auto-approve

# Show state
terraform show
terraform state list

# Show specific resource
terraform state show azurerm_virtual_network.main

# Import existing resource (like importing existing AWS resource)
terraform import azurerm_resource_group.main \
  /subscriptions/SUB_ID/resourceGroups/existing-rg

# Refresh state (sync with actual Azure state)
terraform refresh

# Destroy
terraform destroy \
  -var="environment=dev" \
  -var="project_name=myapp" \
  -var="admin_password=SecureP@ss2024!" \
  -auto-approve

# Destroy specific resource
terraform destroy -target=azurerm_virtual_machine.vm[0]
```

---

## ✅ Lab Checklist

- [ ] Created Terraform state storage in Azure Blob
- [ ] Configured AzureRM provider with remote state
- [ ] Created variables, locals, and outputs
- [ ] Deployed VNet, subnets, NSGs
- [ ] Created NAT Gateway and associations
- [ ] Created Storage Account with security settings
- [ ] Created Key Vault with RBAC
- [ ] Created multiple VMs with count/loops
- [ ] Used dynamic blocks for conditional resources
- [ ] Ran `terraform plan`, `apply`, `destroy`
- [ ] Used `terraform state` commands
