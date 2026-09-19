# ARM Templates & Bicep

> 🎯 Exam Weight: Part of 20–25% Compute domain

---

## 🔑 Infrastructure as Code (IaC)

- **Declarative syntax**: You define *what* resources you want, and Azure handles *how* to deploy them
- **Idempotent**: Running the same template multiple times results in the same identical state
- Formats:
  - **ARM Templates**: JSON files
  - **Bicep**: Cleaner, human-readable domain-specific language (DSL) that transpiles to ARM JSON

---

## 🏗️ ARM Template JSON Structure

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "vmName": { "type": "string", "defaultValue": "WebVM1" }
  },
  "variables": {
    "nicName": "[concat(parameters('vmName'), '-nic')]"
  },
  "functions": [],
  "resources": [
    {
      "type": "Microsoft.Network/networkInterfaces",
      "apiVersion": "2022-07-01",
      "name": "[variables('nicName')]",
      "location": "[resourceGroup().location]",
      "properties": { ... }
    }
  ],
  "outputs": {
    "privateIP": {
      "type": "string",
      "value": "[reference(variables('nicName')).ipConfigurations[0].properties.privateIPAddress]"
    }
  }
}
```

---

## ⚡ Deployment Modes: Incremental vs Complete (CRITICAL!)

```
Resource Group: [VM1, Storage1, SQL1]
Template specifies: [VM1, Storage2]
```

| Deployment Mode | What Happens to Existing Resources | Default? | Risk Level |
|-----------------|-----------------------------------|----------|------------|
| **Incremental** | Deploys new resources (`Storage2`), updates matching (`VM1`), **leaves unmentioned resources (`Storage1`, `SQL1`) untouched** | ✅ **YES** | Low |
| **Complete** | Deploys template resources (`VM1`, `Storage2`), and **PERMANENTLY DELETES any resource in the RG not in the template (`Storage1`, `SQL1`)**! | ❌ No | **High** |

> ⚠️ **CRITICAL Exam Gotcha**:
> - If an exam question asks what happens to an existing VM in a resource group after a template deployment:
>   - In **Incremental mode**: VM is **NOT deleted**.
>   - In **Complete mode**: VM is **DELETED** if it is not defined in the template.

---

## 🛠️ CLI & PowerShell Deployment Commands

```bash
# Preview changes using What-If
az deployment group what-if   --resource-group "RG1"   --template-file "azuredeploy.json"   --parameters @azuredeploy.parameters.json

# Deploy template in Incremental mode
az deployment group create   --resource-group "RG1"   --name "Deploy01"   --template-file "azuredeploy.json"   --parameters @azuredeploy.parameters.json

# Deploy template in Complete mode
az deployment group create   --resource-group "RG1"   --template-file "azuredeploy.json"   --mode Complete
```

```powershell
# PowerShell Deployment
New-AzResourceGroupDeployment `
  -ResourceGroupName "RG1" `
  -TemplateFile "azuredeploy.json" `
  -TemplateParameterFile "azuredeploy.parameters.json" `
  -Mode Complete
```

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Default deployment mode | **Incremental** |
| Complete mode behavior | Deletes any resource in RG not defined in the template |
| Parameter file secrets | Reference Azure Key Vault secrets dynamically |
| Preview changes command | `az deployment group what-if` / `Get-AzResourceGroupDeploymentWhatIfResult` |
| ARM template parameter precedence | Inline parameters override parameter file values |
| Bicep vs ARM JSON | Bicep compiles into standard ARM JSON before submission to ARM API |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: A resource group named RG1 contains 10 virtual machines. You deploy an ARM template to RG1 that defines only 2 storage accounts, using Complete mode. What happens to the 10 virtual machines?**
→ The 10 virtual machines are **permanently deleted** because Complete mode removes all resources in the target resource group that are not declared in the template.

**Q: You need to preview the effects of deploying an updated ARM template to see which resources will be modified, created, or deleted before actually executing the deployment.**
→ Run the **What-If** operation:
`az deployment group what-if --resource-group RG1 --template-file template.json`.

**Q: How can you deploy an ARM template without exposing plain-text database passwords in `azuredeploy.parameters.json`?**
→ In the parameter file, use a `reference` object pointing to an Azure Key Vault secret ID.
