# 🏗️ Lab 02 — Bicep: Azure-Native Infrastructure as Code

**Difficulty:** 🟡 Intermediate  
**Time:** 90 minutes  
**Goal:** Master Bicep — Azure's declarative IaC language (like CloudFormation HCL)

---

## Background

**Bicep** is Azure's domain-specific language for deploying Azure resources. It:
- Compiles down to ARM templates (JSON)
- Has full Azure API coverage
- Supports modules, loops, conditions
- Has excellent VS Code extension with IntelliSense

```
Bicep (Human readable) → Bicep compiler → ARM Template (JSON) → Azure
    Like: HCL → Terraform → API calls
    Like: CDK (TypeScript) → CloudFormation JSON → AWS API
```

---

## Part 1 — Bicep Setup

```bash
# Install Bicep CLI
az bicep install

# Verify
az bicep version

# Install VS Code extension (recommended)
# Code --install-extension ms-azuretools.vscode-bicep

# Decompile ARM template to Bicep (for existing templates)
az bicep decompile --file existing-template.json

# Build (compile Bicep to ARM JSON)
az bicep build --file main.bicep

# Validate Bicep file
az bicep build --file main.bicep --outfile /dev/null
```

---

## Part 2 — Bicep Fundamentals

```bicep
// main.bicep — Basic resource deployment

// Parameters (like CloudFormation Parameters)
@description('The environment name')
@allowed(['dev', 'test', 'staging', 'prod'])
param environment string = 'dev'

@description('Azure region')
param location string = resourceGroup().location

@description('Project name')
@minLength(3)
@maxLength(10)
param projectName string

// Variables (computed values)
var prefix = '${projectName}-${environment}'
var tags = {
  Environment: environment
  Project: projectName
  ManagedBy: 'Bicep'
  CreatedDate: utcNow('yyyy-MM-dd')
}

// Resources
resource rg_vnet 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: 'vnet-${prefix}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-web'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'subnet-app'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'subnet-data'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
    ]
  }
}

// Outputs (like CloudFormation Outputs)
output vnetId string = rg_vnet.id
output vnetName string = rg_vnet.name
output subnetIds object = {
  web: rg_vnet.properties.subnets[0].id
  app: rg_vnet.properties.subnets[1].id
  data: rg_vnet.properties.subnets[2].id
}
```

---

## Part 3 — Comprehensive Bicep — Full Infrastructure

```bicep
// infrastructure/main.bicep
// Deploys: VNet + NSG + Storage + KeyVault + Log Analytics

// =========================================
// PARAMETERS
// =========================================
@description('Environment: dev, test, staging, prod')
@allowed(['dev', 'test', 'staging', 'prod'])
param environment string

@description('Project name (3-10 chars, lowercase)')
@minLength(3)
@maxLength(10)
param projectName string

@description('Primary Azure region')
param location string = resourceGroup().location

@description('Secondary region for geo-redundancy')
param secondaryLocation string = 'westus2'

@description('Admin username for VMs')
param adminUsername string = 'azureuser'

@secure()
@description('Admin password for VMs')
param adminPassword string

@description('Enable advanced security features')
param enableAdvancedSecurity bool = environment == 'prod'

// =========================================
// VARIABLES
// =========================================
var prefix = '${projectName}-${environment}'
var shortPrefix = take(replace('${projectName}${environment}', '-', ''), 14)

var tags = {
  Environment: environment
  Project: projectName
  ManagedBy: 'Bicep'
  Location: location
}

var vnetAddressSpace = '10.0.0.0/16'
var subnetConfig = [
  { name: 'subnet-public', prefix: '10.0.1.0/24', tier: 'web' }
  { name: 'subnet-private', prefix: '10.0.2.0/24', tier: 'app' }
  { name: 'subnet-data', prefix: '10.0.3.0/24', tier: 'data' }
  { name: 'subnet-mgmt', prefix: '10.0.4.0/24', tier: 'management' }
  { name: 'AzureBastionSubnet', prefix: '10.0.5.0/26', tier: 'bastion' }
]

// =========================================
// LOG ANALYTICS WORKSPACE
// =========================================
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'law-${prefix}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: environment == 'prod' ? 90 : 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// =========================================
// NETWORK SECURITY GROUPS
// =========================================
resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: 'nsg-web-${prefix}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'Allow-HTTPS'
        properties: {
          priority: 110
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow-AzureLoadBalancer'
        properties: {
          priority: 300
          protocol: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4096
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource nsgApp 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: 'nsg-app-${prefix}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-From-Web-Tier'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '10.0.1.0/24'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: ['8080', '8443']
        }
      }
      {
        name: 'Allow-AzureLoadBalancer'
        properties: {
          priority: 200
          protocol: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4096
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// =========================================
// VIRTUAL NETWORK WITH SUBNETS
// =========================================
resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: 'vnet-${prefix}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressSpace]
    }
    subnets: [
      // Public/Web subnet
      {
        name: 'subnet-public'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: { id: nsgWeb.id }
        }
      }
      // Private/App subnet with NAT Gateway
      {
        name: 'subnet-private'
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: { id: nsgApp.id }
          natGateway: { id: natGateway.id }
        }
      }
      // Data subnet
      {
        name: 'subnet-data'
        properties: {
          addressPrefix: '10.0.3.0/24'
          serviceEndpoints: [
            { service: 'Microsoft.Sql' }
            { service: 'Microsoft.Storage' }
          ]
        }
      }
      // Management subnet
      {
        name: 'subnet-mgmt'
        properties: {
          addressPrefix: '10.0.4.0/24'
        }
      }
      // Bastion subnet (required name)
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.5.0/26'
        }
      }
    ]
  }
}

// =========================================
// NAT GATEWAY (outbound internet for private subnets)
// =========================================
resource natGatewayPip 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: 'pip-natgw-${prefix}'
  location: location
  tags: tags
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  zones: ['1', '2', '3']
}

resource natGateway 'Microsoft.Network/natGateways@2023-06-01' = {
  name: 'natgw-${prefix}'
  location: location
  tags: tags
  sku: { name: 'Standard' }
  properties: {
    idleTimeoutInMinutes: 10
    publicIpAddresses: [{ id: natGatewayPip.id }]
  }
}

// =========================================
// STORAGE ACCOUNT
// =========================================
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'st${shortPrefix}'
  location: location
  tags: tags
  sku: {
    name: environment == 'prod' ? 'Standard_GZRS' : 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: '${vnet.id}/subnets/subnet-private'
          action: 'Allow'
        }
      ]
    }
    blobServiceProperties: {
      deleteRetentionPolicy: {
        enabled: true
        days: 30
      }
      containerDeleteRetentionPolicy: {
        enabled: true
        days: 7
      }
      isVersioningEnabled: true
    }
  }
}

// =========================================
// KEY VAULT
// =========================================
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${take(prefix, 21)}'  // Max 24 chars
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true  // Use RBAC instead of access policies
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: environment == 'prod' ? true : null
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// =========================================
// DIAGNOSTIC SETTINGS (Log all to Log Analytics)
// =========================================
resource storageAccountDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-storage'
  scope: storageAccount
  properties: {
    workspaceId: logAnalytics.id
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

resource keyVaultDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-keyvault'
  scope: keyVault
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// =========================================
// AZURE BASTION (production only)
// =========================================
resource bastionPip 'Microsoft.Network/publicIPAddresses@2023-06-01' = if (enableAdvancedSecurity) {
  name: 'pip-bastion-${prefix}'
  location: location
  tags: tags
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-06-01' = if (enableAdvancedSecurity) {
  name: 'bastion-${prefix}'
  location: location
  tags: tags
  sku: { name: 'Standard' }
  properties: {
    ipConfigurations: [
      {
        name: 'bastionIpConfig'
        properties: {
          publicIPAddress: { id: bastionPip.id }
          subnet: { id: '${vnet.id}/subnets/AzureBastionSubnet' }
        }
      }
    ]
  }
}

// =========================================
// OUTPUTS
// =========================================
output vnetId string = vnet.id
output vnetName string = vnet.name
output storageAccountName string = storageAccount.name
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output logAnalyticsWorkspaceId string = logAnalytics.id
output webSubnetId string = '${vnet.id}/subnets/subnet-public'
output appSubnetId string = '${vnet.id}/subnets/subnet-private'
output dataSubnetId string = '${vnet.id}/subnets/subnet-data'
```

---

## Part 4 — Bicep Modules

```bicep
// modules/virtualMachine.bicep — Reusable VM module
param vmName string
param location string = resourceGroup().location
param vmSize string = 'Standard_D2s_v3'
param adminUsername string
@secure()
param adminPassword string
param subnetId string
param tags object = {}

@allowed(['Ubuntu2204', 'Win2022Datacenter'])
param imageReference string = 'Ubuntu2204'

var imageMap = {
  Ubuntu2204: {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
  Win2022Datacenter: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  name: 'nic-${vmName}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: subnetId }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'  // Enable managed identity
  }
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'Premium_LRS' }
      }
      imageReference: imageMap[imageReference]
    }
    networkProfile: {
      networkInterfaces: [{ id: nic.id }]
    }
  }
}

output vmId string = vm.id
output privateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output managedIdentityPrincipalId string = vm.identity.principalId
```

```bicep
// main-with-modules.bicep — Using modules (like Terraform modules)
param environment string = 'dev'
param adminPassword string

module networking './modules/networking.bicep' = {
  name: 'networking-deployment'
  params: {
    environment: environment
    projectName: 'myapp'
  }
}

module webServer './modules/virtualMachine.bicep' = {
  name: 'webserver-deployment'
  params: {
    vmName: 'vm-web-01'
    subnetId: networking.outputs.webSubnetId
    adminPassword: adminPassword
    imageReference: 'Ubuntu2204'
  }
}

module appServer './modules/virtualMachine.bicep' = {
  name: 'appserver-deployment'
  params: {
    vmName: 'vm-app-01'
    subnetId: networking.outputs.appSubnetId
    adminPassword: adminPassword
    imageReference: 'Ubuntu2204'
    vmSize: 'Standard_D4s_v3'
  }
}

// Loop: create multiple VMs
module webServers './modules/virtualMachine.bicep' = [for i in range(1, 4): {
  name: 'webserver-${i}-deployment'
  params: {
    vmName: 'vm-web-0${i}'
    subnetId: networking.outputs.webSubnetId
    adminPassword: adminPassword
    imageReference: 'Ubuntu2204'
  }
}]
```

---

## Part 5 — Deploy Bicep Templates

```bash
# Set variables
RG="rg-bicep-lab"
LOCATION="eastus"
ENVIRONMENT="dev"

az group create --name $RG --location $LOCATION

# Deploy Bicep template
az deployment group create \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters environment=$ENVIRONMENT projectName=myapp \
  --parameters adminPassword="SecureP@ss2024!"

# Deploy with parameter file
cat > parameters.dev.json << 'EOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": { "value": "dev" },
    "projectName": { "value": "myapp" },
    "location": { "value": "eastus" },
    "adminUsername": { "value": "azureuser" }
  }
}
EOF

az deployment group create \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters @parameters.dev.json \
  --parameters adminPassword="SecureP@ss2024!"

# What-If (like terraform plan)
az deployment group what-if \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters @parameters.dev.json \
  --parameters adminPassword="SecureP@ss2024!"

# Validate without deploying
az deployment group validate \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters @parameters.dev.json \
  --parameters adminPassword="SecureP@ss2024!"

# Get deployment outputs
az deployment group show \
  --resource-group $RG \
  --name main \
  --query properties.outputs

# Deploy at subscription level
az deployment sub create \
  --location $LOCATION \
  --template-file subscription-main.bicep \
  --parameters environment=$ENVIRONMENT

# Compile Bicep to ARM JSON
az bicep build --file main.bicep --outfile main.json

# Decompile ARM JSON to Bicep
az bicep decompile --file existing.json
```

---

## Cleanup

```bash
az group delete --name rg-bicep-lab --yes --no-wait
rm -f parameters.dev.json main.json
```

---

## ✅ Lab Checklist

- [ ] Installed and configured Bicep CLI
- [ ] Created basic Bicep template with parameters and variables
- [ ] Created VNet with NSGs using Bicep
- [ ] Created Storage Account with security settings
- [ ] Created Key Vault with RBAC
- [ ] Used conditional resources (Bastion only for prod)
- [ ] Created reusable VM module
- [ ] Used for loops to create multiple VMs
- [ ] Deployed with parameter files
- [ ] Used What-If (plan) before deploying
- [ ] Retrieved deployment outputs
