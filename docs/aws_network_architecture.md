# Network Architecture
The default configuration creates a VPC with public and private subnets spread across the specified Availability Zones. Egress traffic to the internet is permitted in order to pull down app images, including those for ARC and the GitHub Actions Runners, but the EKS cluster and its worker nodes are only accessible from within the VPC. Both Fargate and managed node groups are suported. Because the EKS cluster's API server endpoint is private, you need to have a client or site-to-site VPN connection set up.

In addition to the resources depicted in the following architecture diagram, the Terraform plan also creates a set of IAM roles for letting EKS manage worker nodes and other resources on your behalf, along with route tables for managing network traffic.

![SK8s Architecture](../imgs/k8s_arch.jpeg)

## Notes for Fully Private Clusters

When deploying an EKS cluster with a private API server endpoint, it is necessary to configure the security group managed by EKS to allow traffic from your client or site-to-site VPN. Since the VPN solution will attach a network interface to the VPC, source network address translation (SNAT) will also be applied, so the CIDR block to add to the security group is the IP address of the VPC.

For fully private clusters, where the cluster resources are only deployed in private subnets and there is no egress routing to the Internet, additional service endpoints will have to be added to the private subnets, as outlined [here](https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html).
