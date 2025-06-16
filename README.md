# cloud_ngfw

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_swfw-modules_cloudngfw"></a> [swfw-modules\_cloudngfw](#module\_swfw-modules\_cloudngfw) | PaloAltoNetworks/swfw-modules/azurerm//modules/cloudngfw | 3.3.7 |

## Resources

| Name | Type |
|------|------|
| [azurerm_client_config.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_public_ip.pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) | data source |
| [azurerm_resource_group.resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_resource_group.resource_group_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_resource_group.resource_group_pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.trusted](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_subnet.untrusted](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudngfws"></a> [cloudngfws](#input\_cloudngfws) | A map of objects defining the configuration for Cloud Next-Gen Firewalls (cloudngfws) in the environment.<br/><br/>Each cloudngfw entry in the map supports the following attributes:<br/><br/>- `name`                            - (`string`, required) the name of the Palo Alto Next Generation Firewall instance.<br/>- `attachment_type`                 - (`string`, required) specifies whether the firewall is attached to a Virtual Network<br/>- `resource_group_name_key`         - (`string`, required) the name of the Resource Group where the firewall will be created.<br/>- `resource_group_name_network_key` - (`string`, required) the name of the Resource Group where the Virtual Network is located.<br/>                                      (`vnet`) or a Virtual WAN (`vwan`).<br/>- `resource_group_name_pip_key`     - (`string`, optional) the name of the Resource Group where the Public IP resource is located if is different from the<br/>                                      Resource Group of the Virtual Network.<br/>                                      This is used only when the variable `public_ip_keys` is utilized.<br/>- `virtual_network_key`             - (`string`, optional) key referencing the Virtual Network associated with this firewall.<br/>                                      Required if the `attachment_type` is `vnet`.<br/>- `untrusted_subnet_key`            - (`string`, optional) key of the subnet designated as untrusted within the Virtual Network.<br/>- `trusted_subnet_key`              - (`string`, optional) key of the subnet designated as trusted within the Virtual Network.<br/>- `virtual_hub_key`                 - (`string`, optional) key of the Virtual Hub within a vWAN where to place the Cloud NGFW.<br/>- `management_mode`                 - (`string`, required) defines the management mode for the firewall. When set to `panorama`,<br/>                                      the firewall's policies are managed via Panorama.<br/>- `cloudngfw_config`                - (`object`, required) configuration details for the Cloud NGFW instance, with the<br/>                                      following properties:<br/><br/>  - `panorama_base64_config`        - (`string`, optional) the Base64-encoded configuration for connecting to Panorama server.<br/>                                      This field is required when `management_mode` is set to `panorama`.<br/>  - `rulestack_id`                  - (`string`, optional) the ID of the Local Rulestack used to configure this Firewall<br/>                                      Resource. This field is required when `management_mode` is set to `rulestack`.<br/>  - `create_public_ip`              - (`bool`, optional, defaults to `true`) controls if the Public IP resource is created or<br/>                                      sourced. This field is ignored when the variable `public_ip_keys` is used.<br/>  - `public_ip_name`                - (`string`, optional) the name of the Public IP resource. This field is required unless<br/>                                      the variable `public_ip_keys` is used.<br/>  - `public_ip_resource_group_name` - (`string`, optional) the name of the Resource Group hosting the Public IP resource.<br/>                                      This is used only for sourced resources.<br/>  - `public_ip_keys`                - (`list`, optional) the keys referencing Public IP addresses from `public_ip` module.<br/>                                      Property is used when Public IP is not created or sourced within `cloudngfw` module.<br/>  - `egress_nat_ip_keys`            - (`list`, optional) the keys referencing egress NAT Public IP addresses from `public_ip`<br/>                                      module. Property is used when Public IP is not created or sourced within `cloudngfw`<br/>                                      module.<br/>  - `trusted_address_ranges`        - (`list`, optional) a list of public IP address ranges that will be treated as internal<br/>                                      traffic by Cloud NGFW in addition to RFC 1918 private subnets. Each list entry has to be<br/>                                      in a CIDR format.<br/>  - `destination_nats`              - (`map`, optional) defines one or more destination NAT configurations. Each object<br/>                                      supports the following properties:<br/><br/>    - `destination_nat_name`     - (`string`, required) the name of the Destination NAT. Must be unique within this map.<br/>    - `destination_nat_protocol` - (`string`, required) the protocol for this Destination NAT. Possible values are `TCP` or<br/>                                   `UDP`.<br/>    - `frontend_public_ip_key`   - (`string`, optional) the key referencing the Public IP that receives the traffic.<br/>                                   This is used only when the variable `public_ip_ids` is utilized.<br/>    - `frontend_port`            - (`number`, required) the port on which traffic will be received. Must be in the range from<br/>                                   1 to 65535.<br/>    - `backend_ip_address`       - (`string`, required) the IPv4 address to which traffic will be forwarded.<br/>    - `backend_port`             - (`number`, required) the port number to which traffic will be sent.<br/>                                   Must be in the range 1 to 65535.<br/>- `tags`                            - (`map`, optional) a map of tags to assign to the Cloud NGFW instance. | <pre>map(object({<br/>    name                            = string<br/>    attachment_type                 = string<br/>    resource_group_name_key         = string<br/>    resource_group_name_network_key = optional(string)<br/>    resource_group_name_pip_key     = optional(string)<br/>    virtual_network_key             = optional(string)<br/>    untrusted_subnet_key            = optional(string)<br/>    trusted_subnet_key              = optional(string)<br/>    virtual_hub_key                 = optional(string)<br/>    management_mode                 = string<br/>    cloudngfw_config = object({<br/>      plan_id                       = optional(string)<br/>      marketplace_offer_id          = optional(string)<br/>      panorama_base64_config        = optional(string)<br/>      rulestack_id                  = optional(string)<br/>      create_public_ip              = optional(bool, false)<br/>      public_ip_name                = optional(string)<br/>      public_ip_resource_group_name = optional(string)<br/>      public_ip_keys                = optional(list(string))<br/>      egress_nat_ip_keys            = optional(list(string))<br/>      trusted_address_ranges        = optional(list(string))<br/>      destination_nats = optional(map(object({<br/>        destination_nat_name     = string<br/>        destination_nat_protocol = string<br/>        frontend_public_ip_key   = optional(string)<br/>        frontend_port            = number<br/>        backend_ip_address       = string<br/>        backend_port             = number<br/>      })), {})<br/>    })<br/>    tags = optional(map(string))<br/>  }))</pre> | n/a | yes |

## Sincronización automática de la carpeta Tools

La carpeta `Tools` se sincroniza automáticamente con el contenido de la carpeta `Tools` del repositorio externo [terraform_tools](https://github.com/rfernandezdo/terraform_tools).

Para actualizar el contenido de `Tools` a la última versión del repositorio externo, ejecuta:

```bash
git subtree pull --prefix=Tools terraform_tools main --squash
```
