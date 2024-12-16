# Configure the Azure provider
 
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.64.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}
 
provider "azurerm" {
  features {}
  subscription_id = "f936a180-7b93-4203-8faa-f376529bd4f8"
  client_id       = "a2d89136-b086-4755-9f98-af856c2d8c30"
  client_secret   = "Rmn8Q~yfgxmhdOwJbn-pok8UemthKPQ~RH7jxaaI"
  tenant_id       = "13085c86-4bcb-460a-a6f0-b373421c6323"
}
 
resource "azurerm_resource_group" "example" {
  name     = "vam-rg-new1"
  location = "West US 2"
}
 
resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
 
  depends_on = [azurerm_resource_group.example]  # Ensure the resource group is created first
}
 
resource "azurerm_virtual_network" "example" {
  name                = "dev-vnet"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
 
  depends_on = [azurerm_resource_group.example]  # Ensure the resource group is created first
}
 
resource "azurerm_subnet" "example" {
  name                 = "dev-subnet"
  address_prefixes     = ["10.0.1.0/24"]  # This should be a list
  virtual_network_name = azurerm_virtual_network.example.name
  resource_group_name  = azurerm_resource_group.example.name
}
 
resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
 
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}
 
# New Virtual Machine resource
resource "azurerm_virtual_machine" "example" {
  name                  = "dev-vm"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_DS1_v2"
 
  storage_os_disk {
    name          = "dev-vm-osdisk"
    caching       = "ReadWrite"
    create_option = "FromImage"
    os_type       = "Linux"  # Change this to "Windows" for a Windows VM
  }
 
  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
 
  os_profile {
    computer_name  = "dev-vm"
    admin_username = "adminuser"
    admin_password = "P@ssw0rd123"  # Ensure you use a secure password!
  }
 
  os_profile_linux_config {
    disable_password_authentication = false  # Set to true if using SSH keys
  }
}
