# sk8s

// Placeholder for badges

## Table of Contents
- [sk8s](#sk8s)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Prerequisites](#prerequisites)
    - [Command-Line Tools](#command-line-tools)
      - [Required](#required)
      - [Optional](#optional)
    - [Account Access and Credentials](#account-access-and-credentials)
      - [AWS](#aws)
      - [Azure](#azure)
      - [GitHub](#github)

## Overview
This project is used for deploying a Kubernetes cluster in a greenfield AWS or Azure environment with Terraform, and setting up the GitHub Actions Runner Controller (ARC) to manage runners on the cluster. Aside from a few configuration options, everything about the creation process is automated for you. For instructions on how to get started with each cloud provider's Kubernetes service offering, clone this repository and follow the steps in the relevant Quickstart guides:

- [AWS Quickstart](docs/aws.md)
- [Azure Quickstart](docs/azure.md)

## Prerequisites
The prerequisites are split into two categories: the software tools neeeded to execute our infrastructure-as-code, and the account settings and credentials needed to interact with AWS/Azure and GitHub.

### Command-Line Tools
Terraform is used for the IaC, so you will have to install it either on your local workstation or in your CI/CD pipeline by clicking the link below. If you are leveraging GitHub-hosted runners already, or managing a fleet of VM-based self-hosted runners, then you can use the [setup-terraform](https://github.com/hashicorp/setup-terraform) action to begin migrating your workload to Kubernetes and ARC.

Terragrunt is necessary when managing multiple environments. It is a thin wrapper around Terraform that allows you to keep your Terraform code DRY by using shared modules and configuration files. It also provides a number of other features that make it easier to work with Terraform in a team setting, such as locking and state management.

Once the cluster is up and running, the AWS CLI is needed to obtain the cluster's `kubeconfig` in order to connect to it using the Kubernetes command-line utility, `kubectl`.

Helm is used to deploy the cluster autoscaler as well as ARC and its dependencies. For convenience, a Helmfile is included that runs through each of the charts in the correct order of deployment. All other interaction with the cluster (e.g. troubleshooting failed deployments or permissions issues) is done using `kubectl`.

#### Required
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) (tested against v2.8.9)  
OR  
[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (tested against v2.28.1)
- [Helm](https://helm.sh/docs/intro/install/) (tested against v3.11.2)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (tested against v1.25.2)
- [Terraform](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform) (v1.3.1 - v1.3.x)
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) (v0.39.0 - v0.39.x)

#### Optional
- [AWS IAM Authenticator for Kubernetes](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html) (tested against v0.5.3)
- [Helmfile](https://helmfile.readthedocs.io/en/latest/) (v0.151.0)

Helmfile is recommended to simplify deployment of the cluster autoscaler and ARC; if you choose to use it, be sure to also install the Helm Diff plugin (`helm plugin install https://github.com/databus23/helm-diff`).

### Account Access and Credentials

#### AWS
In order to deploy the infrastructure using Terraform, you must have an AWS account with appropriate permissions to spin up the EKS cluster and its worker nodes, along with the host VPC, subnets, NAT gateways, etc. Terraform can authenticate using its AWS provider in a number of different ways, as outlined [here](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration). In keeping with security best practices, we recommend that you avoid hardcoding AWS credentials anywhere in your Terraform configuration and instead use environment variables or instance profile credentials. 

#### Azure
An Azure Kubernetes cluster uses a pair of system-assigned managed identities with the permissions necessary to modify the existing network and create the cluster infrastructure listed below. This is enough for a basic Kubernetes cluster configuration, but a user-created service principal is required to take advantage of more advanced features (e.g. the ACI Connector).

The managed identity or service principal assigned to AKS is responsible for creating the node pool VMs, any attached storage devices, and the network links for the Kubernetes API server. Therefore, it must be given Contributor access to the resource group that contains the cluster’s infrastructure resources (this RG is typically prefixed by MC_). When using Azure CNI, this SP must also be granted the built-in role of Network Contributor on the private virtual network.

In order to leverage Azure Container Instances for burstable workloads, a second managed identity must be created with Contributor access to the cluster resource group. As before, when deploying container instances in the virtual private network, the Network Contributor role must also be assigned to the SP.

#### GitHub

ARC runners can be deployed at the repository, organization, or enterprise level; the exact GitHub permissions required are listed [here](https://github.com/actions/actions-runner-controller/blob/master/docs/authenticating-to-the-github-api.md). You can use either a Personal Access Token (PAT) or install a GitHub App to authenticate the controller.
