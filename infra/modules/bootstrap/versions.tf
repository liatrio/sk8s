terraform {
  required_providers {
    kustomization = {
      source  = "kbst/kustomize"
      version = "0.2.0-beta.3"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
  required_version = ">= 0.12"
}
