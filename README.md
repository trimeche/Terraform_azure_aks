# 🚀 AKS Platform — Enterprise Infrastructure on Azure


> Enterprise-grade Kubernetes platform on Azure with WAF, private networking,
> multiple microservices, and full observability — provisioned entirely with Terraform.

---

## 📐 Architecture Overview

```
                         ┌──────────────────┐
                         │   🌐 Internet    │
                         └────────┬─────────┘
                                  │ DNS lookup
                         ┌────────▼─────────┐
                         │   🔵 Azure DNS   │
                         │  dev-api.myapp.com│
                         └────────┬─────────┘
                                  │ Resolved IP
                         ┌────────▼─────────┐
                         │  🛡️  WAF v2 +    │
                         │  App Gateway     │
                         │  OWASP 3.1 rules │
                         │  SSL Termination │
                         └────────┬─────────┘
                                  │
     ╔════════════════════════════▼═════════════════════════════╗
     ║          VNet: vnet-aksplatform-dev-weu                  ║
     ║                    10.0.0.0/8                            ║
     ║                                                          ║
     ║  ┌───────────────────────────────────────────────────┐   ║
     ║  │  snet-appgw-dev · 10.1.0.0/24                    │   ║
     ║  │  NSG: Allow :80/:443 · Deny all inbound          │   ║
     ║  │         [ Application Gateway v2 ]               │   ║
     ║  └──────────────────────┬────────────────────────────┘   ║
     ║                         │                                ║
     ║  ┌──────────────────────▼────────────────────────────┐   ║
     ║  │  snet-aks-nodes-dev · 10.2.0.0/16                │   ║
     ║  │  NSG: Allow AppGW only · Deny Internet           │   ║
     ║  │  CNI Overlay: Pod IPs = 192.168.x.x (internal)   │   ║
     ║  │                                                   │   ║
     ║  │       [ NGINX Ingress · NodePort :30080 ]        │   ║
     ║  │                      │                           │   ║
     ║  │         /nodejs/*    │    /dotnet/*              │   ║
     ║  │              ┌───────┴────────┐                  │   ║
     ║  │              │                │                  │   ║
     ║  │   ┌──────────▼──────┐  ┌──────▼──────────┐      │   ║
     ║  │   │  nodejs-app     │  │  dotnet-app     │      │   ║
     ║  │   │  namespace      │  │  namespace      │      │   ║
     ║  │   │                 │  │                 │      │   ║
     ║  │   │  [pod-1][pod-2] │  │  [pod-1][pod-2] │      │   ║
     ║  │   │  Node.js 20     │  │  .NET 8 API     │      │   ║
     ║  │   │  :3000          │  │  :8080          │      │   ║
     ║  │   │  HPA: 2-5 pods  │  │  HPA: 2-5 pods  │      │   ║
     ║  │   └─────────────────┘  └─────────────────┘      │   ║
     ║  │                                                   │   ║
     ║  │  ✅ Workload Identity  ✅ Calico Network Policy   │   ║
     ║  │  ✅ AAD RBAC           ✅ Key Vault CSI Driver    │   ║
     ║  └───────────────────────────────────────────────────┘   ║
     ║                                                          ║
     ║  ┌───────────────────────────────────────────────────┐   ║
     ║  │  snet-pe-dev · 10.4.0.0/24 · Private Endpoints   │   ║
     ║  │                                                   │   ║
     ║  │  [PE → ACR]              [PE → Key Vault]        │   ║
     ║  │  privatelink.azurecr.io  privatelink.vaultcore   │   ║
     ║  └───────────────────────────────────────────────────┘   ║
     ╚══════════════════════════════════════════════════════════╝
                    │                          │
       ┌────────────▼──────────┐  ┌────────────▼──────────┐
       │  📦 ACR (acrplatform) │  │  🔑 Key Vault         │
       │  Premium SKU          │  │  Secrets · TLS Certs  │
       │  AcrPull via MI       │  │  CSI Driver mount     │
       │  Private Endpoint ✓   │  │  Private Endpoint ✓   │
       └───────────────────────┘  └───────────────────────┘

       ┌──────────────────────────────────────────────────┐
       │              📊 Observability Layer              │
       │                                                  │
       │  Log Analytics Workspace (law-aksplatform-dev)   │
       │  ├── AKS Container Insights                      │
       │  ├── WAF Access Logs                             │
       │  └── Node + Pod Metrics · Retention 30 days      │
       │                                                  │
       │  Application Insights (appi-law-aksplatform-dev) │
       │  ├── .NET 8 API — Request tracing                │
       │  ├── Node.js API — Performance metrics           │
       │  └── Exceptions · Dependencies · Live Metrics    │
       └──────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
aks-platform/
├── 📄 main.tf                    # Module orchestration (7 modules)
├── 📄 variables.tf               # Input variables
├── 📄 locals.tf                  # Naming conventions
├── 📄 outputs.tf                 # Exported values
├── 📄 versions.tf                # Provider versions (azurerm ~3.90)
├── 📄 azure-pipelines.yml        # ADO CI/CD pipeline
│
├── 📂 modules/
│   ├── 🌐 networking/            # VNet · 3 Subnets · 2 NSGs
│   ├── 🐳 acr/                   # Azure Container Registry + PE
│   ├── 🔑 keyvault/              # Key Vault + Private Endpoint
│   ├── 📊 monitoring/            # Log Analytics + App Insights
│   ├── ☸️  aks/                   # AKS Cluster + Node Pools
│   ├── 🌿 nginx/                 # NGINX Ingress via Helm
│   └── 🛡️  waf/                   # App Gateway + WAF Policy
│
├── 📂 environments/
│   ├── dev/terraform.tfvars      # Dev: Detection mode, smaller nodes
│   └── prod/terraform.tfvars     # Prod: Prevention mode, larger nodes
│
├── 📂 app/                       # .NET 8 Minimal API
│   ├── src/Program.cs
│   ├── src/dotnet-api.csproj
│   ├── Dockerfile                # Multi-stage build
│   ├── deploy.sh                 # Build + Push + Deploy
│   └── k8s/
│       ├── namespace.yaml        # dotnet-app namespace
│       ├── deployment.yaml       # 2 replicas · resource limits
│       ├── service.yaml          # ClusterIP
│       ├── ingress.yaml          # /dotnet/* routes
│       └── hpa.yaml              # Min 2 → Max 5 · CPU 70%
│
├── 📂 app-nodejs/                # Node.js 20 Express API
│   ├── src/index.js
│   ├── src/package.json
│   ├── Dockerfile                # Multi-stage alpine build
│   ├── deploy.sh                 # Build + Push + Deploy
│   └── k8s/
│       ├── namespace.yaml        # nodejs-app namespace
│       ├── deployment.yaml       # 2 replicas · resource limits
│       ├── service.yaml          # ClusterIP
│       ├── ingress.yaml          # /nodejs/* routes
│       └── hpa.yaml              # Min 2 → Max 5 · CPU 70%
│
└── 📂 scripts/
    └── init-backend.sh           # Create Azure Storage backend
```

---

## 🛠️ Prerequisites

| Tool | Version | Install |
|---|---|---|
| Terraform | >= 1.10 | `sudo apt install terraform` |
| Azure CLI | Latest | `curl -sL https://aka.ms/InstallAzureCLIDeb \| sudo bash` |
| kubectl | Latest | `az aks install-cli` |
| Helm | >= 3.14 | `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \| bash` |
| Docker | Latest | `sudo apt install docker.io -y` |
| kubelogin | Latest | `curl -LO https://github.com/Azure/kubelogin/releases/latest/download/kubelogin-linux-amd64.zip` |

---

## 🚀 Full Deployment Guide

### 1️⃣ Login to Azure
```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2️⃣ Create Terraform Backend
```bash
./scripts/init-backend.sh
```

### 3️⃣ Deploy Infrastructure
```bash
terraform init -backend-config=environments/dev/backend.conf
terraform plan  -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

### 4️⃣ Connect to AKS
```bash
az aks get-credentials \
  --name aks-aksplatform-dev-weu \
  --resource-group rg-aksplatform-dev-weu \
  --overwrite-existing

# Convert kubeconfig for Azure CLI auth
kubelogin convert-kubeconfig -l azurecli

# Verify
kubectl get nodes
```

### 5️⃣ Install NGINX Ingress
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443

# Verify
kubectl get pods -n ingress-nginx
kubectl get svc  -n ingress-nginx
```

### 6️⃣ Deploy Node.js API
```bash
cd app-nodejs

# Build and push to ACR
az acr update --name acrplatform --default-action Allow
az acr login  --name acrplatform
docker build --network=host -t acrplatform.azurecr.io/nodejs-api:latest .
docker push acrplatform.azurecr.io/nodejs-api:latest

# Deploy to AKS
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml

# Verify
kubectl get pods -n nodejs-app
```

### 7️⃣ Deploy .NET 8 API
```bash
cd app

# Build and push to ACR
docker build --network=host -t acrplatform.azurecr.io/dotnet-api:latest .
docker push acrplatform.azurecr.io/dotnet-api:latest

# Deploy to AKS
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml

# Verify
kubectl get pods -n dotnet-app
```

---

## 🧪 Test Commands

### Port Forward (easiest)
```bash
# Forward NGINX to localhost
kubectl port-forward svc/ingress-nginx-controller 8080:80 -n ingress-nginx
```

### Node.js API
```bash
curl http://localhost:8080/nodejs/api/info
curl http://localhost:8080/nodejs/api/hello?name=Hamida
curl http://localhost:8080/nodejs/api/pods
curl http://localhost:8080/health/live
curl http://localhost:8080/health/ready
```

### .NET 8 API
```bash
curl http://localhost:8080/dotnet/api/info
curl http://localhost:8080/dotnet/api/hello?name=Hamida
curl http://localhost:8080/health/ready
curl http://localhost:8080/swagger
```

### NodePort (direct node access)
```bash
NODE_IP=$(kubectl get nodes -o wide | awk 'NR==2{print $6}')
curl http://$NODE_IP:30080/nodejs/api/info
curl http://$NODE_IP:30080/dotnet/api/info
```

---

## 🔍 Useful kubectl Commands

### Cluster
```bash
kubectl get nodes -o wide                         # Node IPs + status
kubectl top nodes                                 # CPU/Memory usage
kubectl get events --sort-by='.lastTimestamp'     # Recent events
```

### Pods
```bash
kubectl get pods -A                               # All pods all namespaces
kubectl get pods -n nodejs-app                    # Node.js pods
kubectl get pods -n dotnet-app                    # .NET pods
kubectl get pods -n ingress-nginx                 # NGINX pods
kubectl describe pod <pod-name> -n nodejs-app     # Pod details
kubectl logs <pod-name> -n nodejs-app             # Pod logs
kubectl logs -n nodejs-app -l app=nodejs-api      # Logs by label
kubectl exec -it <pod-name> -n nodejs-app -- sh   # Shell into pod
```

### Services & Ingress
```bash
kubectl get svc -A                                # All services
kubectl get ingress -A                            # All ingress rules
kubectl describe ingress -n nodejs-app            # Ingress details
```

### Deployments
```bash
kubectl get deployments -A                                      # All deployments
kubectl rollout status deployment/nodejs-api -n nodejs-app      # Rollout status
kubectl rollout restart deployment/nodejs-api -n nodejs-app     # Restart pods
kubectl scale deployment nodejs-api --replicas=3 -n nodejs-app  # Manual scale
kubectl get hpa -A                                              # Autoscaler status
```

### Debugging
```bash
kubectl get events -n nodejs-app --sort-by='.lastTimestamp'   # Namespace events
kubectl describe pod <pod> -n nodejs-app                       # Full pod details
kubectl logs <pod> -n nodejs-app --previous                    # Crashed pod logs
```

---

## ☁️ Useful Azure CLI Commands

### AKS
```bash
az aks list --output table                         # List clusters
az aks get-credentials --name aks-aksplatform-dev-weu --resource-group rg-aksplatform-dev-weu
az aks show --name aks-aksplatform-dev-weu --resource-group rg-aksplatform-dev-weu
az aks nodepool list --cluster-name aks-aksplatform-dev-weu --resource-group rg-aksplatform-dev-weu
```

### ACR
```bash
az acr list --output table                         # List registries
az acr login --name acrplatform                    # Login
az acr repository list --name acrplatform          # List images
az acr repository show-tags --name acrplatform --repository nodejs-api
az acr build --registry acrplatform --image nodejs-api:latest .  # Build in cloud
```

### Resources
```bash
az resource list --resource-group rg-aksplatform-dev-weu --output table
az group show --name rg-aksplatform-dev-weu
```

---

## 🔒 Security Features

| Feature | Details |
|---|---|
| 🛡️ WAF | OWASP 3.1 · Custom rules · Detection/Prevention mode |
| 🔒 Private Endpoints | ACR + Key Vault not exposed to internet |
| 🪪 Workload Identity | Pods authenticate to Azure without passwords |
| 👥 AAD RBAC | Azure AD integration for kubectl access |
| 🕸️ Calico | Pod-level network policies — east-west traffic control |
| 🚧 NSGs | Only App Gateway can reach AKS nodes |
| 🔑 Key Vault CSI | Secrets mounted as files — never in env vars |
| 🙅 Non-root | All containers run as UID 1000 |
| 🏗️ CNI Overlay | Pod IPs internal — not routable from outside VNet |

---

## 📡 API Endpoints Reference

### Node.js API (`/nodejs/*`)
| Method | Path | Description |
|---|---|---|
| GET | `/nodejs/api/info` | Service info, hostname, uptime |
| GET | `/nodejs/api/hello?name=X` | Hello endpoint |
| GET | `/nodejs/api/pods` | Pod name + memory usage |
| GET | `/health/live` | Liveness probe |
| GET | `/health/ready` | Readiness probe |

### .NET 8 API (`/dotnet/*`)
| Method | Path | Description |
|---|---|---|
| GET | `/dotnet/api/info` | Service info, .NET version |
| GET | `/dotnet/api/hello?name=X` | Hello endpoint |
| GET | `/health/live` | Liveness probe |
| GET | `/health/ready` | Readiness probe |
| GET | `/swagger` | Swagger UI |

---

## 💰 Cost Estimate

| Resource | Cost/hour | Cost/day |
|---|---|---|
| AKS (2× D2s_v3) | ~$0.19 | ~$4.56 |
| App Gateway v2 + WAF | ~$0.35 | ~$8.40 |
| ACR Premium | ~$0.007 | ~$0.17 |
| Key Vault | ~$0.001 | ~$0.02 |
| Log Analytics | ~$0.002 | ~$0.05 |
| **Total** | **~$0.55/hr** | **~$13.20/day** |

```bash
# Destroy when not using
terraform destroy -var-file=environments/dev/terraform.tfvars

# Recreate when needed (~20 min)
terraform apply -var-file=environments/dev/terraform.tfvars
```

---

## 🔄 Terraform Commands

```bash
# Init
terraform init -backend-config=environments/dev/backend.conf

# Plan
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply
terraform apply -var-file=environments/dev/terraform.tfvars

# Destroy
terraform destroy -var-file=environments/dev/terraform.tfvars

# State
terraform state list
terraform state show module.aks.azurerm_kubernetes_cluster.main

# Import existing resource
terraform import -var-file=environments/dev/terraform.tfvars \
  azurerm_resource_group.main \
  /subscriptions/SUB_ID/resourceGroups/rg-aksplatform-dev-weu
```

---

## 🌿 Module Reference

| Module | Resources | Key Outputs |
|---|---|---|
| `networking` | VNet · 3 Subnets · 2 NSGs | `subnet_ids` · `vnet_id` |
| `acr` | Container Registry · Private Endpoint | `acr_id` · `login_server` |
| `keyvault` | Key Vault · Private Endpoint | `keyvault_id` · `keyvault_uri` |
| `monitoring` | Log Analytics · App Insights | `log_analytics_id` · `app_insights_key` |
| `aks` | Cluster · System Pool · User Pool | `host` · `cluster_name` |
| `nginx` | NGINX Ingress via Helm | `ingress_ip` |
| `waf` | App Gateway · WAF Policy · Public IP | `public_ip_address` |

---

## 👤 Author

Built as **Senior DevOps Engineer Interview Project**

> **Stack:** Azure · Terraform · AKS · Kubernetes · NGINX · .NET 8 · Node.js · Helm · WAF · GitOps
>
> **Key concepts demonstrated:** IaC · Private networking · Zero-trust security · Multi-app ingress · Autoscaling · Observability
