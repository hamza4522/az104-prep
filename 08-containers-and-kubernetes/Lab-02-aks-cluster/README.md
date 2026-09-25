# ☸️ Lab 02 — AKS Cluster: Create, Configure & Deploy

**Difficulty:** 🟡 Intermediate  
**Time:** 90 minutes  
**Goal:** Create a production-grade AKS cluster, deploy apps, configure scaling and networking

---

## Part 1 — Create AKS Cluster

```bash
RG="rg-aks-lab"
LOCATION="eastus"
CLUSTER_NAME="aks-prod-eastus"
ACR_NAME="acrlab$(date +%s)"

az group create --name $RG --location $LOCATION

# Register AKS provider
az provider register --namespace Microsoft.ContainerService

# =========================================
# Create AKS Cluster — Production Grade
# =========================================
az aks create \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --location $LOCATION \
  --kubernetes-version 1.29.0 \
  --node-count 3 \
  --node-vm-size Standard_D4s_v3 \
  --node-osdisk-size 128 \
  --node-osdisk-type Managed \
  --os-sku Ubuntu \
  --max-pods 110 \
  --network-plugin azure \
  --network-policy azure \
  --service-cidr 10.100.0.0/16 \
  --dns-service-ip 10.100.0.10 \
  --vnet-subnet-id "/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/vnet-aks/subnets/subnet-aks" \
  --enable-managed-identity \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 10 \
  --enable-addons monitoring \
  --workspace-resource-id "$(az monitor log-analytics workspace list --query '[0].id' --output tsv)" \
  --enable-oidc-issuer \
  --enable-workload-identity \
  --tags Environment=Lab Project=AKS

# NOTE: For quick lab (no existing VNet), use simpler command:
az aks create \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --location $LOCATION \
  --node-count 2 \
  --node-vm-size Standard_D2s_v3 \
  --enable-managed-identity \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5 \
  --generate-ssh-keys \
  --enable-addons monitoring \
  --attach-acr $ACR_NAME

echo "✅ AKS cluster created"

# Get kubectl credentials (like aws eks update-kubeconfig)
az aks get-credentials \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --overwrite-existing

# Verify connection
kubectl get nodes -o wide
kubectl get namespaces
kubectl cluster-info
```

---

## Part 2 — AKS Node Pools

```bash
# List node pools
az aks nodepool list \
  --resource-group $RG \
  --cluster-name $CLUSTER_NAME \
  --output table

# Add a specialized node pool (spot instances for cost savings)
az aks nodepool add \
  --resource-group $RG \
  --cluster-name $CLUSTER_NAME \
  --name spotnodes \
  --node-count 2 \
  --node-vm-size Standard_D4s_v3 \
  --priority Spot \
  --eviction-policy Delete \
  --spot-max-price -1 \
  --enable-cluster-autoscaler \
  --min-count 0 \
  --max-count 10 \
  --labels workload=batch \
  --node-taints "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"

# Add Windows node pool
az aks nodepool add \
  --resource-group $RG \
  --cluster-name $CLUSTER_NAME \
  --name winnodes \
  --os-type Windows \
  --os-sku Windows2022 \
  --node-count 1 \
  --node-vm-size Standard_D4s_v3

# Add GPU node pool
az aks nodepool add \
  --resource-group $RG \
  --cluster-name $CLUSTER_NAME \
  --name gpunodes \
  --node-count 1 \
  --node-vm-size Standard_NC6s_v3 \
  --node-taints "sku=gpu:NoSchedule" \
  --labels "hardware=gpu"

# Scale a node pool
az aks nodepool scale \
  --resource-group $RG \
  --cluster-name $CLUSTER_NAME \
  --name agentpool \
  --node-count 5

# Upgrade a node pool
az aks nodepool upgrade \
  --resource-group $RG \
  --cluster-name $CLUSTER_NAME \
  --name agentpool \
  --kubernetes-version 1.29.2 \
  --max-surge 33%

# Delete a node pool
az aks nodepool delete \
  --resource-group $RG \
  --cluster-name $CLUSTER_NAME \
  --name spotnodes \
  --no-wait
```

---

## Part 3 — Deploy Applications to AKS

```bash
# =========================================
# Deploy a sample application
# =========================================

# Create namespace
kubectl create namespace myapp

# Deploy nginx application
cat > deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-web
  namespace: myapp
  labels:
    app: myapp-web
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp-web
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: myapp-web
        version: v1
    spec:
      containers:
      - name: myapp-web
        image: nginx:alpine
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
      nodeSelector:
        kubernetes.io/os: linux
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - myapp-web
              topologyKey: kubernetes.io/hostname
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-web-svc
  namespace: myapp
spec:
  selector:
    app: myapp-web
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  type: LoadBalancer
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-web-hpa
  namespace: myapp
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp-web
  minReplicas: 2
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF

kubectl apply -f deployment.yaml

# Watch pods come up
kubectl get pods -n myapp -w

# Wait for load balancer IP
kubectl get svc -n myapp myapp-web-svc -w

# Get external IP
EXTERNAL_IP=$(kubectl get svc -n myapp myapp-web-svc \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "App URL: http://$EXTERNAL_IP"
curl http://$EXTERNAL_IP
```

### Deploy from ACR

```bash
# Deploy using ACR image
cat > acr-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-acr
  namespace: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp-acr
  template:
    metadata:
      labels:
        app: myapp-acr
    spec:
      containers:
      - name: myapp
        image: ${ACR_LOGIN_SERVER}/myapp:v1.0
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
EOF

kubectl apply -f acr-deployment.yaml
kubectl rollout status deployment/myapp-acr -n myapp
```

---

## Part 4 — Kubernetes ConfigMaps and Secrets

```bash
# Create ConfigMap (application configuration)
kubectl create configmap app-config \
  --namespace myapp \
  --from-literal=DATABASE_HOST="sqlsrv-lab.database.windows.net" \
  --from-literal=DATABASE_NAME="myapp-db" \
  --from-literal=REDIS_HOST="redis-lab.redis.cache.windows.net" \
  --from-literal=APP_ENV="production"

# Create from file
cat > app-settings.properties << 'EOF'
app.name=MyAzureApp
app.version=1.0
feature.flag.newUI=true
EOF
kubectl create configmap app-settings \
  --namespace myapp \
  --from-file=app-settings.properties

# View ConfigMap
kubectl get configmap -n myapp
kubectl describe configmap app-config -n myapp

# Create Secret (sensitive data)
kubectl create secret generic app-secrets \
  --namespace myapp \
  --from-literal=DB_PASSWORD="SuperSecret123!" \
  --from-literal=API_KEY="abc123def456"

# Create secret from Azure Key Vault (preferred approach)
# Using Azure Key Vault Provider for Secrets Store CSI Driver

# Install CSI driver
az aks enable-addons \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --addons azure-keyvault-secrets-provider

# Create Key Vault
KV_NAME="kv-aks-$(date +%s)"
az keyvault create \
  --resource-group $RG \
  --name $KV_NAME \
  --location $LOCATION \
  --enable-rbac-authorization true

# Store secret in Key Vault
az keyvault secret set \
  --vault-name $KV_NAME \
  --name "db-password" \
  --value "SuperSecretDBPassword123!"

# SecretProviderClass for mounting Key Vault secrets
cat > secret-provider.yaml << EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-secrets
  namespace: myapp
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: ""
    keyvaultName: "$KV_NAME"
    objects: |
      array:
        - |
          objectName: db-password
          objectType: secret
          objectVersion: ""
    tenantId: "$(az account show --query tenantId --output tsv)"
  secretObjects:
  - data:
    - key: password
      objectName: db-password
    secretName: db-secret
    type: Opaque
EOF

kubectl apply -f secret-provider.yaml
```

---

## Part 5 — Ingress Controller (NGINX)

```bash
# Install NGINX Ingress Controller via Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set controller.service.externalTrafficPolicy=Local

# Wait for ingress controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Get ingress IP
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ingress IP: $INGRESS_IP"

# Create Ingress resource
cat > ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: myapp
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.${INGRESS_IP}.nip.io
    secretName: myapp-tls
  rules:
  - host: myapp.${INGRESS_IP}.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-web-svc
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: myapp-api-svc
            port:
              number: 8080
EOF

kubectl apply -f ingress.yaml
echo "App available at: http://myapp.${INGRESS_IP}.nip.io"
```

---

## Part 6 — AKS Monitoring and Diagnostics

```bash
# =========================================
# Azure Monitor for Containers
# =========================================

# Enable Container Insights
az aks enable-addons \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --addons monitoring

# View Kubernetes events
kubectl get events -n myapp --sort-by='.lastTimestamp'

# View pod logs
kubectl logs -n myapp deployment/myapp-web
kubectl logs -n myapp deployment/myapp-web --previous  # crash logs
kubectl logs -n myapp deployment/myapp-web --follow    # stream logs

# Exec into a pod (like SSM Session Manager)
POD_NAME=$(kubectl get pod -n myapp -l app=myapp-web -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_NAME -n myapp -- /bin/sh

# Check resource usage
kubectl top nodes
kubectl top pods -n myapp

# Describe pod for troubleshooting
kubectl describe pod $POD_NAME -n myapp

# Port forward to access service locally
kubectl port-forward svc/myapp-web-svc 8080:80 -n myapp
# Now access via http://localhost:8080

# =========================================
# AKS Diagnostics via Azure CLI
# =========================================

# Get cluster info
az aks show \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --output json

# Check cluster health
az aks check-network outbound \
  --resource-group $RG \
  --name $CLUSTER_NAME

# Browse AKS dashboard (opens in browser)
az aks browse --resource-group $RG --name $CLUSTER_NAME
```

---

## Part 7 — AKS Upgrades

```bash
# List available Kubernetes versions
az aks get-upgrades \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --output table

# Upgrade cluster control plane
az aks upgrade \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --kubernetes-version 1.29.2 \
  --control-plane-only \
  --no-wait

# Then upgrade node pools separately
az aks nodepool upgrade \
  --resource-group $RG \
  --cluster-name $CLUSTER_NAME \
  --name agentpool \
  --kubernetes-version 1.29.2 \
  --max-surge 33%

# Enable auto-upgrade channel
az aks update \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --auto-upgrade-channel patch

# auto-upgrade options:
# none     — no auto upgrade
# patch    — auto upgrade patch versions
# stable   — auto upgrade to stable minor version
# rapid    — latest Kubernetes version
# node-image — only upgrade node OS images
```

---

## Cleanup

```bash
kubectl delete namespace myapp
az group delete --name rg-aks-lab --yes --no-wait
echo "AKS lab cleanup initiated!"
```

---

## ✅ Lab Checklist

- [ ] Created AKS cluster with managed identity
- [ ] Got kubectl credentials
- [ ] Added spot instance node pool
- [ ] Deployed application with Deployment + Service + HPA
- [ ] Deployed from ACR image
- [ ] Created ConfigMaps and Secrets
- [ ] Set up Azure Key Vault integration
- [ ] Installed NGINX Ingress Controller
- [ ] Configured Ingress with routing rules
- [ ] Monitored pods with kubectl and Azure Monitor
- [ ] Performed AKS cluster upgrade

---

## 📚 AKS vs EKS vs GKE Quick Reference

| Feature | AKS | EKS | GKE |
|---|---|---|---|
| Control plane cost | Free | $0.10/hr | $0.10/hr |
| Get credentials | `az aks get-credentials` | `aws eks update-kubeconfig` | `gcloud container clusters get-credentials` |
| Node identity | Managed Identity | IRSA | Workload Identity |
| Registry access | ACR attach | ECR policy | Artifact Registry auto |
| Ingress | AGIC / NGINX | ALB Ingress / NGINX | GKE Ingress / NGINX |
| Spot nodes | Spot Node Pools | Spot node groups | Spot pods / Spot nodes |
| Windows nodes | ✅ Yes | ✅ Yes | ✅ Yes |
