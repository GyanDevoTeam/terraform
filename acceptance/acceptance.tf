provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# Use the existing resource group
data "azurerm_resource_group" "existing" {
  name = "gyan_sahadew-lall-rg"
}

# Virtual network
resource "azurerm_virtual_network" "acceptance" {
  name                = "acceptance-vnet"
  address_space       = ["10.2.0.0/16"]
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
}

# Subnet
resource "azurerm_subnet" "acceptance" {
  name                 = "acceptance-subnet"
  resource_group_name  = data.azurerm_resource_group.existing.name
  virtual_network_name = azurerm_virtual_network.acceptance.name
  address_prefixes     = ["10.2.1.0/24"]
}

# Network security group
resource "azurerm_network_security_group" "acceptance" {
  name                = "acceptance-nsg"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name

  security_rule {
    name                      = "SSH"
    priority                  = 1001
    direction                 = "Inbound"
    access                    = "Allow"
    protocol                  = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "22"
    source_address_prefix     = "0.0.0.0/0"
    destination_address_prefix = "*"
  }

  security_rule {
    name                      = "HTTP-IN"
    priority                  = 1002
    direction                 = "Inbound"
    access                    = "Allow"
    protocol                  = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "80"
    source_address_prefix     = "0.0.0.0/0"
    destination_address_prefix = "*"
  }

  security_rule {
    name                      = "HTTP-OUT"
    priority                  = 1002
    direction                 = "Outbound"
    access                    = "Allow"
    protocol                  = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "80"
    source_address_prefix     = "0.0.0.0/0"
    destination_address_prefix = "*"
  }
}

# Public IP
resource "azurerm_public_ip" "acceptance" {
  name                = "acceptance-public-ip"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  allocation_method   = "Dynamic"
}

# Network interface
resource "azurerm_network_interface" "acceptance" {
  name                = "acceptance-nic"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name

  ip_configuration {
    name                       = "internal"
    subnet_id                  = azurerm_subnet.acceptance.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id       = azurerm_public_ip.acceptance.id
  }
}

# Virtual machine
resource "azurerm_virtual_machine" "acceptance" {
  name                = "acceptance-vm"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  vm_size             = "Standard_D2s_v3"
  network_interface_ids = [azurerm_network_interface.acceptance.id]

  storage_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_profile {
    computer_name  = "acceptance-vm"
    admin_username = "azuregyan"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azuregyan/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }

  storage_os_disk {
    name              = "acceptance-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
}