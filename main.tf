
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "subscription_id" {}
variable "web_server_location" {}
variable "web_server_rg" {}
variable "resource_prefix" {}
variable "web_server_address_space" {}
variable "web_server_name" {}
variable "environment" {}
variable "web_server_count" {}
variable "web_server_subnets" {
    type = "list"
}
variable "terraform_script_version" {}




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

locals {
  web_server_name = "${var.environment == "production" ? "${var.web_server_name}-prd" : "${var.web_server_name}-dev"}"
  build_environment = "${var.environment == "production" ? "production" : "development"}"
}

resource "azurerm_resource_group" "web_server_rg" {
    name     = "${var.web_server_rg}"
    location = "${var.web_server_location}"

tags {
    environment = "${local.build_environment}"
    build-version = "${var.terraform_script_version}"
    }
}

resource "azurerm_virtual_network" "web_server_vnet" {
  name                = "${var.resource_prefix}-vnet"
  location            = "${var.web_server_location}"
  resource_group_name = "${azurerm_resource_group.web_server_rg.name}"
  address_space       = ["${var.web_server_address_space}"]
}

resource "azurerm_subnet" "web_server_subnet" {
  name                      = "${var.resource_prefix}-subnet-${substr(var.web_server_subnets[count.index], 0, length(var.web_server_subnets[count.index]) - 3)}"
  resource_group_name       = "${azurerm_resource_group.web_server_rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.web_server_vnet.name}"
  address_prefix            = "${var.web_server_subnets[count.index]}"
  network_security_group_id = "${azurerm_network_security_group.web_server_nsg.id}"
  count                     = "${length(var.web_server_subnets)}"
}

# resource "azurerm_network_interface" "web_server_nic" {
#   name                = "${var.web_server_name}-nic-${format("%02d",count.index)}"
#   location            = "${var.web_server_location}"
#   resource_group_name = "${azurerm_resource_group.web_server_rg.name}"
#   count               = "${var.web_server_count}"

#   ip_configuration {
#       name                          = "${var.web_server_name}-ip-${format("%02d",count.index)}"
#       subnet_id                     = "${azurerm_subnet.web_server_subnet.*.id[count.index]}"
#       private_ip_address_allocation = "dynamic"
#       public_ip_address_id          = "${azurerm_public_ip.web_server_public_ip.*.id[count.index]}"
#   }
# }

# resource "azurerm_public_ip" "web_server_public_ip" {
#     name                         = "${var.web_server_name}-public-ip-${format("%02d",count.index)}"
#     location                     = "${var.web_server_location}"
#     resource_group_name          = "${azurerm_resource_group.web_server_rg.name}"
#     allocation_method            = "${var.environment == "production" ? "Static" : "Dynamic"}"
#     count                        = "${var.web_server_count}"
# }

resource "azurerm_public_ip" "web_server_public_ip" {
    name                         = "${var.resource_prefix}-public-ip"
    location                     = "${var.web_server_location}"
    resource_group_name          = "${azurerm_resource_group.web_server_rg.name}"
    allocation_method            = "${var.environment == "production" ? "Static" : "Dynamic"}"
    count                        = "${var.web_server_count}"
}

resource "azurerm_network_security_group" "web_server_nsg" {
    name                         = "${var.resource_prefix}-nsg"
    location                     = "${var.web_server_location}"
    resource_group_name          = "${azurerm_resource_group.web_server_rg.name}"    
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
    name                        = "RDP Inbound"
    priority                    = 100
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "TCP"
    source_port_range           = "*"
    destination_port_range      = "3389"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = "${azurerm_resource_group.web_server_rg.name}"
    network_security_group_name = "${azurerm_network_security_group.web_server_nsg.name}"
    count                       = "${var.environment == "production" ? 1 : 0 }"
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_ssh" {
    name                        = "SSH Inbound"
    priority                    = 101
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "TCP"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = "${azurerm_resource_group.web_server_rg.name}"
    network_security_group_name = "${azurerm_network_security_group.web_server_nsg.name}"
    count                       = "${var.environment == "production" ? 1 : 0 }"
}

resource "azurerm_virtual_machine_scale_set" "web_server" {
    name                         = "${local.web_server_name}-scale-set"
    location                     = "${var.web_server_location}"
    resource_group_name          = "${azurerm_resource_group.web_server_rg.name}"
    upgrade_policy_mode          = "manual"

    sku {
        name = "Standard_B1s"
        tier = "Standard"
        capacity = "${var.web_server_count}"
    }

    storage_profile_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter-Server-Core-smalldisk"
        version   = "2016.127.20190416"
    }

    # storage_image_reference {
    #     publisher = "Canonical"
    #     offer     = "UbuntuServer"
    #     sku       = "18.04-LTS"
    #     version   = "latest"
    # }

    storage_profile_os_disk {
        name              = ""
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name_prefix  = "${local.web_server_name}"
        admin_username        = "webserver"
        admin_password        = "Passw0rd123!"
    }

    network_profile {
        name    = "web_server_network_profile"
        primary = true

        ip_configuration {
            name      = "${local.web_server_name}"
            primary   = true
            subnet_id = "${azurerm_subnet.web_server_subnet.*.id[0]}"
        }
    }


    os_profile_windows_config {

    }

    # os_profile_linux_config {
    #     disable_password_authentication = false
    # }

}

# resource "azurerm_availability_set" "web_server_availability_set" {
#       name                        = "${var.resource_prefix}-availability-set"
#       location                    = "${var.web_server_location}"
#       resource_group_name         = "${azurerm_resource_group.web_server_rg.name}"
#       managed                     = true
#       platform_fault_domain_count = 2
# }

