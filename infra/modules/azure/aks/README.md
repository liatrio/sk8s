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
| [azurerm_kubernetes_cluster.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_kubernetes_cluster_node_pool.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |
| [azurerm_role_assignment.aci-custom-route](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.aci-default-route](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_client_config.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_resource_group.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of Azure Container Registry. | `string` | n/a | yes |
| <a name="input_default_node_pool"></a> [default\_node\_pool](#input\_default\_node\_pool) | n/a | <pre>object({<br>    auto_scaler_profile = object({<br>      enabled        = bool<br>      expander       = optional(string, "random")<br>      max_node_count = optional(number, 3)<br>      min_node_count = optional(number, 1)<br>    })<br>    node_count = optional(number, 3)<br>    node_size  = string<br>    zones      = optional(list(string))<br>  })</pre> | n/a | yes |
| <a name="input_identity"></a> [identity](#input\_identity) | n/a | <pre>object({<br>    assignment  = string<br>    id          = optional(string)<br>  })</pre> | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | n/a | <pre>object({<br>    virtual_network_name = string<br>    subnet_id            = string<br>    user_defined_routing = optional(bool, false)<br>    dns_service_ip       = string<br>    docker_bridge_cidr   = string<br>    plugin               = string<br>    pod_cidr             = optional(string)<br>    service_cidr         = string<br>  })</pre> | n/a | yes |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | n/a | <pre>map(object({<br>    auto_scaler_profile = object({<br>      enabled        = bool<br>      max_node_count = optional(number, 3)<br>      min_node_count = optional(number, 1)<br>    })<br>    node_count = optional(number, 3)<br>    node_size  = string<br>    priority   = object({<br>      spot_enabled = bool<br>      spot_price   = optional(number, -1)<br>    })<br>    subnet_name = optional(string)<br>    zones       = optional(list(string))<br>  }))</pre> | `{}` | no |
| <a name="input_private_cluster"></a> [private\_cluster](#input\_private\_cluster) | Determine whether aks cluster will be private or public | `bool` | n/a | yes |
| <a name="input_private_zone_id"></a> [private\_zone\_id](#input\_private\_zone\_id) | ID of private DNS zone for looking up container registry private endpoint. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of Azure resource group in which DNS zone resides. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_virtual_nodes"></a> [virtual\_nodes](#input\_virtual\_nodes) | n/a | <pre>object({<br>    enabled     = bool<br>    subnet_name = optional(string)<br>  })</pre> | <pre>{<br>  "enabled": false<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_client_certificate"></a> [client\_certificate](#output\_client\_certificate) | n/a |
| <a name="output_kube_config"></a> [kube\_config](#output\_kube\_config) | n/a |
<!-- END_TF_DOCS -->