# Azure Text Analytics (Cognitive Services) for support-conversation sentiment.

resource "azurerm_resource_group" "cloudmart" {
  name     = "${var.project_name}-rg"
  location = var.location
}

resource "azurerm_cognitive_account" "text_analytics" {
  name                = "${var.project_name}-text-analytics"
  location            = azurerm_resource_group.cloudmart.location
  resource_group_name = azurerm_resource_group.cloudmart.name
  kind                = "TextAnalytics"
  sku_name            = "F0"
}
