# trunk-ignore(checkov/CKV_TF_1)
module "swfw-modules_cloudngfw" {
  source  = "PaloAltoNetworks/swfw-modules/azurerm//modules/cloudngfw"
  version = "3.3.7"
  # insert the 6 required variables here
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
      for k in coalesce(each.value.cloudngfw_config.public_ip_keys, []) : k => data.azurerm_public_ip.pip[k].id
    },
    egress_nat_ip_ids = {
      for k in each.value.cloudngfw_config.egress_nat_ip_keys : k => data.azurerm_public_ip.pip[k].id
    },
    destination_nats = {
      for k, v in each.value.cloudngfw_config.destination_nats : k => merge(v, {
        frontend_public_ip_address_id = v.frontend_public_ip_key != null ? lookup({
          for pk, pv in data.azurerm_public_ip.pip : pk => pv.id
        }, v.frontend_public_ip_key, null) : null
      })
    }
  })

  tags = each.value.tags
}
