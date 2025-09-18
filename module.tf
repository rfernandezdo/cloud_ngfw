# Crear IPs públicas adicionales para DNATs (solo cuando sea necesario)
# Agrupación por región dinámica a partir de los resource groups de cada IP / Prefix
# Si todas las IPs son externas, no se instancian módulos

module "public_ip" {
  for_each = local.need_public_ip_module ? local.public_ip_grouped : {}
  source   = "PaloAltoNetworks/swfw-modules/azurerm//modules/public_ip"
  version  = "3.3.7"

  region              = each.key
  public_ip_addresses = each.value.public_ip_addresses
  public_ip_prefixes  = each.value.public_ip_prefixes
  tags                = {}
}

# trunk-ignore(checkov/CKV_TF_1)
module "swfw-modules_cloudngfw" {
  source  = "PaloAltoNetworks/swfw-modules/azurerm//modules/cloudngfw"
  version = "3.3.7"
  for_each            = var.cloudngfws
  name                = each.value.name
  resource_group_name = data.azurerm_resource_group.resource_group[each.key].name
  region              = data.azurerm_resource_group.resource_group[each.key].location
  attachment_type     = try(each.value.attachment_type, "vnet")
  virtual_network_id = each.value.attachment_type == "vnet" ? (
    data.azurerm_virtual_network.virtual_network[each.key].id
  ) : null
  untrusted_subnet_id = each.value.attachment_type == "vnet" ? (
    data.azurerm_subnet.untrusted[each.key].id
  ) : null
  trusted_subnet_id = each.value.attachment_type == "vnet" ? (
    data.azurerm_subnet.trusted[each.key].id
  ) : null
  management_mode = try(each.value.management_mode, "panorama")
  cloudngfw_config = merge(each.value.cloudngfw_config, {
    public_ip_name = null
    public_ip_ids = {
      for k in coalesce(each.value.cloudngfw_config.public_ip_keys, []) : k => (
        local.need_public_ip_module ? (
          contains(keys(local.module_pip_ids_flat), k) ? local.module_pip_ids_flat[k] : (
            contains(keys(data.azurerm_public_ip.pip), k) ? data.azurerm_public_ip.pip[k].id : null
          )
        ) : data.azurerm_public_ip.pip[k].id
      ) if local.need_public_ip_module ? true : contains(keys(data.azurerm_public_ip.pip), k)
    }
    egress_nat_ip_ids = {
      for k in coalesce(each.value.cloudngfw_config.egress_nat_ip_keys, []) : k => (
        local.need_public_ip_module ? (
          contains(keys(local.module_pip_ids_flat), k) ? local.module_pip_ids_flat[k] : (
            contains(keys(data.azurerm_public_ip.pip), k) ? data.azurerm_public_ip.pip[k].id : null
          )
        ) : data.azurerm_public_ip.pip[k].id
      ) if local.need_public_ip_module ? true : contains(keys(data.azurerm_public_ip.pip), k)
    }
    destination_nats = {
      for k, v in each.value.cloudngfw_config.destination_nats : k => merge(v, {
        frontend_public_ip_address_id = v.frontend_public_ip_key != null ? (
          local.need_public_ip_module && contains(keys(local.module_pip_ids_flat), v.frontend_public_ip_key) ?
            local.module_pip_ids_flat[v.frontend_public_ip_key] :
            lookup({ for pk, pv in data.azurerm_public_ip.pip : pk => pv.id }, v.frontend_public_ip_key, null)
        ) : null
      })
    }
  })

  tags = each.value.tags
}
