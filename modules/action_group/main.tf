resource "azurerm_monitor_action_group" "ag" {
  for_each            = var.child_action_group
  name                = each.value.name
  resource_group_name = var.resource_group_name
  short_name          = each.value.short_name
}