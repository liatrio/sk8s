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
| [azurerm_container_registry.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry) | resource |
| [azurerm_private_endpoint.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_resource_group.self](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container_registry_name"></a> [container\_registry\_name](#input\_container\_registry\_name) | Name of Azure Container Registry. | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | n/a | <pre>object({<br>    virtual_network_name = string<br>    resource_group       = string<br>    subnet_id            = string<br>  })</pre> | n/a | yes |
| <a name="input_private_zone_id"></a> [private\_zone\_id](#input\_private\_zone\_id) | ID of private DNS zone for looking up container registry private endpoint. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of Azure resource group in which DNS zone resides. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acr_id"></a> [acr\_id](#output\_acr\_id) | n/a |
<!-- END_TF_DOCS -->