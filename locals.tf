# ============================================================
#  locals.tf  —  Computed values + naming convention
#  Pattern: <type>-<project>-<env>-<region_short>
# ============================================================

locals {

  # ── Short region code ──────────────────────────────────────
  region_map = {
    "westeurope"     = "weu"
    "northeurope"    = "neu"
    "eastus"         = "eus"
    "eastus2"        = "eus2"
    "westus"         = "wus"
    "francecentral"  = "frc"
    "uksouth"        = "uks"
  }
  region_short = lookup(local.region_map, var.location, substr(var.location, 0, 4))

  # ── Common name prefix ─────────────────────────────────────
  # Example: aksplatform-dev-weu
  name_prefix = "${var.project}-${var.environment}-${local.region_short}"

  # ── Resource names ─────────────────────────────────────────
  rg_name      = "rg-${local.name_prefix}"
  vnet_name    = "vnet-${local.name_prefix}"
  aks_name     = "aks-${local.name_prefix}"
  acr_name     = "acr${replace(local.name_prefix, "-", "")}"  # no hyphens
  kv_name      = "kv-${local.name_prefix}"
  appgw_name   = "appgw-${local.name_prefix}"
  law_name     = "law-${local.name_prefix}"  # Log Analytics Workspace

  # ── Merged tags (add computed values) ─────────────────────
  tags = merge(var.tags, {
    Environment = var.environment
    Location    = var.location
  })
}
