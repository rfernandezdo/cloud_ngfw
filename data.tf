# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group
data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}


data "azurerm_public_ip" "pip" {
  for_each = var.cloudngfws

  name                = each.value.cloudngfw_config.public_ip_keys
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

data "azurerm_virtual_network" "virtual_network" {
  for_each = var.cloudngfws

  name                = each.value.virtual_network_key
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

data "azurerm_subnet" "untrusted" {
  for_each = var.cloudngfws

  name                 = each.value.untrusted_subnet_key
  virtual_network_name = each.value.virtual_network_key
  resource_group_name  = data.azurerm_resource_group.resource_group.name
}

data "azurerm_subnet" "trusted" {
  for_each = var.cloudngfws

  name                 = each.value.trusted_subnet_key
  virtual_network_name = each.value.virtual_network_key
  resource_group_name  = data.azurerm_resource_group.resource_group.name
}
