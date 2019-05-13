
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "subscription_id" {}

variable "web_server_location" {}
variable "web_server_rg" {}
variable "resource_prefix" {}
variable "web_server_address_space" {}
variable "web_server_address_prefix" {}
variable "web_server_name" {}


provider "azurerm" {
    version         = "1.27.0"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"
    tenant_id       = "${var.tenant_id}"
    subscription_id = "${var.subscription_id}"
}

# provider "azurerm" {
#     version         = "1.27.0"
#     client_id       = "e5653f3d-a55e-474d-8386-c511590722e8"
#     client_secret   = "IA72SU=wUdlqeJ[:tilteE-pNICuXe41"
#     tenant_id       = "b82a4829-cdd4-48de-b142-985c68d41b4c"
#     subscription_id = "0b55b4c7-3322-4eb8-988a-0cda8f823217"
# }

resource "azurerm_resource_group" "web_server_rg" {
    name     = "${var.web_server_rg}"
    location = "${var.web_server_location}"
}

resource "azurerm_virtual_network" "web_server_vnet" {
  name                = "${var.resource_prefix}-vnet"
  location            = "${var.web_server_location}"
  resource_group_name = "${azurerm_resource_group.web_server_rg.name}"
  address_space       = ["${var.web_server_address_space}"]
}

resource "azurerm_subnet" "web_server_subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = "${azurerm_resource_group.web_server_rg.name}"
  virtual_network_name = "${azurerm_virtual_network.web_server_vnet.name}"
  address_prefix       = "${var.web_server_address_prefix}"
}

resource "azurerm_network_interface" "web_server_nic" {
  name                = "${var.web_server_name}-nic"
  location            = "${var.web_server_location}"
  resource_group_name = "${azurerm_resource_group.web_server_rg.name}"

  ip_configuration {
      name                          = "${var.web_server_name}-ip"
      subnet_id                     = "${azurerm_subnet.web_server_subnet.id}"
      private_ip_address_allocation = "dynamic"
  }
}


