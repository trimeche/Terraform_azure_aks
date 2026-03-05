#!/bin/bash
# ============================================================
#  deploy.sh — Build + Push + Deploy Node.js API to AKS
# ============================================================

set -euo pipefail

ACR_NAME="acraksplatformdevweu"
IMAGE_NAME="nodejs-api"
TAG="${1:-latest}"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   Deploying Node.js API to AKS       ║"
echo "╚══════════════════════════════════════╝"
echo ""

echo "► Step 1: Login to ACR"
az acr login --name $ACR_NAME

echo "► Step 2: Build Docker image"
docker build -t $ACR_NAME.azurecr.io/$IMAGE_NAME:$TAG .

echo "► Step 3: Push to ACR"
docker push $ACR_NAME.azurecr.io/$IMAGE_NAME:$TAG

echo "► Step 4: Deploy manifests to AKS"
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml

echo "► Step 5: Wait for rollout"
kubectl rollout status deployment/nodejs-api -n nodejs-app --timeout=120s

echo ""
echo "✅ Deployment complete!"
echo ""

NGINX_IP=$(kubectl get svc ingress-nginx-controller \
  -n ingress-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "PENDING")

echo "► Test your API:"
echo "   curl http://$NGINX_IP/nodejs/api/info"
echo "   curl http://$NGINX_IP/nodejs/api/hello?name=Hamida"
echo "   curl http://$NGINX_IP/health/live"
echo ""
kubectl get pods -n nodejs-app
