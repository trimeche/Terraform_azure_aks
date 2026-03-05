output "log_analytics_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "app_insights_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}

output "app_insights_conn_string" {
  value     = azurerm_application_insights.main.connection_string
  sensitive = true
}
