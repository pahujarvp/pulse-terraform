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
