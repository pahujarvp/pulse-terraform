resource "azurerm_key_vault" "kvault" {
  for_each                    = var.child_key_vault
  name                        = each.value.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  sku_name                    = each.value.sku_name
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  rbac_authorization_enabled  = false
  enabled_for_disk_encryption = true
}
