resource "azurerm_network_interface" "nic" {
  for_each            = var.child_vms
  name                = each.value.nic_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip_id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each                        = var.child_vms
  name                            = each.value.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = each.value.size
  admin_username                  = each.value.admin_username
  admin_password                  = each.value.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nic[each.key].id]

  os_disk {
    name                 = each.value.os_disk_name
    caching              = "ReadWrite"
    storage_account_type = each.value.os_disk_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# resource "azurerm_managed_disk" "data_disk" {
#   for_each             = var.child_data_disks
#   name                 = each.value.name
#   location             = var.location
#   resource_group_name  = var.resource_group_name
#   storage_account_type = each.value.storage_account_type
#   create_option        = "Empty"
#   disk_size_gb         = each.value.disk_size_gb
# }

# resource "azurerm_virtual_machine_data_disk_attachment" "disk_attach" {
#   for_each           = var.child_data_disks
#   managed_disk_id    = azurerm_managed_disk.data_disk[each.key].id
#   virtual_machine_id = azurerm_linux_virtual_machine.vm[each.value.vm_key].id
#   lun                = each.value.lun
#   caching            = each.value.caching
# }
