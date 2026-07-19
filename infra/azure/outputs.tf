output "endpoint" {
  value = azurerm_cognitive_account.text_analytics.endpoint
}

output "primary_key" {
  value     = azurerm_cognitive_account.text_analytics.primary_access_key
  sensitive = true
}
