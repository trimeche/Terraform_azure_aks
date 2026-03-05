variable "resource_group_name"    { type = string }
variable "location"               { type = string }
variable "cluster_name"           { type = string }
variable "kubernetes_version"     { type = string }
variable "node_subnet_id"         { type = string }
variable "acr_id"                 { type = string }
variable "keyvault_id"            { type = string }
variable "log_analytics_id"       { type = string }
variable "admin_group_object_ids" { type = list(string) }
variable "tenant_id"              { type = string }
variable "tags"                   { type = map(string) }

variable "system_node_pool" {
  type = object({
    vm_size    = string
    node_count = number
    min_count  = number
    max_count  = number
    os_disk_gb = number
  })
}

variable "user_node_pool" {
  type = object({
    vm_size    = string
    node_count = number
    min_count  = number
    max_count  = number
    os_disk_gb = number
  })
}
