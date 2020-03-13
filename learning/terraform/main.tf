provider "azurerm" {
  version         = "=1.44.0"
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "web_server_rg" {
  name     = var.web_server_rg
  location = var.web_server_location
}

resource "azurerm_virtual_network" "web_server_vnet" {
  name                = "${var.resource_prefix}-vnet"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  address_space       = [var.web_server_address_space]
}

resource "azurerm_subnet" "web_server_subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.web_server_rg.name
  virtual_network_name = azurerm_virtual_network.web_server_vnet.name
  address_prefix       = var.web_server_address_prefix
}

resource "azurerm_network_interface" "web_server_nic" {
  name                = "${var.web_server_name}-nic"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name

  ip_configuration {
    name                          = "${var.web_server_name}-ip"
    subnet_id                     = azurerm_subnet.web_server_subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.web_server_public_ip.id
  }
}

resource "azurerm_public_ip" "web_server_public_ip" {
  name                = "${var.web_server_name}-public-ip"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  allocation_method   = var.environment == "production" ? "Static" : "Dynamic"
}

resource "azurerm_network_security_group" "web_server_nsg" {
  name                = "${var.web_server_name}-nsg"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
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
  resource_group_name         = azurerm_resource_group.web_server_rg.name
  network_security_group_name = azurerm_network_security_group.web_server_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "web_server_subnet_nsg" {
  subnet_id                 = azurerm_subnet.web_server_subnet.id
  network_security_group_id = azurerm_network_security_group.web_server_nsg.id
}

resource "azurerm_virtual_machine" "web_server" {
  name                  = var.web_server_name
  location              = var.web_server_location
  resource_group_name   = azurerm_resource_group.web_server_rg.name
  network_interface_ids = [azurerm_network_interface.web_server_nic.id]
  vm_size               = "Standard_A2"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-core-smalldisk"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.web_server_name}-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = var.web_server_name
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_windows_config {

  }
}
