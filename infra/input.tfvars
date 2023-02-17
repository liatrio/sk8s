network_name        = "demonet"

cidr_block          = "172.27.0.0/16"
subnet_range        = 20

availability_zones  = [
    "us-west-2a",
    "us-west-2b",
    "us-west-2c"
]

cluster_name        = "democluster"
namespace           = "demo"

app_name            = "demoapp"

tags                = {
    "Environment" = "demo"
}
