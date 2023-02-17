#! /usr/bin/env bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NONE='\033[0m'
PASS=true

docker_image=$(cat infra/input.tfvars | grep "app_name" | awk -F= '/=/{gsub(/ /, "", $0); print $2}' | tr -d '"')
namespace=$(cat infra/input.tfvars | grep "namespace" | awk -F= '/=/{gsub(/ /, "", $0); print $2}' | tr -d '"')

echo "Checking number of ALB pods running:"
replicas=$(kubectl get deployment aws-load-balancer-controller -n kube-system -o 'jsonpath={.status.availableReplicas}')
echo "Expected 2, got: ${replicas}"
if [ $replicas -eq 2 ]; then
  echo -e "  ${GREEN}Success!${NONE}"
else
  echo -e "  ${RED}Failure!${NONE}"
  PASS=false
fi

echo "Checking number of application pods running:"
replicas=$(kubectl get deployment ${docker_image} -n ${namespace} -o 'jsonpath={.status.availableReplicas}')
echo "Expected 3, got: ${replicas}"
if [ $replicas -eq 3 ]; then
  echo -e "  ${GREEN}Success!${NONE}"
else
  echo -e "  ${RED}Failure!${NONE}"
  PASS=false
fi

if $PASS; then
  hostname=$(kubectl get ingress/demoapp -n demo -o 'jsonpath={.status.loadBalancer.ingress[0].hostname}')
  if [ -z "${hostname}" ]; then
    echo "There is no published endpoint."
    echo -e "  ${RED}Failure!${NONE}"
    exit 1
  fi
  endpoint=http://${hostname}/api/foo
  echo "Checking endpoint: ${endpoint}"
  output=$(curl -f -s ${endpoint})
  if [ ! -z "${output}" ]; then
    echo "  Response: ${output}"
    echo -e "  ${GREEN}Success!${NONE}"
  else
    echo "Failed to get a response; server returned an error."
    echo -e "  ${RED}Failure!${NONE}"
    exit 1
  fi
else
  echo "One or both of the previous tests failed; there is no valid endpoint to check."
  exit 1
fi
