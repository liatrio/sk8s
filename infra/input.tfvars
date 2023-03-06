network_name        = "odinet"

public_network     = true

cidr_block          = "172.27.0.0/24"
subnet_range        = 27

availability_zones  = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
]

cluster_name        = "odin-cluster"
namespace           = "odin-core"

app_name            = "odinapp"

tags                = {
    "Environment" = "Odin"
}
