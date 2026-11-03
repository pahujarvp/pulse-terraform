data "azurerm_client_config" "current" {}

data "azurerm_subnet" "snet_workload" {
  ## To-Be created after Subnet
  depends_on           = [module.subnet]
  name                 = var.root_subnets["snet_workload"].name
  virtual_network_name = var.root_virtual_network["vnet1"].name
  resource_group_name  = var.root_resource_group["workload"].name
}

data "azurerm_public_ip" "pip_vm" {
  ## To-Be created after Public IP
  depends_on          = [module.public_ip]
  name                = var.root_public_ip["pip_vm"].name
  resource_group_name = var.root_resource_group["workload"].name
}


data "azurerm_virtual_machine" "vm1" {
  ## To-Be created after Subnet and Public IP
  depends_on          = [module.linux_virtual_machine]
  name                = var.root_vms["vm1"].name
  resource_group_name = var.root_resource_group["workload"].name
}

data "azurerm_monitor_action_group" "group1" {
  resource_group_name = var.root_resource_group["monitoring"].name
  name                = var.root_action_group["group1"].name
}

data "azurerm_monitor_action_group" "group2" {
  resource_group_name = var.root_resource_group["monitoring"].name
  name                = var.root_action_group["group2"].name
}
