variable "resource_group_name" {
  description = "The name of the resource group in which to create the resources."
  type        = string
}

variable "cloudngfws" {
  description = "Map of Cloud NGFW configurations. Each key represents a firewall instance, and the value is an object with all required properties."
  type = map(object({
    name                 = string
    attachment_type      = optional(string, "vnet")
    virtual_network_key  = string
    untrusted_subnet_key = string
    trusted_subnet_key   = string
    management_mode      = optional(string, "panorama")
    cloudngfw_config     = any
  }))
}

variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
  default     = {}
}
