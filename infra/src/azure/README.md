<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.1, <= 1.4.6 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.51.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acr"></a> [acr](#module\_acr) | ../../modules/azure/acr | n/a |
| <a name="module_aks"></a> [aks](#module\_aks) | ../../modules/azure/aks | n/a |
| <a name="module_dns"></a> [dns](#module\_dns) | ../../modules/azure/dns | n/a |
| <a name="module_firewall"></a> [firewall](#module\_firewall) | ../../modules/azure/firewall | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../../modules/azure/network | n/a |
| <a name="module_vpn-gateway"></a> [vpn-gateway](#module\_vpn-gateway) | ../../modules/azure/vpn-gateway | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_node_pools"></a> [additional\_node\_pools](#input\_additional\_node\_pools) | Additional node pools to create | <pre>map(object({<br>    auto_scaler_profile = object({<br>      enabled        = bool<br>      max_node_count = optional(number, 3)<br>      min_node_count = optional(number, 1)<br>    })<br>    node_count = optional(number, 3)<br>    node_size  = optional(string, "Standard_D2s_v3")<br>    node_os    = optional(string, "Linux")<br>    priority   = object({<br>      spot_enabled = bool<br>      spot_price   = optional(number, -1)<br>    })<br>    zones = optional(list(string), ["1", "2", "3"])<br>  }))</pre> | `{}` | no |
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | n/a | `string` | n/a | yes |
| <a name="input_application_rules"></a> [application\_rules](#input\_application\_rules) | List of application rules to be passed into the firewall policy | <pre>list(object({<br>    name              = string<br>    source_addresses  = list(string)<br>    destination_fqdns = list(string)<br>    protocols         = object({<br>      port = string<br>      type = string<br>    })<br>  }))</pre> | `null` | no |
| <a name="input_container_insights_enabled"></a> [container\_insights\_enabled](#input\_container\_insights\_enabled) | Determine whether container insights will be enabled for the cluster | `bool` | `false` | no |
| <a name="input_default_node_pool"></a> [default\_node\_pool](#input\_default\_node\_pool) | Default node pool configuration | <pre>object({<br>    auto_scaler_profile = object({<br>      enabled        = bool<br>      expander       = optional(string, "random")<br>      max_node_count = optional(number, 3)<br>      min_node_count = optional(number, 1)<br>    })<br>    node_count = optional(number, 3)<br>    node_size  = string<br>    zones      = optional(list(string))<br>  })</pre> | <pre>{<br>  "auto_scaler_profile": {<br>    "enabled": true,<br>    "max_node_count": 9,<br>    "min_node_count": 3<br>  },<br>  "node_size": "Standard_D2s_v3",<br>  "zones": [<br>    "1",<br>    "2",<br>    "3"<br>  ]<br>}</pre> | no |
| <a name="input_firewall"></a> [firewall](#input\_firewall) | Firewall to use for outbound traffic. | <pre>object({<br>    name           = string<br>    resource_group = string<br>  })</pre> | `null` | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Name of virtual network. | `string` | n/a | yes |
| <a name="input_network_rules"></a> [network\_rules](#input\_network\_rules) | List of network rules to be passed into the firewall policy | <pre>list(object({<br>      name                  = string<br>      protocols             = list(string)<br>      source_addresses      = list(string)<br>      destination_addresses = list(string)<br>      destination_ports     = list(string)<br>  }))</pre> | `null` | no |
| <a name="input_peering_connection"></a> [peering\_connection](#input\_peering\_connection) | Virtual network to peer with. | <pre>object({<br>    virtual_network_name = string<br>    subnet_name          = string<br>    resource_group       = string<br>  })</pre> | `null` | no |
| <a name="input_private_cluster"></a> [private\_cluster](#input\_private\_cluster) | Determine whether aks cluster will be private or public | `bool` | `true` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of Azure resource group in which to create the network. | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnets to create in the virtual network. | <pre>list(object({<br>    name           = string<br>    address_prefix = string<br>    attributes     = object({<br>       routing     = string<br>       managed     = bool<br>       services    = list(string)<br>    })<br>  }))</pre> | n/a | yes |
| <a name="input_system_managed_dns"></a> [system\_managed\_dns](#input\_system\_managed\_dns) | Determine if dns zone is managed by system | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | n/a | yes |
| <a name="input_vpn-gateway"></a> [vpn-gateway](#input\_vpn-gateway) | Vpn-gateway configuration to connect to the cluster | <pre>object({<br>      name          = string<br>      address_space = string<br>      tenant_id     = string<br>    })</pre> | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->