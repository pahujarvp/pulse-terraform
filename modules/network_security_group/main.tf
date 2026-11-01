resource "azurerm_network_security_group" "nsg" {
  for_each            = var.child_network_security_group
  name                = each.value.name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}
