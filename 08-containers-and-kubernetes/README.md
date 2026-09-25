# 📦 Azure Containers & Kubernetes (AKS)

> **AWS Parallel:** ECR + EKS → Azure Container Registry (ACR) + AKS  
> **GCP Parallel:** Artifact Registry + GKE → ACR + AKS  
> **OCI Parallel:** OCIR + OKE → ACR + AKS

## Container Services Overview

| Azure Service | AWS Equivalent | GCP Equivalent | Purpose |
|---|---|---|---|
| **Azure Container Registry (ACR)** | ECR | Artifact Registry | Private container registry |
| **Azure Kubernetes Service (AKS)** | EKS | GKE | Managed Kubernetes |
| **Azure Container Instances (ACI)** | ECS Fargate | Cloud Run | Serverless containers |
| **Azure Container Apps** | ECS + App Runner | Cloud Run | Microservices PaaS |
| **Azure Red Hat OpenShift** | — | Anthos | Managed OpenShift |

## Key AKS vs EKS Differences

| Feature | AKS | EKS | GKE |
|---|---|---|---|
| Control plane cost | FREE | $0.10/hr | $0.10/hr |
| Node OS | Ubuntu / Windows | Amazon Linux 2 | Container-Optimized OS |
| Node pools | Multiple pools | Node groups | Node pools |
| Auto-scaling | Cluster Autoscaler + KEDA | Cluster Autoscaler | Autopilot / Standard |
| Managed identity | Workload Identity | IRSA | Workload Identity |
| Ingress | NGINX / AGIC | ALB Ingress | GKE Ingress |
| Monitoring | Azure Monitor + Container Insights | CloudWatch Container | Cloud Monitoring |
| GitOps | Flux (built-in) | Flux / ArgoCD | Config Sync |
| CNI plugin | Azure CNI / Kubenet / Cilium | VPC CNI | Dataplane V2 |

---

## Labs in This Section

| Lab | Title | Difficulty |
|---|---|---|
| Lab-01 | Azure Container Registry (ACR) | 🟢 |
| Lab-02 | AKS Cluster — Create & Configure | 🟡 |
| Lab-03 | Deploy Applications to AKS | 🟡 |
| Lab-04 | AKS Networking — Ingress & Load Balancing | 🔴 |
| Lab-05 | AKS Security — RBAC, Pod Identity, Network Policies | 🔴 |
| Lab-06 | AKS Scaling — HPA, VPA, KEDA, Cluster Autoscaler | 🔴 |
| Lab-07 | AKS Monitoring with Azure Monitor & Prometheus | 🔴 |
| Lab-08 | Azure Container Instances (ACI) | 🟡 |
| Lab-09 | Azure Container Apps | 🟡 |
