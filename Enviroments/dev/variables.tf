
# Enviroment Variables


# 1. Base Foundation

variable "root_resource_group" {}

# 2. Networking Infrastructure

variable "root_virtual_network" {}
variable "root_subnets" {}

# 3. Network Security

variable "root_network_security_group" {}
# variable "root_network_security_rules" {} # (Archived) ###########

# 4. Public Connectivity

variable "root_public_ip" {}
# variable "root_appgw" {} # (Archived) ###########

# 5. Security & Secrets Management

variable "root_key_vault" {}

# 6. Compute & Storage Workloads

variable "root_vms" {}
variable "root_data_disks" {}

# 7. Monitoring & Alerting

variable "root_action_group" {}
variable "root_logic_app" {}
