
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
variable "domain_name_label" {}


provider "azurerm" {
    version         = "1.27.0"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"
    tenant_id       = "${var.tenant_id}"
    subscription_id = "${var.subscription_id}"
}


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
  network_security_group_id = "${count.index == 0 ? "${azurerm_network_security_group.web_server_nsg.id}" : ""}"
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

resource "azurerm_public_ip" "web_server_lb_public_ip" {
    name                         = "${var.resource_prefix}-public-ip"
    location                     = "${var.web_server_location}"
    resource_group_name          = "${azurerm_resource_group.web_server_rg.name}"
    allocation_method            = "${var.environment == "production" ? "Static" : "Dynamic"}"
    domain_name_label            = "${var.domain_name_label}"
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
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_http" {
    name                        = "RDP Inbound"
    priority                    = 102
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "TCP"
    source_port_range           = "*"
    destination_port_range      = "80"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = "${azurerm_resource_group.web_server_rg.name}"
    network_security_group_name = "${azurerm_network_security_group.web_server_nsg.name}"
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
            name                                   = "${local.web_server_name}"
            primary                                = true
            subnet_id                              = "${azurerm_subnet.web_server_subnet.*.id[0]}"
            load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.web_server_lb_backend_pool.id}"]
        }
    }

    os_profile_windows_config {
        provision_vm_agent = true
    }

    # os_profile_linux_config {
    #     disable_password_authentication = false
    # }

    extension {
        name                 = "${local.web_server_name}-extension"
        publisher            = "Microsoft.Compute"
        type                 = "CustomScriptExtension"
        type_handler_version = "1.9"

        settings = <<SETTINGS
        {
            "fileUris": ["https://raw.githubusercontent.com/eltimmo/learning/master/azureInstallWebServer.ps1"],
            "commandToExecute": "start powershell -ExecutionPolicy Unrestricted -File azureInstallWebServer.ps1"
        }
        SETTINGS

    }

}

# resource "azurerm_availability_set" "web_server_availability_set" {
#       name                        = "${var.resource_prefix}-availability-set"
#       location                    = "${var.web_server_location}"
#       resource_group_name         = "${azurerm_resource_group.web_server_rg.name}"
#       managed                     = true
#       platform_fault_domain_count = 2
# }

resource "azurerm_lb" "web_server_lb" {
    name                         = "${var.resource_prefix}-lb"
    location                     = "${var.web_server_location}"
    resource_group_name          = "${azurerm_resource_group.web_server_rg.name}"  

    frontend_ip_configuration {
        name                     = "${var.resource_prefix}-lb-frontend-ip"
        public_ip_address_id     = "${azurerm_public_ip.web_server_lb_public_ip.id}"
    }
}

resource "azurerm_lb_backend_address_pool" "web_server_lb_backend_pool" {
    name                = "${var.resource_prefix}-lb-backend-pool"
    resource_group_name = "${azurerm_resource_group.web_server_rg.name}"
    loadbalancer_id     = "${azurerm_lb.web_server_lb.id}"
}

resource "azurerm_lb_probe" "web_server_lb_http_probe" {
    name                = "${var.resource_prefix}-lb-http-probe"
    resource_group_name = "${azurerm_resource_group.web_server_rg.name}"
    loadbalancer_id     = "${azurerm_lb.web_server_lb.id}"
    protocol            = "tcp"
    port                = "80"
}

resource "azurerm_lb_rule" "web_server_lb_http_rule" {
    name                           = "${var.resource_prefix}-lb-http-probe"
    resource_group_name            = "${azurerm_resource_group.web_server_rg.name}"
    loadbalancer_id                = "${azurerm_lb.web_server_lb.id}"
    protocol                       = "tcp"
    frontend_port                  = "80"
    backend_port                   = "80"
    frontend_ip_configuration_name = "${var.resource_prefix}-lb-frontend-ip"
    probe_id                       = "${azurerm_lb_probe.web_server_lb_http_probe.id}"
    backend_address_pool_id        = "${azurerm_lb_backend_address_pool.web_server_lb_backend_pool.id}"
}




