# ============================================================
#  modules/aks/main.tf
#  Creates: AKS cluster + System pool + User pool
#  NOTE: NGINX Ingress is installed separately in modules/nginx
#        to avoid circular dependency with helm/kubernetes providers
# ============================================================

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  kubernetes_version  = var.kubernetes_version
  dns_prefix          = var.cluster_name
  tags                = var.tags
  sku_tier            = "Standard"

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_pool.vm_size
    node_count                   = var.system_node_pool.node_count
    min_count                    = var.system_node_pool.min_count
    max_count                    = var.system_node_pool.max_count
    enable_auto_scaling          = true
    os_disk_size_gb              = var.system_node_pool.os_disk_gb
    vnet_subnet_id               = var.node_subnet_id
    only_critical_addons_enabled = true

    node_labels = {
      "nodepool-type" = "system"
    }

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
    tenant_id              = var.tenant_id
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_id
  }

  automatic_channel_upgrade = "patch"

  maintenance_window {
    allowed {
      day   = "Saturday"
      hours = [2, 4]
    }
  }
}

# Grant AKS kubelet: pull images from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}

# Grant AKS identity: read secrets from Key Vault
resource "azurerm_role_assignment" "aks_kv_secrets" {
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = var.keyvault_id
}

# User node pool
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_node_pool.vm_size
  node_count            = var.user_node_pool.node_count
  min_count             = var.user_node_pool.min_count
  max_count             = var.user_node_pool.max_count
  enable_auto_scaling   = true
  os_disk_size_gb       = var.user_node_pool.os_disk_gb
  vnet_subnet_id        = var.node_subnet_id
  tags                  = var.tags

  node_labels = {
    "nodepool-type" = "user"
    "workload"      = "application"
  }
}
