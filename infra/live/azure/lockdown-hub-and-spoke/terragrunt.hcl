terraform {
  source = "../../..//src/azure"
}

remote_state {
  backend = "azurerm"
  config  = {
    resource_group_name  = "sk8s"
    storage_account_name = "sk8sinfrastate"
    container_name       = "tfstate"
    key                  = "test.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  resource_group_name = "sk8s-cluster"
  network_name        = "sk8s-cluster-vnet"
  address_space       = "10.1.0.0/16"
  system_managed_dns  = false
  subnets             = [
    {
      name           = "cidr"
      address_prefix = "10.1.64.0/18"
      attributes     = {
        routing  = "internal"
        managed  = true
        services = [ "aks" ]
      }
    },
    {
      name           = "nodes"
      address_prefix = "10.1.0.0/18"
      attributes     = {
        routing  = "external"
        managed  = false
        services = [ "aks" ]
      }
    },
    {
      name           = "aci"
      address_prefix = "10.1.128.0/18"
      attributes     = {
        routing  = "external"
        managed  = false
        services = [ "aks" ] 
      }
    },
    {
      name           = "extras"
      address_prefix = "10.1.192.0/19"
      attributes     = {
        routing  = "internal"
        managed  = false
        services = [ "acr" ]
      }
    },
    {
      name           = "GatewaySubnet"
      address_prefix = "10.1.224.0/24"
      attributes     = {
        routing  = "external"
        managed  = false
        services = [ "gateway" ]
      }
    },
    {
      name           = "AzureFirewallSubnet"
      address_prefix = "10.1.225.0/24"
      attributes     = {
        routing  = "external"
        managed  = false
        services = [ "firewall" ]
      }
    }
  ]

  peering_connection = {
    virtual_network_name = "sk8s-vnet"
    subnet_name          = "primary"
    resource_group       = "sk8s"
  }
  firewall = {
    name           = "sk8s-firewall"
    resource_group = "sk8s-cluster"
  }
  tags = {
    project = "Sk8s"
    owner   = "GitHub Practice"
  }

  network_rules = [
    {
      name                  = "all-udp"
      protocols             = [ "UDP" ]
      source_addresses      = [ "*" ]
      destination_addresses = [ "*" ]
      destination_ports     = ["53"]
    },
    {
      name                  = "dns-monitor"
      protocols             = [ "TCP" ]
      source_addresses      = [ "*" ]
      destination_addresses = [ "AzureMonitor" ]
      destination_ports     = ["443"]
    },
    {
      name                  = "all"
      protocols             = [ "TCP" ]
      source_addresses      = [ "*" ]
      destination_addresses = [ "*" ]
      destination_ports     = ["443"]
    }
  ]

  application_rules = [
    {
      name              = "mcr"
      source_addresses  = [ "*" ]
      destination_fqdns = [ "mcr.microsoft.com" ]
      protocols         = {
        port = "443"
        type = "Https"
      }
    },
    {
      name              = "mcr-data"
      source_addresses  = [ "*" ]
      destination_fqdns = [ "*.data.mcr.microsoft.com" ]
      protocols         = {
        port = "443"
        type = "Https"
      }
    },
    {
      name              = "mgmt"
      source_addresses  = [ "*" ]
      destination_fqdns = [ "management.azure.com" ]
      protocols         = {
        port = "443"
        type = "Https"
      }
    },
    {
      name              = "login"
      source_addresses  = [ "*" ]
      destination_fqdns = [ "login.microsoftonline.com	" ]
      protocols         = {
        port = "443"
        type = "Https"
      }
    },
    {
      name              = "pkgs"
      source_addresses  = [ "*" ]
      destination_fqdns = [ "packages.microsoft.com" ]
      protocols         = {
        port = "443"
        type = "Https"
      }
    },
    {
      name              = "acs"
      source_addresses  = [ "*" ]
      destination_fqdns = [ "acs-mirror.azureedge.net" ]
      protocols         = {
        port = "443"
        type = "Https"
      }
    },
    {
      name              = "ubuntu"
      source_addresses  = [ "*" ]
      destination_fqdns = [ "security.ubuntu.com", "azure.archive.ubuntu.com", "changelogs.ubuntu.com" ]
      protocols         = {
        port = "80"
        type = "Http"
      }
    },
    {
      name              = "vault"
      source_addresses  = [ "*" ]
      destination_fqdns = [ "vault.azure.net" ]
      protocols         = {
        port = "443"
        type = "Https"
      }
    }
  ]
}
