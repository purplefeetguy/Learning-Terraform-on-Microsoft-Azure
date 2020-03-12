provider "azurerm" {
  version         = "~> 1.0"
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "web_server_rg" {
  name = var.web_server_rg
  location = var.web_server_location
}