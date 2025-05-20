variable "cloudngfws" {
  description = "Map of Cloud NGFW configurations. Each key represents a firewall instance, and the value is an object with all required properties."
  type = map(object({
    name                       = string
    resource_group_name_key    = string
    resource_group_name_network_key = string
    attachment_type            = optional(string, "vnet")
    virtual_network_key        = string
    untrusted_subnet_key       = string
    trusted_subnet_key         = string
    management_mode            = optional(string, "panorama")
    cloudngfw_config           = any
    tags                       = optional(map(string), {})
  }))
}
