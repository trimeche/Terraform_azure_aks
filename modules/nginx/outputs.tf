output "ingress_ip" {
  description = "NGINX Ingress LoadBalancer IP — used by WAF as backend"
  value       = data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
}
