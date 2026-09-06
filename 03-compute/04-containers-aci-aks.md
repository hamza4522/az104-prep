# Containers: ACI & AKS

> 🎯 Exam Weight: Part of 20–25% Compute domain

---

## 🐳 Container Overview

### What Are Containers?
- Lightweight, isolated environments that package **application code + dependencies**
- Share the host OS kernel (unlike VMs which have full OS)
- **Faster startup** than VMs, more portable, consistent across environments

### Docker Concepts
| Concept | Description |
|---------|-------------|
| **Image** | Blueprint/template for a container |
| **Container** | Running instance of an image |
| **Registry** | Repository of container images |
| **Dockerfile** | Script to build a Docker image |

---

## 📦 Azure Container Registry (ACR)

- **Private Docker registry** in Azure
- Store and manage container images and Helm charts
- Integrated with ACI and AKS for easy deployment

### ACR Tiers
| Tier | Storage | Use Case |
|------|---------|----------|
| **Basic** | 10 GB | Dev/testing |
| **Standard** | 100 GB | Production |
| **Premium** | 500 GB | High-volume, geo-replication |

### Key Commands
```bash
# Create ACR
az acr create --resource-group myRG --name myACR --sku Standard

# Login to ACR
az acr login --name myACR

# Build and push image to ACR
az acr build --registry myACR --image myapp:v1 .

# List images in ACR
az acr repository list --name myACR --output table
```

### ACR Authentication
| Method | Description |
|--------|-------------|
| **Admin account** | Username/password (disabled by default, not recommended) |
| **Service principal** | For automated/CI-CD scenarios |
| **Managed identity** | For Azure services (ACI, AKS) — most secure |

---

## 🏃 Azure Container Instances (ACI)

### What is ACI?
- Run **single containers** without managing servers
- Serverless container execution
- Best for: simple apps, batch jobs, task automation, event-driven workloads

### Key Features
| Feature | Detail |
|---------|--------|
| **Startup** | Seconds |
| **Billing** | Per-second while running |
| **Groups** | Multi-container groups (like Kubernetes pods) |
| **VNet integration** | Deploy into a VNet subnet |
| **Persistent storage** | Mount Azure Files shares |
| **Restart policy** | Always, OnFailure, Never |

### Creating Containers
```bash
# Run a simple container
az container create \
  --resource-group myRG \
  --name mycontainer \
  --image nginx \
  --ports 80 \
  --dns-name-label myapp-unique-label

# Run a container from ACR with managed identity
az container create \
  --resource-group myRG \
  --name mycontainer \
  --image myACR.azurecr.io/myapp:v1 \
  --acr-identity {managed-identity-id}

# View container logs
az container logs --resource-group myRG --name mycontainer

# Execute command in running container
az container exec --resource-group myRG --name mycontainer --exec-command "/bin/bash"
```

### ACI Restart Policies
| Policy | Behavior | Use Case |
|--------|---------|----------|
| **Always** | Container always restarts | Web servers |
| **OnFailure** | Restart only on non-zero exit | Batch jobs |
| **Never** | Never restart | One-time tasks |

---

## ☸️ Azure Kubernetes Service (AKS)

### What is AKS?
- **Managed Kubernetes** in Azure
- Azure handles the control plane (master nodes) — **free**
- You pay only for **worker nodes** (agent nodes)
- Use for: complex containerized applications, microservices, high scale

### Kubernetes Concepts for AZ-104
| Concept | Description |
|---------|-------------|
| **Node** | A VM in the cluster |
| **Node Pool** | Group of nodes with same configuration |
| **Pod** | Smallest deployable unit (one or more containers) |
| **Service** | Network endpoint to access pods |
| **Deployment** | Manages replica sets of pods |
| **Namespace** | Virtual cluster for isolation |

### AKS Architecture
```
AKS Cluster
    ├── Control Plane (managed by Azure, free)
    │       ├── API Server
    │       ├── Scheduler
    │       └── etcd (state store)
    └── Node Pools (you pay for these)
            ├── System Node Pool (required)
            └── User Node Pools (optional)
```

### AKS Key Features
| Feature | Description |
|---------|-------------|
| **Cluster Autoscaler** | Auto-scale nodes based on demand |
| **Horizontal Pod Autoscaler (HPA)** | Scale pods based on CPU/memory |
| **Azure CNI** | Advanced networking, pods get VNet IPs |
| **Kubenet** | Basic networking (pods on internal IP) |
| **RBAC** | Kubernetes RBAC + Azure AD integration |
| **Azure Monitor** | Container insights for monitoring |
| **Azure Policy** | Enforce governance on AKS |

### AKS Networking Modes
| Mode | Description | Use Case |
|------|-------------|----------|
| **Kubenet** | Pods get private IPs not from VNet | Simple workloads |
| **Azure CNI** | Pods get IPs from VNet subnet | Connectivity to VNet resources |
| **Azure CNI Overlay** | Pods use overlay network, VNet IPs for nodes | Scale (more pods per node) |

### Creating an AKS Cluster
```bash
# Create AKS cluster
az aks create \
  --resource-group myRG \
  --name myAKS \
  --node-count 3 \
  --node-vm-size Standard_D2s_v3 \
  --enable-managed-identity \
  --generate-ssh-keys

# Get credentials (configure kubectl)
az aks get-credentials --resource-group myRG --name myAKS

# Scale a node pool
az aks nodepool scale \
  --resource-group myRG \
  --cluster-name myAKS \
  --name nodepool1 \
  --node-count 5
```

---

## 🆚 ACI vs AKS vs App Service

| Feature | ACI | AKS | App Service |
|---------|-----|-----|-------------|
| **Best for** | Simple/short-lived containers | Microservices at scale | Web apps/APIs |
| **Managed** | Fully serverless | Control plane only | Fully managed |
| **Scaling** | Manual/restart | Auto-scale (pods + nodes) | Auto-scale |
| **Networking** | Basic | Advanced (VNet, Ingress) | Built-in |
| **Cost** | Per second | Node VMs | Plan-based |
| **Complexity** | Low | High | Low |
| **Container support** | Yes | Yes | Yes |

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| AKS control plane cost | **Free** (Azure managed) |
| AKS worker nodes | **You pay** for these |
| ACI billing | **Per-second** |
| ACR tiers | Basic (10GB), Standard (100GB), Premium (500GB) |
| ACI restart policies | Always, OnFailure, Never |
| AKS default networking | **Kubenet** |
| AKS for VNet integration | **Azure CNI** |
| Most secure ACR auth | **Managed Identity** |

---

## 🚨 Common Exam Scenarios

**Q: A team needs to run a batch job in a container that runs once and exits. What Azure service and restart policy?**
→ **ACI** with restart policy **Never** (or OnFailure)

**Q: An organization has 200 microservices that need to communicate with each other and auto-scale. What service?**
→ **AKS** — designed for complex, multi-container microservice architectures

**Q: You need to pull container images in AKS from ACR without storing credentials. What do you configure?**
→ Enable **Managed Identity** on AKS and grant it **AcrPull** role on ACR

**Q: Which AKS networking mode should you use if pods need to access other resources in the VNet directly?**
→ **Azure CNI** — pods get IPs from the VNet subnet
