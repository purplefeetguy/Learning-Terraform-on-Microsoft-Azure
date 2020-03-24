terraform {
  backend "azurerm" {
    resource_group_name   = "pfltstaterg"
    storage_account_name  = "pfltstatestor"
    container_name        = "tstate"
    key                   = "terraform.tfstate"
  }
}
