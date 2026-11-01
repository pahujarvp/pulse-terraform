resource "azurerm_monitor_workspace" "example" {
for_each = var.monittor_workspace
  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  }