output "public_ip_address" { value = azurerm_public_ip.appgw.ip_address }
output "appgw_id"          { value = azurerm_application_gateway.main.id }
output "waf_policy_id"     { value = azurerm_web_application_firewall_policy.main.id }
