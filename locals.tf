locals {
  // Paso 1: Recopilar todas las claves de IPs necesarias por firewall
  all_required_ip_keys = {
    for fw_key, fw in var.cloudngfws : fw_key => distinct(concat(
      try(fw.cloudngfw_config.public_ip_keys, []),
      try(fw.cloudngfw_config.egress_nat_ip_keys, []) != null ? try(fw.cloudngfw_config.egress_nat_ip_keys, []) : [],
      # Agregar también las claves de IPs para DNAT
      [for dnat_key, dnat in try(fw.cloudngfw_config.destination_nats, {}) : 
        dnat.frontend_public_ip_key if dnat.frontend_public_ip_key != null]
    ))
  }

  // Paso 2: Determinar qué IPs son externas vs módulo-creadas
  ip_classification = {
    for fw_key, ip_keys in local.all_required_ip_keys : fw_key => {
      external_ips    = [for k in ip_keys : k if contains(keys(var.external_public_ips), k)]
      module_ips      = [for k in ip_keys : k if !contains(keys(var.external_public_ips), k)]
      all_external    = length([for k in ip_keys : k if !contains(keys(var.external_public_ips), k)]) == 0
      has_module_ips  = length([for k in ip_keys : k if !contains(keys(var.external_public_ips), k)]) > 0
    }
  }

  // Paso 3: Lista de pares clave-resource group con lógica híbrida mejorada
  public_ip_key_rg_pairs = flatten([
    for fw_key, fw in var.cloudngfws : [
      for k in local.all_required_ip_keys[fw_key] : {
        key = k
        # Lógica híbrida mejorada: primero buscar en external_public_ips, luego en los RGs standard
        rg = try(
          var.external_public_ips[k].resource_group_name,  # IPs externas (prioritarias)
          try(data.azurerm_resource_group.resource_group_pip[fw_key].name, null),   # IPs creadas por este módulo (si resource_group_name_pip_key está definido)
          data.azurerm_resource_group.resource_group_network[fw_key].name, # Fallback al RG de network
          data.azurerm_resource_group.resource_group[fw_key].name, # Fallback final al RG del firewall
          null
        )
        is_external = contains(keys(var.external_public_ips), k)
        firewall_key = fw_key
      }
    ]
  ])
  // Paso 2: Mapping único clave => resource group
  public_ip_key_to_rg = {
    for pair in local.public_ip_key_rg_pairs : pair.key => pair.rg
  }

  # Todas las claves únicas
  all_public_ip_keys = distinct([for pair in local.public_ip_key_rg_pairs : pair.key])
  
  # Solo las IPs externas (que ya existen y necesitan data source)
  external_public_ip_keys = distinct([for pair in local.public_ip_key_rg_pairs : pair.key if pair.is_external])

  // Paso 4: Detectar modo de operación para optimización (renombrado all_external -> all_ips_external)
  operation_mode = {
    for fw_key, classification in local.ip_classification : fw_key => (
      classification.all_external ? "all_ips_external" :
      classification.has_module_ips ? (length(classification.external_ips) > 0 ? "hybrid_ips" : "all_ips_module") :
      "no_ips"
    )
  }

  // Descripciones legibles de los modos
  operation_mode_descriptions = {
    all_ips_external = "Todas las IP son externas (no se crean nuevas)"
    all_ips_module   = "Todas las IP se crean mediante el módulo"
    hybrid_ips       = "Combinación: algunas IP externas y otras creadas"
    no_ips           = "No se requieren IP públicas"
  }

  // Paso 5: Determinar si necesitamos crear el módulo public_ip (ajustado al nuevo nombre)
  need_public_ip_module = length([for fw_key, mode in local.operation_mode : fw_key if mode != "all_ips_external"]) > 0

  // Paso 6: Debug - información sobre el modo de operación (para outputs opcionales)
  debug_info = {
    for fw_key, fw in var.cloudngfws : fw_key => {
      required_ips                = local.all_required_ip_keys[fw_key]
      external_ips                = local.ip_classification[fw_key].external_ips
      module_ips                  = local.ip_classification[fw_key].module_ips
      operation_mode              = local.operation_mode[fw_key]
      operation_mode_description  = local.operation_mode_descriptions[local.operation_mode[fw_key]]
      needs_module                = local.operation_mode[fw_key] != "all_ips_external"
    }
  }

  // Locals relacionados con Public IPs (movidos desde module.tf)
  // Resource groups únicos usados por IPs/Prefixes
  public_ip_rg_names = distinct(concat(
    [for _, v in coalesce(var.public_ips.public_ip_addresses, {}) : v.resource_group_name if try(v.resource_group_name, null) != null],
    [for _, v in coalesce(var.public_ips.public_ip_prefixes, {}) : v.resource_group_name if try(v.resource_group_name, null) != null],
    [for _, v in coalesce(var.public_ips.public_ip_addresses, {}) : v.prefix_resource_group_name if try(v.prefix_resource_group_name, null) != null]
  ))

  // Mapeado de RG a sus ubicaciones
  public_ip_rgs_locations = {
    for rg in local.public_ip_rg_names : rg => data.azurerm_resource_group.public_ip_rgs[rg].location
  }

  // Regiones únicas donde hay IPs
  public_ip_regions = distinct(values(local.public_ip_rgs_locations))

  // Agrupación de IPs por región para instanciar módulos
  public_ip_grouped = {
    for region in local.public_ip_regions : region => {
      public_ip_addresses = {
        for k, v in coalesce(var.public_ips.public_ip_addresses, {}) : k => v
        if try(v.resource_group_name, null) != null && local.public_ip_rgs_locations[v.resource_group_name] == region
      }
      public_ip_prefixes = {
        for k, v in coalesce(var.public_ips.public_ip_prefixes, {}) : k => v
        if try(v.resource_group_name, null) != null && local.public_ip_rgs_locations[v.resource_group_name] == region
      }
    }
    if length(coalesce(var.public_ips.public_ip_addresses, {})) + length(coalesce(var.public_ips.public_ip_prefixes, {})) > 0
  }

  // Outputs aplanados de múltiples instancias del módulo public_ip
  module_pip_ids_flat        = local.need_public_ip_module && length(module.public_ip) > 0 ? merge([for _, m in module.public_ip : m.pip_ids]...) : {}
  module_pip_ip_addresses_flat = local.need_public_ip_module && length(module.public_ip) > 0 ? merge([for _, m in module.public_ip : m.pip_ip_addresses]...) : {}

}