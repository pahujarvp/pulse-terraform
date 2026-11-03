## Resource Groups
module "resource_group" {
  source               = "../../modules/resource_groups"
  child_resource_group = var.root_resource_group
}

## Virtual Network
module "network" {
  ## To-Be created after Resourcegroup
  depends_on = [module.resource_group]

  source                = "../../modules/virtual_network"
  child_virtual_network = var.root_virtual_network["vnet1"].name
  address_space         = var.root_virtual_network["vnet1"].address_space
  resource_group_name   = var.root_resource_group["workload"].name
  location              = var.root_resource_group["workload"].location
}

## Subnet
module "subnet" {
  ## To-Be created after Network
  depends_on = [module.network]

  source               = "../../modules/subnet"
  child_subnet         = var.root_subnets
  resource_group_name  = var.root_resource_group["workload"].name
  virtual_network_name = var.root_virtual_network["vnet1"].name
}

## Network Security Group
module "network_security_group" {
  ## To-Be created after Resourcegroup
  depends_on = [module.resource_group]

  source                       = "../../modules/network_security_group"
  child_network_security_group = var.root_network_security_group
  resource_group_name          = var.root_resource_group["workload"].name
  resource_group_location      = var.root_resource_group["workload"].location
}

## Network Security Rule
# module "network_security_rule" {
#   ## To-Be created after Network Security Group
#   depends_on = [module.network_security_group]

#   source                       = "../../modules/network_security_rule"
#   child_network_security_rules = var.root_network_security_rules
#   resource_group_name          = var.root_resource_group["workload"].name
# }

## Public IP
module "public_ip" {
  ## To-Be created after Resourcegroup
  depends_on = [module.resource_group]

  source              = "../../modules/public_ip"
  child_public_ip     = var.root_public_ip
  resource_group_name = var.root_resource_group["workload"].name
  location            = var.root_resource_group["workload"].location
}

## Key Vault
module "key_vault" {
  ## To-Be created after Resourcegroup
  depends_on = [module.resource_group]

  source              = "../../modules/key_vault"
  child_key_vault     = var.root_key_vault
  resource_group_name = var.root_resource_group["workload"].name
  location            = var.root_resource_group["workload"].location
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

## Application Gateway
# module "application_gateway" {
#   ## To-Be created after Public IP
#   depends_on = [module.public_ip, module.subnet]

#   source              = "../../modules/application_gateway"
#   child_appgw         = var.root_appgw
#   resource_group_name = var.root_resource_group["workload"].name
#   location            = var.root_resource_group["workload"].location
#   subnet_id           = data.azurerm_subnet.snet_appgw.id
#   public_ip_id        = data.azurerm_public_ip.pip_appgw.id
# }

## Linux Virtual Machines
module "linux_virtual_machine" {
  ## To-Be created after Subnet and Public IP
  depends_on = [module.subnet, module.public_ip]

  source    = "../../modules/linux_virtual_machine"
  child_vms = var.root_vms
  # child_data_disks    = var.root_data_disks
  resource_group_name = var.root_resource_group["workload"].name
  location            = var.root_resource_group["workload"].location
  subnet_id           = data.azurerm_subnet.snet_workload.id
  public_ip_id        = data.azurerm_public_ip.pip_vm.id
}

## Action Group 
module "action_group" {
  ## To-Be created after Resourcegroup
  depends_on = [module.resource_group]

  source             = "../../modules/action_group"
  child_action_group = var.root_action_group

  resource_group_name = var.root_resource_group["monitoring"].name
}

## Logic App
module "logic_app" {
  ## To-Be created after Resourcegroup
  depends_on = [module.resource_group]

  source              = "../../modules/logic_app"
  child_logic_app     = var.root_logic_app
  location            = var.root_resource_group["monitoring"].location
  resource_group_name = var.root_resource_group["monitoring"].name
}

## Matric Alert

module "alerts" {
  depends_on          = [module.linux_virtual_machine]
  source              = "../../modules/alerts"
  child_alerts        = var.root_alert
  resource_group_name = var.root_resource_group["monitoring"].name
  target_resource_id  = data.azurerm_virtual_machine.vm1.id
  action_group_id     = data.azurerm_monitor_action_group.group2.id

}
