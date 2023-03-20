network_name        = "ghest"

// The subnet range must generate at least twice the number of subnets as the number of availability zones specified.
// So, for 3 AZs, we need 6 subnets (3 public + 3 private).
cidr_block          = "172.27.0.0/21"
subnet_range        = 24

availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"
]

cluster_name        = "ghest"
namespace           = "ghest"

instance_type       = "t3.xlarge"
disk_size           = 20

// The Project tag is required; we use it to generate unique IAM roles for the EKS cluster being created.
tags                = {
  "Project"     = "GHEST"
  "Environment" = "Testing"
}
