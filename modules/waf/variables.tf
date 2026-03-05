variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "appgw_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "backend_ip_address" {
  type = string
}

variable "keyvault_id" {
  type = string
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
}
