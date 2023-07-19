<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.1, <= 1.4.6 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.51.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.51.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_firewall.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall) | resource |
| [azurerm_firewall_policy.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy) | resource |
| [azurerm_firewall_policy_rule_collection_group.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) | resource |
| [azurerm_public_ip.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_route_table.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_subnet_route_table_association.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_firewall.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/firewall) | data source |
| [azurerm_resource_group.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_rules"></a> [application\_rules](#input\_application\_rules) | List of application rules to be passed into the firewall policy | <pre>list(object({<br>    name              = string<br>    source_addresses  = list(string)<br>    destination_fqdns = list(string)<br>    protocols         = object({<br>      port = string<br>      type = string<br>    })<br>  }))</pre> | `null` | no |
| <a name="input_association_subnet_id"></a> [association\_subnet\_id](#input\_association\_subnet\_id) | Subnet id to associate to the route table | `string` | n/a | yes |
| <a name="input_firewall"></a> [firewall](#input\_firewall) | Firewall to use for outbound traffic. | <pre>object({<br>    name           = string<br>    resource_group = string<br>  })</pre> | `null` | no |
| <a name="input_network"></a> [network](#input\_network) | n/a | <pre>object({<br>    virtual_network_name = string<br>    subnet_name          = string<br>    subnet_id            = string<br>    managed              = bool<br>  })</pre> | n/a | yes |
| <a name="input_network_rules"></a> [network\_rules](#input\_network\_rules) | List of network rules to be passed into the firewall policy | <pre>list(object({<br>      name                  = string<br>      protocols             = list(string)<br>      source_addresses      = list(string)<br>      destination_addresses = list(string)<br>      destination_ports     = list(string)<br>  }))</pre> | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of Azure resource group in which DNS zone resides. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_route_table_id"></a> [route\_table\_id](#output\_route\_table\_id) | n/a |
<!-- END_TF_DOCS -->