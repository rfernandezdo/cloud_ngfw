locals {
  // Paso 1: Lista de pares clave-resource group
  public_ip_key_rg_pairs = flatten([
    for fw_key, fw in var.cloudngfws : [
      for k in distinct(concat(
        try(fw.cloudngfw_config.public_ip_keys, []),
        try(fw.cloudngfw_config.egress_nat_ip_keys, [])
        )) : {
        key = k
        rg  = try(data.azurerm_resource_group.resource_group_pip[fw_key].name, data.azurerm_resource_group.resource_group_network[fw_key].name, null)
      }
    ]
  ])
  // Paso 2: Mapping único clave => resource group
  public_ip_key_to_rg = {
    for pair in local.public_ip_key_rg_pairs : pair.key => pair.rg
  }

  # Todas las claves únicas
  all_public_ip_keys = distinct([for pair in local.public_ip_key_rg_pairs : pair.key])

}