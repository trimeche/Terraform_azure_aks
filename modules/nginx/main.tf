# ============================================================
#  modules/nginx/main.tf
#  Installs NGINX Ingress Controller via Helm
#  Separated from modules/aks to avoid circular dependency:
#    helm provider needs AKS → AKS module can't use helm provider
# ============================================================

resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.9.1"
  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.replicaCount"
    value = "2"
  }

  # Internal LoadBalancer — only reachable from App Gateway, not internet
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal"
    value = "true"
  }

  set {
    name  = "controller.nodeSelector.nodepool-type"
    value = "user"
  }
}

# Read the LoadBalancer IP assigned by Azure to NGINX
data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
  depends_on = [helm_release.nginx_ingress]
}
