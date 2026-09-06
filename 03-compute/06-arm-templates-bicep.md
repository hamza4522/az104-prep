# ARM Templates & Bicep

> 🎯 Exam Weight: Part of 20–25% Compute domain (Infrastructure as Code)

---

## 🔑 What is Infrastructure as Code (IaC)?

- Define and deploy Azure resources using **code/templates** instead of clicking the portal
- Repeatable, version-controlled, consistent deployments
- Azure supports: **ARM Templates (JSON)** and **Bicep (newer, simpler)**

---

## 📋 ARM Templates (Azure Resource Manager)

### What They Are
- JSON files that describe the **desired state** of Azure resources
- Declarative — you say WHAT you want, ARM figures out HOW to deploy it
- Idempotent — deploying the same template twice gives the same result

### ARM Template Structure

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "vmName": {
      "type": "string",
      "defaultValue": "myVM",
      "metadata": {"description": "Name of the virtual machine"}
    }
  },
  "variables": {
    "nicName": "[concat(parameters('vmName'), '-NIC')]"
  },
  "resources": [
    {
      "type": "Microsoft.Compute/virtualMachines",
      "apiVersion": "2023-03-01",
      "name": "[parameters('vmName')]",
      "location": "[resourceGroup().location]",
      "properties": { }
    }
  ],
  "outputs": {
    "vmId": {
      "type": "string",
      "value": "[resourceId('Microsoft.Compute/virtualMachines', parameters('vmName'))]"
    }
  }
}
```

### Template Sections

| Section | Required | Description |
|---------|----------|-------------|
| `$schema` | ✅ | Template schema URL |
| `contentVersion` | ✅ | Template version (you manage) |
| `parameters` | No | Input values at deployment time |
| `variables` | No | Computed values to reuse |
| `resources` | ✅ | Resources to deploy |
| `outputs` | No | Values returned after deployment |
| `functions` | No | Custom template functions |

### ARM Template Functions
| Function | Example | Result |
|----------|---------|--------|
| `concat()` | `concat('vm', '-nic')` | `vm-nic` |
| `resourceGroup().location` | - | Current RG location |
| `parameters('name')` | - | Parameter value |
| `variables('name')` | - | Variable value |
| `resourceId()` | `resourceId('Microsoft.Compute/virtualMachines', 'myVM')` | Full resource ID |
| `uniqueString()` | `uniqueString(resourceGroup().id)` | Deterministic unique hash |

---

## 🚀 Deploying ARM Templates

```bash
# Deploy to a Resource Group
az deployment group create \
  --resource-group myRG \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json

# Deploy to Subscription level
az deployment sub create \
  --location eastus \
  --template-file subscription-template.json

# Deploy to Management Group level
az deployment mg create \
  --location eastus \
  --management-group-id myMG \
  --template-file mg-template.json

# Preview changes (What-If)
az deployment group what-if \
  --resource-group myRG \
  --template-file azuredeploy.json

# PowerShell
New-AzResourceGroupDeployment \
  -ResourceGroupName "myRG" \
  -TemplateFile "azuredeploy.json" \
  -TemplateParameterFile "azuredeploy.parameters.json"
```

### Deployment Modes
| Mode | Description |
|------|-------------|
| **Incremental** (default) | Add/update resources in template; resources NOT in template are left alone |
| **Complete** | Resources in template are deployed; resources NOT in template are **deleted** |

> ⚠️ **Complete mode is destructive** — it deletes resources in the RG that aren't in the template!

---

## 🔵 Bicep

### What is Bicep?
- **Domain-specific language (DSL)** for deploying Azure resources
- Simpler, more readable than ARM JSON
- **Transpiles to ARM templates** — same underlying engine
- Type-safe, IntelliSense support, no state file needed (vs Terraform)

### ARM JSON vs Bicep Comparison

**ARM JSON (verbose):**
```json
{
  "resources": [{
    "type": "Microsoft.Storage/storageAccounts",
    "apiVersion": "2023-01-01",
    "name": "mystorageaccount",
    "location": "[resourceGroup().location]",
    "sku": {"name": "Standard_LRS"},
    "kind": "StorageV2"
  }]
}
```

**Bicep (clean):**
```bicep
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'mystorageaccount'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}
```

### Bicep Features
| Feature | Description |
|---------|-------------|
| **Modules** | Reusable Bicep files called from parent |
| **Decorators** | `@description()`, `@allowed()`, `@minValue()` on parameters |
| **Loops** | `for` loops to create multiple resources |
| **Conditions** | `if` expressions for conditional deployment |
| **Existing resources** | Reference already-deployed resources |

```bicep
// Bicep with parameters and decorators
@description('VM name')
@minLength(3)
@maxLength(15)
param vmName string = 'myVM'

@allowed(['Standard_LRS', 'Premium_LRS'])
param storageSku string = 'Standard_LRS'

// Create multiple resources with a loop
param vmCount int = 3

resource vms 'Microsoft.Compute/virtualMachines@2023-03-01' = [for i in range(0, vmCount): {
  name: '${vmName}-${i}'
  location: resourceGroup().location
  // ...
}]
```

### Bicep Commands
```bash
# Install Bicep
az bicep install

# Convert ARM template to Bicep
az bicep decompile --file azuredeploy.json

# Build/transpile Bicep to ARM
az bicep build --file main.bicep

# Deploy Bicep directly
az deployment group create \
  --resource-group myRG \
  --template-file main.bicep \
  --parameters vmName=myVM
```

---

## 📦 Template Specs

- Store ARM templates **within Azure** (not just files on disk)
- Version-controlled, shareable across subscriptions
- Managed with RBAC — control who can view/deploy

```bash
# Create a template spec
az ts create \
  --resource-group myRG \
  --name myTemplateSpec \
  --version "1.0" \
  --template-file azuredeploy.json

# Deploy from template spec
az deployment group create \
  --resource-group myTargetRG \
  --template-spec {template-spec-resource-id}
```

---

## 🔄 Deployment Stack (New Feature)

- Manages deployed resources as a unit
- Can **deny** changes to resources outside the stack
- Easy cleanup — delete stack = delete all resources it manages

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| ARM template format | **JSON** |
| Bicep transpiles to | **ARM templates** |
| Default deployment mode | **Incremental** |
| Complete mode | Deletes resources NOT in template |
| What-If flag | Preview changes before deploying |
| Template Specs | Store templates in Azure with versioning |
| Idempotent deployment | Same template → same result |
| ARM scope levels | Resource Group, Subscription, Management Group, Tenant |
| Bicep state file | **Not needed** (unlike Terraform) |

---

## 🚨 Common Exam Scenarios

**Q: You deployed an ARM template to a resource group in Complete mode. Resources that existed before the deployment but weren't in the template were deleted. Is this expected?**
→ **Yes** — Complete mode deletes resources in the RG that are not defined in the template

**Q: You need to deploy the same infrastructure to 5 different environments repeatably. What do you use?**
→ **ARM Templates or Bicep** with environment-specific parameter files

**Q: What command previews what changes an ARM template deployment will make WITHOUT actually deploying?**
→ `az deployment group what-if` (the What-If operation)

**Q: A team wants to store and share ARM templates centrally with version control within Azure. What feature?**
→ **Template Specs**

**Q: You want to write infrastructure code that's simpler than ARM JSON but still native to Azure. What language?**
→ **Bicep** — Azure-native IaC DSL that compiles to ARM
