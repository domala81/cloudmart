terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "archive" {}

provider "tls" {}

# Azure and Google providers are only exercised when enable_azure / enable_gcp
# are true. With the flags off, no resources are created and no cloud
# credentials are required (terraform validate/plan still succeed).
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id != "" ? var.azure_subscription_id : null
}

provider "google" {
  project = var.gcp_project_id != "" ? var.gcp_project_id : null
  region  = var.gcp_region
}

# Kubernetes provider is wired to the EKS cluster created by module.aws.
# Uses the AWS CLI token helper (no static kubeconfig required).
provider "kubernetes" {
  host                   = module.aws.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.aws.eks_cluster_ca_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.aws.eks_cluster_name, "--region", var.aws_region]
  }
}
