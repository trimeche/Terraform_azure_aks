# ============================================================
#  modules/acr/main.tf
#  Creates: Azure Container Registry + Private Endpoint
# ============================================================

resource "azurerm_container_registry" "main" {
  name                          = var.acr_name
  public_network_access_enabled = true   # allow public for pushing
  #network_rule_default_action   = "Deny" #  but deny by default
  sku                 = "Premium"
  resource_group_name = var.resource_group_name
  location            = var.location

  network_rule_set {
    default_action = "Deny"

    ip_rule {
      action   = "Allow"
      ip_range = "197.15.113.25/32"  #  only My IP
    }
  }
}

# ── Private DNS Zone for ACR ──────────────────────────────────
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "acr-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

# ── Private Endpoint ──────────────────────────────────────────
resource "azurerm_private_endpoint" "acr" {
  name                = "pe-${var.acr_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-acr"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }
}
