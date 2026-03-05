# ============================================================
#  environments/prod/terraform.tfvars
# ============================================================

environment        = "prod"
location           = "westeurope"
project            = "aksplatform"
kubernetes_version = "1.28"
waf_mode           = "Prevention"   # Always Prevention in prod
domain_name        = "api.myapp.com"

vnet_address_space = ["10.0.0.0/8"]

subnet_cidrs = {
  appgw             = "10.1.0.0/24"
  aks_nodes         = "10.2.0.0/16"
  aks_pods          = "10.3.0.0/16"
  private_endpoints = "10.4.0.0/24"
}

system_node_pool = {
  vm_size    = "Standard_D2s_v3"
  node_count = 2
  min_count  = 2
  max_count  = 3
  os_disk_gb = 60
}

user_node_pool = {
  vm_size    = "Standard_D4s_v3"
  node_count = 2
  min_count  = 2
  max_count  = 10
  os_disk_gb = 100
}

admin_group_object_ids = []  # replace with your Azure AD group ID

tags = {
  ManagedBy   = "Terraform"
  Project     = "AKS-Platform"
  Environment = "prod"
  CostCenter  = "Engineering"
}
