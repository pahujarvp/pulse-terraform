resource "azurerm_public_ip" "pip" {
  for_each            = var.child_public_ip
  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = each.value.allocation_method
  sku                 = each.value.sku
}
