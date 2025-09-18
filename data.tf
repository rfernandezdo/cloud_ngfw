# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group
data "azurerm_resource_group" "resource_group" {
  for_each = var.cloudngfws
  name     = each.value.resource_group_name_key
}

data "azurerm_resource_group" "resource_group_network" {
  for_each = var.cloudngfws
  name     = each.value.resource_group_name_network_key
}

data "azurerm_resource_group" "resource_group_pip" {
  for_each = {
    for k, v in var.cloudngfws : k => v 
    if try(v.resource_group_name_pip_key, null) != null
  }
  name = each.value.resource_group_name_pip_key
}

data "azurerm_public_ip" "pip" {
  for_each            = toset(local.external_public_ip_keys)
  name                = each.key
  resource_group_name = local.public_ip_key_to_rg[each.key]
}

data "azurerm_virtual_network" "virtual_network" {
  for_each = var.cloudngfws

  name                = each.value.virtual_network_key
  resource_group_name = data.azurerm_resource_group.resource_group_network[each.key].name
}

data "azurerm_subnet" "untrusted" {
  for_each = var.cloudngfws

  name                 = each.value.untrusted_subnet_key
  virtual_network_name = each.value.virtual_network_key
  resource_group_name  = data.azurerm_resource_group.resource_group_network[each.key].name
}

data "azurerm_subnet" "trusted" {
  for_each = var.cloudngfws

  name                 = each.value.trusted_subnet_key
  virtual_network_name = each.value.virtual_network_key
  resource_group_name  = data.azurerm_resource_group.resource_group_network[each.key].name
}

# Data sources para Resource Groups de Public IPs (movido desde module.tf)
data "azurerm_resource_group" "public_ip_rgs" {
  for_each = toset(local.public_ip_rg_names)
  name     = each.value
}
