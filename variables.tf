variable "cloudngfws" {
  description = <<-EOF
  A map of objects defining the configuration for Cloud Next-Gen Firewalls (cloudngfws) in the environment.

  Each cloudngfw entry in the map supports the following attributes:

  - `name`                            - (`string`, required) the name of the Palo Alto Next Generation Firewall instance.
  - `attachment_type`                 - (`string`, required) specifies whether the firewall is attached to a Virtual Network
  - `resource_group_name_key`         - (`string`, required) the name of the Resource Group where the firewall will be created.
  - `resource_group_name_network_key` - (`string`, required) the name of the Resource Group where the Virtual Network is located.
                                        (`vnet`) or a Virtual WAN (`vwan`).
  - `resource_group_name_pip_key`     - (`string`, optional) the name of the Resource Group where the Public IP resource is located if is different from the
                                        Resource Group of the Virtual Network.
                                        This is used only when the variable `public_ip_keys` is utilized.
  - `virtual_network_key`             - (`string`, optional) key referencing the Virtual Network associated with this firewall.
                                        Required if the `attachment_type` is `vnet`.
  - `untrusted_subnet_key`            - (`string`, optional) key of the subnet designated as untrusted within the Virtual Network.
  - `trusted_subnet_key`              - (`string`, optional) key of the subnet designated as trusted within the Virtual Network.
  - `virtual_hub_key`                 - (`string`, optional) key of the Virtual Hub within a vWAN where to place the Cloud NGFW.
  - `management_mode`                 - (`string`, required) defines the management mode for the firewall. When set to `panorama`,
                                        the firewall's policies are managed via Panorama.
  - `cloudngfw_config`                - (`object`, required) configuration details for the Cloud NGFW instance, with the
                                        following properties:

    - `panorama_base64_config`        - (`string`, optional) the Base64-encoded configuration for connecting to Panorama server.
                                        This field is required when `management_mode` is set to `panorama`.
    - `rulestack_id`                  - (`string`, optional) the ID of the Local Rulestack used to configure this Firewall
                                        Resource. This field is required when `management_mode` is set to `rulestack`.
    - `create_public_ip`              - (`bool`, optional, defaults to `true`) controls if the Public IP resource is created or
                                        sourced. This field is ignored when the variable `public_ip_keys` is used.
    - `public_ip_name`                - (`string`, optional) the name of the Public IP resource. This field is required unless
                                        the variable `public_ip_keys` is used.
    - `public_ip_resource_group_name` - (`string`, optional) the name of the Resource Group hosting the Public IP resource.
                                        This is used only for sourced resources.
    - `public_ip_keys`                - (`list`, optional) the keys referencing Public IP addresses from `public_ip` module.
                                        Property is used when Public IP is not created or sourced within `cloudngfw` module.
    - `egress_nat_ip_keys`            - (`list`, optional) the keys referencing egress NAT Public IP addresses from `public_ip`
                                        module. Property is used when Public IP is not created or sourced within `cloudngfw`
                                        module.
    - `trusted_address_ranges`        - (`list`, optional) a list of public IP address ranges that will be treated as internal
                                        traffic by Cloud NGFW in addition to RFC 1918 private subnets. Each list entry has to be
                                        in a CIDR format.
    - `destination_nats`              - (`map`, optional) defines one or more destination NAT configurations. Each object
                                        supports the following properties:

      - `destination_nat_name`     - (`string`, required) the name of the Destination NAT. Must be unique within this map.
      - `destination_nat_protocol` - (`string`, required) the protocol for this Destination NAT. Possible values are `TCP` or
                                     `UDP`.
      - `frontend_public_ip_key`   - (`string`, optional) the key referencing the Public IP that receives the traffic.
                                     This is used only when the variable `public_ip_ids` is utilized.
      - `frontend_port`            - (`number`, required) the port on which traffic will be received. Must be in the range from
                                     1 to 65535.
      - `backend_ip_address`       - (`string`, required) the IPv4 address to which traffic will be forwarded.
      - `backend_port`             - (`number`, required) the port number to which traffic will be sent.
                                     Must be in the range 1 to 65535.
  - `tags`                            - (`map`, optional) a map of tags to assign to the Cloud NGFW instance.

  EOF
  type = map(object({
    name                            = string
    attachment_type                 = string
    resource_group_name_key         = string
    resource_group_name_network_key = optional(string)
    resource_group_name_pip_key     = optional(string)
    virtual_network_key             = optional(string)
    untrusted_subnet_key            = optional(string)
    trusted_subnet_key              = optional(string)
    virtual_hub_key                 = optional(string)
    management_mode                 = string
    cloudngfw_config = object({
      plan_id                       = optional(string)
      marketplace_offer_id          = optional(string)
      panorama_base64_config        = optional(string)
      rulestack_id                  = optional(string)
      create_public_ip              = optional(bool, false)
      public_ip_name                = optional(string)
      public_ip_resource_group_name = optional(string)
      public_ip_keys                = optional(list(string))
      egress_nat_ip_keys            = optional(list(string))
      trusted_address_ranges        = optional(list(string))
      destination_nats = optional(map(object({
        destination_nat_name     = string
        destination_nat_protocol = string
        frontend_public_ip_key   = optional(string)
        frontend_port            = number
        backend_ip_address       = string
        backend_port             = number
      })), {})
    })
    tags = optional(map(string))
  }))

  // Validación: cada firewall debe tener al menos una IP asociada (creada o existente)
  validation {
    condition = alltrue([
      for _, fw in var.cloudngfws : (
        length(concat(
          try(fw.cloudngfw_config.public_ip_keys, []),
          try(fw.cloudngfw_config.egress_nat_ip_keys, [])
        )) > 0
        || try(fw.cloudngfw_config.create_public_ip, false)
        || length([
          for _, dn in try(fw.cloudngfw_config.destination_nats, {}) : dn
          if try(dn.frontend_public_ip_key, null) != null
        ]) > 0
      )
    ])
    error_message = "Cada firewall (cloudngfw) debe definir al menos una IP pública: public_ip_keys, egress_nat_ip_keys, create_public_ip=true o destination_nats con frontend_public_ip_key."
  }
}

variable "public_ips" {
  description = <<-EOF
  A map defining Public IP Addresses and Prefixes for DNAT purposes.

  Following properties are available:

  - `public_ip_addresses` - (`map`, optional) map of objects describing Public IP Addresses
  - `public_ip_prefixes`  - (`map`, optional) map of objects describing Public IP Prefixes

  Example:
  ```
  public_ips = {
    public_ip_addresses = {
      "https-dnat-ip" = {
        create = true
        name   = "dnat-https-pip"
        resource_group_name = "my-rg"
      }
    }
    public_ip_prefixes = {}
  }
  ```
  EOF
  default = {
    public_ip_addresses = {}
    public_ip_prefixes = {}
  }
  type = object({
    public_ip_addresses = optional(map(object({
      create                     = bool
      name                       = string
      resource_group_name        = optional(string)
      zones                      = optional(list(string))
      domain_name_label          = optional(string)
      idle_timeout_in_minutes    = optional(number)
      prefix_name                = optional(string)
      prefix_resource_group_name = optional(string)
      prefix_id                  = optional(string)
    })), {})
    public_ip_prefixes = optional(map(object({
      create              = bool
      name                = string
      resource_group_name = optional(string)
      zones               = optional(list(string))
      length              = optional(number)
    })), {})
  })
}

variable "external_public_ips" {
  description = <<-EOF
  A map of objects defining external public IP addresses that are created outside this module.
  These IPs are referenced by their key and the module will look them up in the specified resource group.

  Each entry supports the following attributes:
  - `name`                - (`string`, required) the name of the existing Public IP resource.
  - `resource_group_name` - (`string`, required) the name of the Resource Group where the Public IP is located.
  EOF
  type = map(object({
    name                = string
    resource_group_name = string
  }))
  default = {}
}