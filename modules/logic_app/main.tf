resource "azurerm_logic_app_workflow" "logic_app" {
  for_each            = var.child_logic_app
  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
}