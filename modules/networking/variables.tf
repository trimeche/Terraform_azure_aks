# ============================================================
#  modules/networking/variables.tf
# ============================================================

variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "environment"         { type = string }
variable "project"             { type = string }
variable "vnet_name"           { type = string }
variable "vnet_address_space"  { type = list(string) }
variable "tags"                { type = map(string) }

variable "subnet_cidrs" {
  description = "CIDR per subnet key: appgw | aks_nodes | aks_pods | private_endpoints"
  type        = map(string)
}
