resource "azurerm_monitor_metric_alert" "alert" {
  for_each            = var.child_alerts
  name                = each.value.name
  resource_group_name = var.resource_group_name
  scopes              = [var.target_resource_id]

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 40
  }

  action {
    action_group_id = var.action_group_id
  }
}
