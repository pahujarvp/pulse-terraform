terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-healops-tfstate-cin-01"
    storage_account_name = "sthealopstfstate01"
    container_name       = "pulsetfstate"
    key                  = "pulseterraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}