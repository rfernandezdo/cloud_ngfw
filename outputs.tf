# Outputs principales del módulo Cloud NGFW

output "cloudngfw_firewalls" {
  description = "Summary of Cloud NGFW firewall configurations"
  value = {
    for fw_key, fw in var.cloudngfws : fw_key => {
      name                  = fw.name
      resource_group_name   = data.azurerm_resource_group.resource_group[fw_key].name
      management_mode       = fw.management_mode
      attachment_type       = fw.attachment_type
      required_public_ip_keys = local.debug_info[fw_key].required_ips
      external_public_ips = {
        for k in local.debug_info[fw_key].external_ips : k => {
          id      = try(data.azurerm_public_ip.pip[k].id, null)
          address = try(data.azurerm_public_ip.pip[k].ip_address, null)
        }
      }
      module_public_ip_keys = local.debug_info[fw_key].module_ips
      operation_mode        = local.debug_info[fw_key].operation_mode
    }
  }
}

output "public_ip_addresses" {
  description = "Public IP addresses created by the module (if any)"
  value = local.need_public_ip_module ? merge([
    for _, m in module.public_ip : {
      for k, v in m.pip_ids : k => {
        id      = v
        address = m.pip_ip_addresses[k]
      }
    }
  ]...) : {}
}

output "external_ip_addresses" {
  description = "External IP addresses referenced by the module"
  value = {
    for k, v in data.azurerm_public_ip.pip : k => {
      id             = v.id
      address        = v.ip_address
      resource_group = v.resource_group_name
      name           = v.name
    }
  }
}

# Output de debug - información sobre la configuración híbrida
output "debug_ip_configuration" {
  description = "Debug information about IP configuration modes"
  value = local.debug_info
}

output "operation_summary" {
  description = "Summary of how the module is operating"
  value = {
    need_public_ip_module = local.need_public_ip_module
    operation_modes       = local.operation_mode
    total_external_ips    = length(local.external_public_ip_keys)
    total_firewalls       = length(var.cloudngfws)
  }
}
