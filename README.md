# sk8s

Deploy a simple Kubernetes cluster in a greenfield AWS environment with Terraform.

## Networking

The default configuration creates a VPC with public and private subnets spread across the specified Availability Zones. Egress traffic to the internet is permitted in order to pull down app images, including those for ARC and the GitHub Actions Runners, but the EKS cluster and its worker nodes are only accessible from within the VPC. Both Fargate and managed node groups are suported. Because the EKS cluster's API server endpoint is private, you need to have a client or site-to-site VPN connection set up.

In addition to the resources depicted in the following architecture diagram, the Terraform plan also creates a set of IAM roles for letting EKS manage worker nodes and other resources on your behalf, along with route tables for managing network traffic.

![SK8s Architecture](imgs/k8s_arch.jpeg)

### Notes for Fully Private Clusters

When deploying an EKS cluster with a private API server endpoint, it is necessary to configure the security group managed by EKS to allow traffic from your client or site-to-site VPN. Since the VPN solution will attach a network interface to the VPC, source network address translation (SNAT) will also be applied, so the CIDR block to add to the security group is the IP address of the VPC.

For fully private clusters, where the cluster resources are only deployed in private subnets and there is no egress routing to the Internet, additional service endpoints will have to be added to the private subnets, as outlined [here](https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html).

## IAM Roles and Policies

In addition to the network requirements outlined above, a set of IAM policies must be attached to the EKS cluster being deployed to manage the lifecycle of the worker nodes and pods being scheduled on them. In order for the cluster to manage those resources on our behalf we must attach the following:
* arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
* arn:aws:iam::aws:policy/AmazonEKSServicePolicy

The `AmazonEKSClusterPolicy` allows EKS to modify the EC2 instances that make up the node groups so that they can register themselves to the cluster. It also allows the cluster to manage auto-scaling and elastic load balancing of services. The `AmazonEKSServicePolicy` allows it to update the Kubernetes version during a planned upgrade, enable private endpoint networking for its API server, log events for the control plane, etc.

Worker nodes require a separate set of policies to operate, and they are different for managed node groups and Fargate. For managed node groups, three additional policies must be applied to the IAM role governing access to AWS services:
* arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
* arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
* arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

The `AmazonEKSWorkerNodePolicy` is necessary to accurately identify the node joining the cluster based on its volume and network information. The `AmazonEKS_CNI_Policy` permits the creation of elastic network interfaces as well as the allocation of IP addresses for pods scheduled to run on the cluster. Pulling images from ECR onto the worker nodes requires read-only permissions to the container registries for the individual applications, and is granted by the `AmazonEC2ContainerRegistryReadOnly` policy.

## Creating a Client VPN

Instructions for creating a Client VPN in AWS for testing can be found [here](docs/clientvpn-setup.md).

## Installing ARC

Instructions for installing the GitHub Actions Runner Controller on EKS can be found [here](docs/deployment.md).

## Pre-requisites
* AWS credentials to authenticate the [terraform provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#provider-configuration)
* [An s3 bucket for the terraform backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3) (technically optional, but highly recommended)
* [GitHub credentials](https://github.com/actions/actions-runner-controller/blob/master/docs/authenticating-to-the-github-api.md) for ARC

### Tools
- [Terraform](https://www.terraform.io/downloads.html) (v1.3.1+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (v1.24.0+)
- [helm](https://helm.sh/docs/intro/install/) (v3.7.0+) (optional)
- [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) (v2.2.0+) (optional)
- [aws-iam-authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html) (v0.5.3+) (optional)

### AWS
- [AWS-S3](https://aws.amazon.com/s3/) bucket for Terraform state

## AWS Resources

- VPC (public and private subnets, NAT gateways, route tables, etc.)
- IAM roles and policies for EKS
- EKS cluster
- Managed node groups (worker nodes) or Fargate profile
