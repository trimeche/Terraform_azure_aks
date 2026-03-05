# ============================================================
#  main.tf  — Module orchestration
#  Order: networking → acr → keyvault → monitoring → aks → nginx → waf
# ============================================================

data "azurerm_client_config" "current" {}

# ── 0. Resource Group ─────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.location
  tags     = local.tags
}

# ── 1. Networking ─────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project             = var.project
  vnet_name           = local.vnet_name
  vnet_address_space  = var.vnet_address_space
  subnet_cidrs        = var.subnet_cidrs
  tags                = local.tags
}

# ── 2. ACR ────────────────────────────────────────────────────
module "acr" {
  source = "./modules/acr"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  acr_name                   = local.acr_name
  private_endpoint_subnet_id = module.networking.subnet_ids["private_endpoints"]
  vnet_id                    = module.networking.vnet_id
  tags                       = local.tags
}

# ── 3. Key Vault ──────────────────────────────────────────────
module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  keyvault_name              = local.kv_name
  private_endpoint_subnet_id = module.networking.subnet_ids["private_endpoints"]
  vnet_id                    = module.networking.vnet_id
  tags                       = local.tags
}

# ── 4. Monitoring ─────────────────────────────────────────────
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  law_name            = local.law_name
  tags                = local.tags
}

# ── 5. AKS Cluster ────────────────────────────────────────────
module "aks" {
  source = "./modules/aks"

  resource_group_name    = azurerm_resource_group.main.name
  location               = var.location
  cluster_name           = local.aks_name
  kubernetes_version     = var.kubernetes_version
  node_subnet_id         = module.networking.subnet_ids["aks_nodes"]
  system_node_pool       = var.system_node_pool
  user_node_pool         = var.user_node_pool
  acr_id                 = module.acr.acr_id
  keyvault_id            = module.keyvault.keyvault_id
  log_analytics_id       = module.monitoring.log_analytics_id
  admin_group_object_ids = var.admin_group_object_ids
  tenant_id              = data.azurerm_client_config.current.tenant_id
  tags                   = local.tags
}

# ── 6. NGINX Ingress (Helm) ───────────────────────────────────
# Separate module to avoid circular dependency with helm provider
# #module "nginx" {
# #  source = "./modules/nginx"
# 
# #  depends_on = [module.aks]
# #}
# 
# # ── 7. WAF + Application Gateway ──────────────────────────────
# # Created LAST — needs NGINX Ingress IP as backend
# module "waf" {
#   source = "./modules/waf"
# 
#   resource_group_name = azurerm_resource_group.main.name
#   location            = var.location
#   appgw_name          = local.appgw_name
#   subnet_id           = module.networking.subnet_ids["appgw"]
#   backend_ip_address  = "10.2.0.0"
#   keyvault_id         = module.keyvault.keyvault_id
#   waf_mode            = var.waf_mode
#   domain_name         = var.domain_name
#   tags                = local.tags
# }
