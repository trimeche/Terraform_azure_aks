# ============================================================
#  variables.tf  — Root variables
# ============================================================

variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be: dev | staging | prod"
  }
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "project" {
  type    = string
  default = "aksplatform"
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/8"]
}

# Only 3 subnets now — aks_pods removed (not needed with CNI Overlay)
variable "subnet_cidrs" {
  type = map(string)
  default = {
    appgw             = "10.1.0.0/24"
    aks_nodes         = "10.2.0.0/16"
    private_endpoints = "10.4.0.0/24"
  }
}

variable "kubernetes_version" {
  type    = string
  default = "1.30"
}

variable "system_node_pool" {
  type = object({
    vm_size    = string
    node_count = number
    min_count  = number
    max_count  = number
    os_disk_gb = number
  })
  default = {
    vm_size    = "Standard_D2s_v3"
    node_count = 2
    min_count  = 2
    max_count  = 3
    os_disk_gb = 60
  }
}

variable "user_node_pool" {
  type = object({
    vm_size    = string
    node_count = number
    min_count  = number
    max_count  = number
    os_disk_gb = number
  })
  default = {
    vm_size    = "Standard_D4s_v3"
    node_count = 2
    min_count  = 1
    max_count  = 5
    os_disk_gb = 100
  }
}

variable "admin_group_object_ids" {
  type      = list(string)
  default   = []
  sensitive = true
}

variable "waf_mode" {
  type    = string
  default = "Prevention"
}

variable "domain_name" {
  type    = string
  default = ""
}

variable "tags" {
  type = map(string)
  default = {
    ManagedBy  = "Terraform"
    Project    = "AKS-Platform"
    CostCenter = "Engineering"
  }
}
