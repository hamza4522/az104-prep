# 🏗️ Infrastructure as Code (IaC)

> **AWS Parallel:** CloudFormation + CDK → ARM Templates + Bicep  
> **GCP Parallel:** Deployment Manager + Terraform → Bicep + Terraform  

## IaC Options on Azure

| Tool | AWS Equivalent | Type | Language | When to Use |
|---|---|---|---|---|
| **ARM Templates** | CloudFormation | Declarative JSON | JSON | Low-level, full API coverage |
| **Bicep** | CloudFormation + CDK | Declarative DSL | Bicep | Azure-native IaC (recommended) |
| **Terraform** | Terraform | Declarative HCL | HCL | Multi-cloud, existing Terraform teams |
| **Pulumi** | Pulumi | Imperative | Python/TS/Go | Dev-friendly, same language as app |
| **Azure SDK** | AWS SDK | Imperative | Python/JS/C# | Programmatic resource management |

---

## Labs in This Section

| Lab | Title | Difficulty |
|---|---|---|
| Lab-01 | ARM Templates — Basics to Advanced | 🟡 |
| Lab-02 | Bicep — Azure-Native IaC | 🟡 |
| Lab-03 | Terraform on Azure — Full Infrastructure | 🔴 |
| Lab-04 | IaC Best Practices — Modules, State, Drift | ⭐ |
