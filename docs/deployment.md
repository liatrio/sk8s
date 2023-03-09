# Deploying EKS and ARC

Deploying this solution consists of 3 primary steps:
1. Applying EKS Terraform config
2. Deploying Actions Runner Controller (ARC)
3. Deploying runners

## Apply EKS Terraform config
### Set up Terraform provider and backend
Clone or make a copy of the Terraform config in the `infra` directory.
Create a new file (such as `provider.tf`) and within that file add [provider configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#provider-configuration) and [backend configuration](https://developer.hashicorp.com/terraform/language/settings/backends/s3) (for terraform state).

If state management isn't desired, the backend configuration can be omitted and Terraform will store state locally on the machine that runs the Terraform commands.


### Terraform Plan/Apply
Once the backend and provider are configured, run:
```shell
terraform init
terraform plan
```
Validate there are no errors, then run:
```shell
terraform apply
```

## Deploy Actions Runner Controller (ARC)
Follow the ARC [documentation on Installing ARC](https://github.com/actions/actions-runner-controller/blob/master/docs/installing-arc.md) 
to set up the controller.

Follow the ARC [documentation on Authenticating to the GitHub API](https://github.com/actions/actions-runner-controller/blob/master/docs/authenticating-to-the-github-api.md) 
to set up credentials for ARC to communicate with GitHub. 


## Deploy runners
Follow the ARC [documentation on Deploying ARC runners](https://github.com/actions/actions-runner-controller/blob/master/docs/deploying-arc-runners.md)
to deploy runners.
