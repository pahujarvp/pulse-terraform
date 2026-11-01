resource "azurerm_resource_group" "rg" {
  for_each = var.child_resource_group
  name     = each.value.name
  location = each.value.location
}
