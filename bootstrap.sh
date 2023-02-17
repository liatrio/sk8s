# #! /usr/bin/env bash

echo "Running Terraform to spin up EKS cluster:"
pushd infra
if [ ! -f "terraform.tfstate" ]; then
  terraform init
fi
terraform apply -var-file="input.tfvars" -auto-approve
retval=$?
if [ $retval -ne 0 ]; then
  echo "Terraform run finished with error(s); cannot continue, so cleaning up instead:"
  terraform destroy -var-file="input.tfvars" -auto-approve
  popd
  exit 1
fi

# Populating variables used later in the script once AWS resources have been created
aws_account_id=$(aws sts get-caller-identity --query "Account" --output text)
aws_region=$(aws configure get region)
cluster_name=$(cat input.tfvars | grep "cluster_name" | awk -F= '/=/{gsub(/ /, "", $0); print $2}' | tr -d '"')
vpc_name=$(cat input.tfvars | grep "network_name" | awk -F= '/=/{gsub(/ /, "", $0); print $2}' | tr -d '"')
vpc_id=$(aws ec2 describe-vpcs --filter Name=tag:Name,Values=${vpc_name} --query "Vpcs[].VpcId" --output text)
docker_image=$(cat input.tfvars | grep "app_name" | awk -F= '/=/{gsub(/ /, "", $0); print $2}' | tr -d '"')
namespace=$(cat input.tfvars | grep "namespace" | awk -F= '/=/{gsub(/ /, "", $0); print $2}' | tr -d '"')
max_retries=20

echo "Deploying application load balancer:"
aws eks --region ${aws_region} update-kubeconfig --name ${cluster_name}
retval=$?
if [ $retval -ne 0 ]; then
  echo "Failed to update context. Cannot proceed with deployments to Kubernetes. Cleaning up."
  terraform destroy -var-file="input.tfvars" -auto-approve
  popd
  exit 1
fi

helm repo add eks https://aws.github.io/eks-charts &&
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master" &&
kubectl apply -f - <<EOH
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${aws_account_id}:role/ALBIngressControllerServiceAccountRole
EOH
kubectl get serviceaccount aws-load-balancer-controller --namespace kube-system
retval=$?
if [ $retval -ne 0 ]; then
  echo "Failed to create service account for ALB Ingress Controller. Cleaning up."
  terraform destroy -var-file="input.tfvars" -auto-approve
  popd
  exit 1
fi

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    --set clusterName=${cluster_name} \
    --set serviceAccount.create=false \
    --set region=${aws_region} \
    --set vpcId=${vpc_id} \
    --set serviceAccount.name=aws-load-balancer-controller \
    -n kube-system
retval=$?
if [ $retval -ne 0 ]; then
  echo "Failed to deploy ALB. Cleaning up."
  terraform destroy -var-file="input.tfvars" -auto-approve
  popd
  exit 1
else
  retries=0
  while true; do
    output=$(kubectl get deployment aws-load-balancer-controller -n kube-system -o 'jsonpath={.status.availableReplicas}')
    sleep 10
    if [ ! -z $output ]; then
      if [ $output -gt 1 ]; then
        echo "Success!"
        break
      fi
    fi
    if [ $retries -eq $max_retries ]; then
      echo "ALB Ingress Controller not running. Cleaning up."
      helm delete aws-load-balancer-controller -n kube-system
      terraform destroy -var-file="input.tfvars" -auto-approve
      popd
      exit 1
    fi
    echo "Waiting for load balancer to become available..."
    ((retries+=1))
  done
fi
popd

echo "Building Docker image for demo:"
pushd app
docker build -t ${docker_image} .
docker tag ${docker_image}:latest ${aws_account_id}.dkr.ecr.us-west-2.amazonaws.com/${docker_image}:latest
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.us-west-2.amazonaws.com
docker push ${aws_account_id}.dkr.ecr.us-west-2.amazonaws.com/${docker_image}:latest
popd

echo "Deploying web app to EKS:"
pushd app/deploy
kubectl create namespace ${namespace}
helm package demo
helm install demoapp demo-0.1.0.tgz --namespace ${namespace}
popd

retries=0
while true; do
  output=$(kubectl get deployment ${docker_image} -n ${namespace} -o 'jsonpath={.status.availableReplicas}')
  sleep 10
  if [ ! -z $output ]; then
    if [ $output -gt 1 ]; then
      echo "Success!"
      break
    fi
  fi
  if [ $retries -eq $max_retries ]; then
    echo "Web app failed to deploy. Quitting."
    exit 1
  fi
  echo "Waiting for web app to become available..."
  ((retries+=1))
done
hostname=$(kubectl get ingress/demoapp -n demo -o 'jsonpath={.status.loadBalancer.ingress[0].hostname}')
echo "The web app is available at: ${hostname}"
