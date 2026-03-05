# AKS Platform 🚀

A production-ready Kubernetes platform on Azure — built with Terraform, secured with WAF, and tested with a Node.js API.


> [!NOTE]
> The demo uses a **Node.js API** for testing purposes — running on **$200 Azure free credits**.
> The production architecture is designed for any containerized app (.NET, Java, Python, etc.)
> NGINX Ingress is the core routing component — Node.js is just the test vehicle.

---

## The idea

One AKS cluster, one NGINX Ingress, one app — but built the right way:

```
Internet → Azure DNS → WAF + App Gateway
              └── VNet (10.0.0.0/8)
                    └── NGINX Ingress (NodePort :30080)
                              └── /nodejs/* → Node.js 20 API
```

The app pulls its image from a private ACR, reads secrets from Key Vault, and sends logs to Application Insights — all without storing any credentials anywhere.

---

## Architecture

```
                    🌐 Internet
                         │
                    🔵 Azure DNS
                         │
                  🛡️ WAF + App Gateway
                    OWASP 3.1 · SSL
                         │
    ╔════════════════════▼════════════════════╗
    ║           VNet 10.0.0.0/8              ║
    ║                                        ║
    ║   snet-appgw      10.1.0.0/24         ║
    ║   snet-aks-nodes  10.2.0.0/16         ║
    ║   snet-pe         10.4.0.0/24         ║
    ║                                        ║
    ║      [ NGINX Ingress :30080 ]         ║
    ║                  │                    ║
    ║         [Node.js 2 pods]             ║
    ║          ×2 · HPA 2-5 pods           ║
    ║                                        ║
    ║   PE → ACR      PE → Key Vault        ║
    ╚════════════════════════════════════════╝
              │                │
           📦 ACR           🔑 Key Vault
       (store images)    (store secrets)

    📊 Log Analytics + Application Insights
```

---

## Stack

| Layer | Technology |
|---|---|
| Infrastructure | Terraform 1.10+ |
| Cloud | Azure (West Europe) |
| Kubernetes | AKS 1.30 |
| Ingress | NGINX (Helm) |
| Security | WAF v2 · OWASP 3.1 · Calico · NSGs |
| Registry | Azure Container Registry (Premium) |
| Secrets | Azure Key Vault + CSI Driver |
| Observability | Log Analytics + Application Insights |
| Test app | Node.js 20 Express |

---

## Getting started

### 1. Login
```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. Deploy infrastructure
```bash
terraform init -backend-config=environments/dev/backend.conf
terraform apply -var-file=environments/dev/terraform.tfvars
```

### 3. Connect to cluster
```bash
az aks get-credentials \
  --name aks-aksplatform-dev-weu \
  --resource-group rg-aksplatform-dev-weu

kubelogin convert-kubeconfig -l azurecli
kubectl get nodes
```

### 4. Install NGINX
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080
```

### 5. Deploy Node.js app
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
```

### 6. Test
```bash
kubectl port-forward svc/ingress-nginx-controller 8080:80 -n ingress-nginx

curl http://localhost:8080/nodejs/api/info
curl http://localhost:8080/nodejs/api/hello?name=Hamida
curl http://localhost:8080/health/live
```

---

## API endpoints

```bash
curl http://localhost:8080/nodejs/api/info          # service info + hostname
curl http://localhost:8080/nodejs/api/hello?name=X  # hello endpoint
curl http://localhost:8080/nodejs/api/pods          # pod name + memory
curl http://localhost:8080/health/live              # liveness probe
curl http://localhost:8080/health/ready             # readiness probe
```

---

## Day-to-day commands

### Check what's running
```bash
kubectl get pods -A
kubectl get svc  -n ingress-nginx
kubectl get ingress -n nodejs-app
kubectl top nodes
```

### Debug a pod
```bash
kubectl logs -n nodejs-app -l app=nodejs-api
kubectl describe pod <pod-name> -n nodejs-app
kubectl exec -it <pod-name> -n nodejs-app -- sh
```

### Redeploy after a code change
```bash
docker build --network=host -t acrplatform.azurecr.io/nodejs-api:latest .
docker push acrplatform.azurecr.io/nodejs-api:latest
kubectl rollout restart deployment/nodejs-api -n nodejs-app
kubectl rollout status deployment/nodejs-api -n nodejs-app
```

### Scale manually
```bash
kubectl scale deployment nodejs-api --replicas=4 -n nodejs-app
```

### Destroy everything (save credits 💰)
```bash
terraform destroy -var-file=environments/dev/terraform.tfvars
```

---

## Security highlights

- **WAF** blocks SQLi, XSS and common attacks (OWASP 3.1)
- **Private Endpoints** — ACR and Key Vault have no public internet access
- **Workload Identity** — pods authenticate to Azure with no passwords
- **Calico** — controls pod-to-pod traffic inside the cluster
- **NSGs** — only App Gateway can reach AKS nodes
- **Non-root containers** — all pods run as UID 1000

---

## Cost

> [!WARNING]
> This project runs on **$200 Azure free credits**. Running 24/7 costs ~$0.55/hour (~$13/day).

```bash
# End of day — destroy to save credits
terraform destroy -var-file=environments/dev/terraform.tfvars

# Next morning — recreate in ~20 min
terraform apply -var-file=environments/dev/terraform.tfvars
```

> [!TIP]
> App Gateway alone costs ~$0.35/hr. Destroying overnight saves ~$2.80 per night.

---

## Project structure

```
aks-platform/
├── main.tf, variables.tf, locals.tf, outputs.tf, versions.tf
├── modules/
│   ├── networking/   VNet + subnets + NSGs
│   ├── acr/          Container registry
│   ├── keyvault/     Secrets store
│   ├── monitoring/   Logs + APM
│   ├── aks/          Kubernetes cluster
│   ├── nginx/        Ingress controller
│   └── waf/          Web application firewall
├── environments/
│   ├── dev/          Small nodes · detection mode
│   └── prod/         Larger nodes · prevention mode
└── app-nodejs/       Node.js test app + k8s manifests
```

---

Made with ☕ and too many `terraform apply` retries.
