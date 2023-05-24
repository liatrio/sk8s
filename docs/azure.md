# Quickstart Guide

<details><summary id="local-workstation">Local Workstation</summary>

## Setting up your environment:
1. Install pre-requisites
2. Follow [these steps](https://learn.microsoft.com/en-us/azure/aks/kubernetes-service-principal?tabs=azure-cli) to generate the necessary Service Principals
3. Create a [PAT](https://docs.github.com/en/enterprise-server@3.4/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) or install a GitHub App with the desired scopes
4. Clone the repo and move to the project's `infra` folder:
```bash
git clone https://github.com/gh-runner-solutions/sk8s.git
cd sk8s/infra
```
5. (Optional, but highly recommended) create blob storage container for remote storage of Terraform state

## Spinning up the AKS cluster:
1. Update the `input.tfvars` file with your desired configuration
2. Run Terraform:
```bash
terraform init
terraform plan -var-file=input.tfvars
terraform apply -var-file=input.tfvars
```

## Connecting to the cluster:
1. (Optional if you do not already have a VPN solution in place) Create an Azure VPN Gateway as described [here](https://learn.microsoft.com/en-us/azure/vpn-gateway/tutorial-create-gateway-portal) and download the client configuration
2. Run the following command to obtain the cluster's `kubeconfig`:
```bash
az aks get-credentials --resource-group <your_RG> --name <cluster_name>
kubectl config use-context <kube_context>
```
3. Test the connection by running `kubectl get nodes`

## Deploying services:
1. Move to the `helm` folder and run: `helmfile sync`

</details>

<details><summary id="cicd-pipeline">CI/CD Pipeline</summary>

## Setting up a GitHub Action Runner on Local Workstation
1. Navigate to the Enterprise Settings page in your GitHub Enterprise instance
2. Navigate to the Actions section
3. Navigate to the Runners section and click the "Add Runner" button
4. Select the OS and architecture of the runner you want to use based on the machine you are running it on
5. Open a terminal or command prompt and follow the guide to install the runner
6. Ensure the label "bootstrap" is added to the runner during the configuration process, otherwise the default settings will be used
7. Congrats! You now have a runner that can be used to execute GitHub Actions workflows :tada:

## Deploying the AKS Cluster from GitHub Actions
1. Navigate to the repository
2. Go to the Actions tab and click on the "Terraform" workflow on the left
3. Using the "Run workflow" dropdown, select the branch you want to deploy
4. Go to the AWS Console and navigate to the AKS service
5. Validate that the cluster has been created and is in the `ACTIVE` state
6. Congrats! You now have an AKS cluster :tada:

## Setup the Azure VPN Client
[Azure VPN Gateway Setup Guide](https://learn.microsoft.com/en-us/azure/vpn-gateway/tutorial-create-gateway-portal)

## Deploying the GitHub Actions Runner Controller from GitHub Actions
1. Connect to the VPN Client using the profile for the AWS account you deployed the EKS cluster to
2. Navigate to the repository
3. Go to the Actions tab and click on the "Deploy to AKS" workflow on the left
4. Using the "Run workflow" dropdown, select the branch you want to deploy
5. Navigate to the Enterprise Settings page in your GitHub Enterprise instance
6. Navigate to the Actions section
7. Navigate to the Runners section and validate that the runners has been deployed
8. Congrats! You now have a GitHub Actions Runner Controller :tada:

## Cleanup
1. Open your terminal where your bootstrap runner is running and run the following command to remove the boostrap runner:
```bash
./config.sh remove --token <token> --unattended --url <repo_url>
```
2. Navigate to the Enterprise Settings page in your GitHub Enterprise instance
3. Navigate to the Actions section
4. Delete the bootstrap runner from the Runners section
5. Navigate to the repository
6. Navigate to the .github/workflows folder and update the terraform.yml and deploy.yml files to runs-on: self-hosted instead of runs-on: boostrap
7. Commit the changes and push to the repository
8. Validate the workflows run successfully
9. Congrats! You have now completed the deployment of ARC runners :tada:

</details>


For more details on the infrastructure created in Azure for the AKS cluster, please refer to the [Azure Kubernetes Cluster Architecture](../docs/azure_architecture.md) document in this repository.
