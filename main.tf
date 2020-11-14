provider "azurerm" {
  version = "2.34.0"
  features {} # allows to configure some of the behaviors of some of the resources. Put a statement to disable unwanted features
}

resource "azurerm_resource_group" "primary_rg" {
  name     = var.primary_rg
  location = var.web_server_location

  tags = {
    Owner      = "Mohamed"
    Department = "Cloud"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_prefix}-vnet"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.primary_rg.name
  address_space       = [var.web_server_address_space]

  tags = {
    Network    = "Central"
    Department = "Infrastructure"
  }
}

resource "azurerm_subnet" "web_server_subnets" {
for_each = var.web_server_subnet

  name = each.key
  resource_group_name  = azurerm_resource_group.primary_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix     = each.value

}

resource "azurerm_network_interface" "web_server_nic" {
  name                = "${var.web_server_name}-${format("%02d",count.index)}-nic"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.primary_rg.name
  count               = var.web_server_count

  ip_configuration {
    name                          = "${var.resource_prefix}-ip"
    subnet_id                     = azurerm_subnet.web_server_subnets["web-server"].id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = count.index == 0 ? azurerm_public_ip.public_ip.id : null
  }
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.web_server_name}-pip"
  resource_group_name = azurerm_resource_group.primary_rg.name
  location            = var.web_server_location
  allocation_method   = var.environment == "development" ? "Static" : "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_security_group" "web_server_nsg" {
  name                = "${var.web_server_name}-nsg"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.primary_rg.name
}


resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
  name                        = "rdp_inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.primary_rg.name
  network_security_group_name = azurerm_network_security_group.web_server_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "web_server_sag" {
  network_security_group_id = azurerm_network_security_group.web_server_nsg.id
  subnet_id      = azurerm_subnet.web_server_subnets["web-server"].id
}

resource "azurerm_windows_virtual_machine" "web_server" {
  name                  = "${var.web_server_name}-${format("%02d",count.index)}"
  location              = var.web_server_location
  resource_group_name   = azurerm_resource_group.primary_rg.name
  network_interface_ids = [azurerm_network_interface.web_server_nic[count.index].id]
  availability_set_id   = azurerm_availability_set.web_server_as.id
  count                 = var.web_server_count
  size                  = "Standard_B1s"
  admin_username        = "${var.web_server_name}-${format("%02d",count.index)}"
  admin_password        = "Gh%$d745!34"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServerSemiAnnual"
    sku       = "Datacenter-Core-1709-smalldisk"
    version   = "latest"
  }

}

resource "azurerm_availability_set" "web_server_as" {
  name                        = "${var.resource_prefix}-as"
  location                    = var.web_server_location
  resource_group_name         = azurerm_resource_group.primary_rg.name
  managed                     = true
  platform_fault_domain_count = 2
}
