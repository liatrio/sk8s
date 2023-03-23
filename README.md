# sk8s
This project is used for deploying a Kubernetes cluster in a greenfield AWS environment with Terraform and setting up the GitHub Actions Runner Controller (ARC) to manage runners on the cluster. Aside from a few configuration options, everything about the creation process is automated for you. For instructions on how to get started with EKS, clone this repo and follow the steps in the [Quickstart Guide](#quickstart-guide) below.

## Prerequisites
The prerequisites are split into two categories: the software tools neeeded to execute our infrastructure-as-code, and the account settings and credentials needed to interact with AWS and GitHub.

### Command-Line Tools
Terraform is used for the IaC, so you will have to install it either on your local workstation or in your CI/CD pipeline by clicking the link below. If you are leveraging GitHub-hosted runners already, or managing a fleet of VM-based self-hosted runners, then you can use the [setup-terraform](https://github.com/hashicorp/setup-terraform) action to begin migrating your workload to EKS and ARC.

Once the EKS cluster is up and running, the AWS CLI is needed to obtain the cluster's `kubeconfig` in order to connect to it using the Kubernetes command-line utility, `kubectl`.

Helm is used to deploy the cluster autoscaler as well as ARC and its dependencies. For convenience, a Helmfile is included that runs through each of the charts in the correct order of deployment. All other interaction with the cluster (e.g. troubleshooting failed deployments or permissions issues) is done using `kubectl`.

#### Required
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) (tested against v2.8.9)
- [Helm](https://helm.sh/docs/intro/install/) (tested against v3.11.2)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (tested against v1.25.2)
- [Terraform](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform) (v1.3.1 - v1.3.x)

#### Optional
- [AWS IAM Authenticator for Kubernetes](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html) (tested against v0.5.3)
- [Helmfile](https://helmfile.readthedocs.io/en/latest/) (v0.151.0)

Helmfile is recommended to simplify deployment of the cluster autoscaler and ARC; if you choose to use it, be sure to also install the Helm Diff plugin (`helm plugin install https://github.com/databus23/helm-diff`).

### Account Access and Credentials
In order to deploy the infrastructure using Terraform, you must have an AWS account with appropriate permissions to spin up the EKS cluster and its worker nodes, along with the host VPC, subnets, NAT gateways, etc. Terraform can authenticate using its AWS provider in a number of different ways, as outlined [here](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration). In keeping with security best practices, we recommend that you avoid hardcoding AWS credentials anywhere in your Terraform configuration and instead use environment variables or instance profile credentials.

ARC runners can be deployed at the repository, organization, or enterprise level; the exact GitHub permissions required are listed [here](https://github.com/actions/actions-runner-controller/blob/master/docs/authenticating-to-the-github-api.md). You can use either a Personal Access Token (PAT) or install a GitHub App to authenticate the controller.

## Quickstart Guide

### Setting up your environment:
1. Install [pre-requisites](#pre-requisites)
2. Follow [these steps](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html) to generate AWS credentials
3. Create a [PAT](https://docs.github.com/en/enterprise-server@3.4/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) or install a GitHub App with the desired scopes
4. Clone the repo and move to the project's `infra` folder:
```bash
git clone https://github.com/gh-runner-solutions/sk8s.git
cd sk8s/infra
```
5. (Optional, but highly recommended) create an S3 bucket for remote storage of Terraform state

### Spinning up the EKS cluster:
1. Update the `input.tfvars` file with your desired configuration
2. Run Terraform:
```bash
terraform init
terraform plan -var-file=input.tfvars
terraform apply -var-file=input.tfvars
```

### Connecting to the cluster:
1. (Optional if you do not already have a VPN solution in place) Create an AWS Client VPN as described [here](docs/aws_client_vpn.md) and attach it to the newly created VPC
2. Run the following command to obtain the cluster's `kubeconfig`:
```bash
aws eks --region <your_region> update-kubeconfig --name <cluster_name>
kubectl config use-context <kube_context>
```
3. Test the connection by running `kubectl get nodes`

### Deploying services:
1. Move to the `helm` folder and run: `helmfile sync`

## AWS Resources
The Terraform plan creates the following resources in your AWS account:
- VPC:
  - Public and private subnets (1 per Availability Zone)
  - NAT Gateways (1 per public subnet)
  - Route tables
  - Internet Gateway
  - Security groups
- IAM:
  - Roles and policies for EKS and worker nodes
  - Service account roles for cluster autoscaler and ALB Ingress Controller
- EKS:
  - Control plane
  - Managed node group or Fargate profile
    - EC2 instances
    - EBS volumes
    - Autoscaling group

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
