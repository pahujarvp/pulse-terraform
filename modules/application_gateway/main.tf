resource "azurerm_application_gateway" "appgw" {
  for_each            = var.child_appgw
  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = each.value.sku_name
    tier     = each.value.sku_tier
    capacity = each.value.capacity
  }

  gateway_ip_configuration {
    name      = "appgw-ip-configuration"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "frontend-port-80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-configuration"
    public_ip_address_id = var.public_ip_id
  }

  backend_address_pool {
    name = "backend-address-pool"
  }

  backend_http_settings {
    name                  = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-configuration"
    frontend_port_name             = "frontend-port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "request-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-address-pool"
    backend_http_settings_name = "backend-http-settings"
    priority                   = 100
  }
}
