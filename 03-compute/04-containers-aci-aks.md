# Containers: ACI, AKS & ACR

> 🎯 Exam Weight: Part of 20–25% Compute domain

---

## 📦 Container Services Comparison

| Feature | Azure Container Instances (ACI) | Azure Kubernetes Service (AKS) |
|---------|---------------------------------|--------------------------------|
| **Complexity** | Serverless, simple | Complex container orchestration |
| **Startup Time** | Seconds | Minutes (cluster startup) |
| **Pricing** | Per second of vCPU/memory used | Pay for worker node VMs only (control plane free) |
| **Use Case** | Fast batch jobs, dev/test, simple microservices | Large-scale microservices, auto-scaling clusters |
| **Orchestration** | Container groups | Pods, Deployments, StatefulSets, Ingress |

---

## 🚢 Azure Container Instances (ACI)

- **Container Groups**: A collection of containers that schedule on the same host machine and share:
  - Lifecycle (started and stopped together)
  - Local network (can communicate over `localhost`)
  - Storage volumes
- **Restart Policies**:
  - `Always`: For long-running web servers (restarts on exit).
  - `OnFailure`: For batch jobs (restarts only on non-zero exit code).
  - `Never`: Runs once to completion (e.g. one-off data migration).
- **Mounting Storage Volumes**: ACI can mount an **Azure File Share** directly as a persistent volume!

```bash
# Azure CLI: Deploy ACI mounting an Azure File Share
az container create   --resource-group "RG1"   --name "mycontainer"   --image "mcr.microsoft.com/azuredocs/aci-helloworld"   --azure-file-volume-account-name "mystorage"   --azure-file-volume-account-key "<key>"   --azure-file-volume-share-name "myshare"   --azure-file-volume-mount-path "/mnt/data"
```

---

## 🗄️ Azure Container Registry (ACR)

- Private Docker registry in Azure for storing container images
- **SKU Comparison**:
  - **Basic**: Entry-level, 10 GB storage.
  - **Standard**: 100 GB storage, increased throughput.
  - **Premium**: 500 GB, geo-replication, Private Link endpoints, content trust.
- **Authentication**:
  - **Admin User**: Simple username/password toggle for rapid testing.
  - **Service Principal / Managed Identity**: Recommended for production pipelines and AKS integration (`--attach-acr`).

```bash
# ACR Docker push workflow
az acr login --name "myacr"
docker tag myimage:v1 myacr.azurecr.io/myimage:v1
docker push myacr.azurecr.io/myimage:v1
```

---

## ☸️ Azure Kubernetes Service (AKS)

### AKS Networking Models
| Model | Pod IP Allocation | Routing Performance | Subnet IP Exhaustion Risk |
|-------|-------------------|----------------------|---------------------------|
| **Kubenet** (Basic) | Private internal IP range (NAT via node) | Standard | Low (only nodes consume subnet IPs) |
| **Azure CNI** (Advanced) | Real IP from the VNet subnet | Direct / Highest performance | **High** (every pod consumes a VNet IP) |

### Nodepools & Scaling
- **System Nodepool**: Hosts critical cluster pods (`CoreDNS`, `metrics-server`); must run Linux.
- **User Nodepool**: Hosts customer application workloads; can run Linux or Windows.
- **Cluster Autoscaler**: Adds/removes nodes automatically when pods are pending due to resource constraints.

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| ACI persistent storage volume | Mount an **Azure File Share** |
| Fast serverless container without cluster | **Azure Container Instances (ACI)** |
| ACR geo-replication SKU requirement | **Premium** SKU |
| Connecting AKS to ACR without passwords | `az aks update -n MyAKS -g RG1 --attach-acr MyACR` |
| Azure CNI IP planning | Subnet must be large enough for (Nodes + (Nodes * max pods per node)) |
| ACI restart policy for web apps | `Always` |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You need to run a containerized application in Azure that requires persistent storage and runs continuously. You want to avoid managing VMs or Kubernetes clusters.**
→ Deploy an **Azure Container Instance (ACI)** with an `Always` restart policy and mount an **Azure File Share** as a volume.

**Q: You have an AKS cluster and an Azure Container Registry (ACR). You need to allow the cluster to pull images from ACR securely without creating service principals or storing credentials in Kubernetes secrets.**
→ Run `az aks update --name MyCluster --resource-group RG1 --attach-acr MyRegistry` to grant the AKS managed identity the **AcrPull** role.

**Q: You are deploying an AKS cluster with Azure CNI networking. The cluster will have 10 nodes, with up to 30 pods per node. How many IP addresses must the subnet support?**
→ At least 310 IP addresses (+ Azure reserved IPs) because Azure CNI assigns a real subnet IP to every node and every pod.

**Q: You need to deploy a YAML manifest file to an AKS cluster named AKS1. What command should you use?**
→ Use the **`kubectl`** client (e.g., `kubectl apply -f myapp.yaml`). `az aks` manages the cluster itself. `azcopy` is for storage. To install kubectl: run `az aks install-cli` from Azure CLI.

**Q: You need to install the kubectl client tool on a Windows 10 computer that has Azure CLI installed. What command should you run?**
→ `az aks install-cli` — this downloads and installs the kubectl binary locally.

---

## 🔀 Moving a VM to a Different Virtual Network

You **cannot** directly reassign a VM's VNet after creation. The procedure is:

1. **Identify the OS disk** used by the VM
2. **Delete the VM** (retain the disk — do NOT delete the disk)
3. **Recreate the VM** in the target virtual network
4. **Attach the original OS disk** to the new VM

> 💡 **Exam Gotcha**: Moving a VM to a different VNet requires deleting and recreating it — you cannot just move or update the NIC's virtual network assignment while the VM exists.

---

## 🔌 NIC Region Constraint

- A **network interface (NIC)** must be in the **same region (location)** as the virtual machine and the virtual network it connects to
- If creating a new NIC for an existing VM: the NIC must be in the **same region as the VM**, regardless of which resource group it's in

> 💡 **Exam Tip (Q5-Q7)**: A NIC in a different resource group is allowed, but it MUST be in the same region as the VM and VNet. A NIC in a different region (e.g., Central US vs West US) will FAIL.
