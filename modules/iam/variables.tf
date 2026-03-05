# ============================================================
#  modules/iam/variables.tf
# ============================================================

variable "environment"          { type = string }
variable "project"              { type = string }
variable "resource_group_name"  { type = string }
variable "subscription_id"      { type = string }

# AKS references
variable "aks_cluster_id"        { type = string }
variable "aks_kubelet_object_id" { type = string }
variable "aks_identity_id"       { type = string }

# Resource references
variable "acr_id"        { type = string }
variable "keyvault_id"   { type = string }
variable "law_id"        { type = string }  # Log Analytics Workspace

variable "tags"  { type = map(string) }
