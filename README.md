# sk8s

## Table of Contents
- [sk8s](#sk8s)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Prerequisites](#prerequisites)
    - [Command-Line Tools](#command-line-tools)
      - [Required](#required)
      - [Optional](#optional)
    - [Account Access and Credentials](#account-access-and-credentials)
  - [Quickstart Guides](#quickstart-guides)
    - [Local Workstation](#local-workstation)
    - [CI/CD Pipeline](#cicd-pipeline)
  - [AWS Resources](#aws-resources)

## Overview
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

## Quickstart Guides

<details><summary id="local-workstation">Local Workstation</summary>

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

</details>

<details><summary id="cicd-pipeline">CI/CD Pipeline</summary>

### Setting up a GitHub Action Runner on Local Workstation
1. Navigate to the Enterprise Settings page in your GitHub Enterprise instance
2. Navigate to the Actions section
3. Navigate to the Runners section and click the "Add Runner" button
4. Select the OS and architecture of the runner you want to use based on the machine you are running it on
5. Open a terminal or command prompt and follow the guide to install the runner
6. Ensure the label "bootstrap" is added to the runner during the configuration process, otherwise the default settings will be used
7. Congrats! You now have a runner that can be used to execute GitHub Actions workflows :tada:

### Deploying the EKS Cluster from GitHub Actions
1. Navigate to the repository [dxc-arc-runners](https://github.dxc.com/devcloud/dxc-arc-runners)
2. Go to the Actions tab and click on the "Terraform" workflow on the left
3. Using the "Run workflow" dropdown, select the branch you want to deploy
4. Go to the AWS Console and navigate to the EKS service
5. Validate that the cluster has been created and is in the `ACTIVE` state
6. Congrats! You now have an EKS cluster :tada:

### Setup the AWS VPN Client
[AWS VPN Setup Guide](/docs/clientvpn-setup.md)

### Deploying the GitHub Actions Runner Controller from GitHub Actions
1. Connect to the VPN Client using the profile for the AWS account you deployed the EKS cluster to
2. Navigate to the repository [dxc-arc-runners](https://github.dxc.com/devcloud/dxc-arc-runners)
3. Go to the Actions tab and click on the "Deploy to EKS" workflow on the left
4. Using the "Run workflow" dropdown, select the branch you want to deploy
5. Navigate to the Enterprise Settings page in your GitHub Enterprise instance
6. Navigate to the Actions section
7. Navigate to the Runners section and validate that the runners has been deployed
8. Congrats! You now have a GitHub Actions Runner Controller :tada:

### Cleanup
1. Open your terminal where your bootstrap runner is running and run the following command to remove the boostrap runner:
```bash
./config.sh remove --token <token> --unattended --url https://github.dxc.com/devcloud/dxc-arc-runners
```
2. Navigate to the Enterprise Settings page in your GitHub Enterprise instance
3. Navigate to the Actions section
4. Delete the bootstrap runner from the Runners section
5. Navigate to the repository [dxc-arc-runners](https://github.dxc.com/devcloud/dxc-arc-runners)
6. Navigate to the .github/workflows folder and update the terraform.yml and deploy.yml files to runs-on: self-hosted instead of runs-on: boostrap
7. Commit the changes and push to the repository
8. Validate the workflows run successfully
9. Congrats! You have now completed the deployment of ARC runners :tada:

### Navigate to the repository [dxc-arc-runners]()

</details>

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

For more details on the network infrastructure created in AWS for the EKS cluster, please refer to the [Network Architecture](docs/network_architecture.md) document in this repository. All IAM roles and policies created by the Terraform plan are necessary for the cluster to manage its own resources, including worker nodes, autoscaling, and ingress. Information on the IAM permissions required for EKS is available [here](docs/iam_permissions.md).
