locals {
  bigquery_dataset_id = "cloudmart"
  bigquery_table_id   = "cloudmart-orders"
}

# ---------------------------------------------------------------------------
# AWS: core app infra (always on)
#   DynamoDB, Lambdas, IAM, ECR, Bedrock agent, EKS, GitHub OIDC.
# ---------------------------------------------------------------------------
module "aws" {
  source = "./aws"

  project_name = var.project_name
  aws_region   = var.aws_region

  github_owner  = var.github_owner
  github_repo   = var.github_repo
  github_branch = var.github_branch

  eks_node_instance_type = var.eks_node_instance_type
  eks_min_size           = var.eks_min_size
  eks_desired_size       = var.eks_desired_size
  eks_max_size           = var.eks_max_size

  bedrock_model_id = var.bedrock_model_id

  # BigQuery pipeline is created inside the AWS module but gated on enable_gcp.
  enable_bigquery_pipeline = var.enable_gcp
  gcp_project_id           = var.gcp_project_id
  bigquery_dataset_id      = local.bigquery_dataset_id
  bigquery_table_id        = local.bigquery_table_id
}

# ---------------------------------------------------------------------------
# Azure: Text Analytics (sentiment) — toggle
# ---------------------------------------------------------------------------
module "azure" {
  source = "./azure"
  count  = var.enable_azure ? 1 : 0

  project_name = var.project_name
  location     = var.azure_location
}

# ---------------------------------------------------------------------------
# GCP: BigQuery warehouse — toggle
# ---------------------------------------------------------------------------
module "gcp" {
  source = "./gcp"
  count  = var.enable_gcp ? 1 : 0

  project_id = var.gcp_project_id
  region     = var.gcp_region
  dataset_id = local.bigquery_dataset_id
  table_id   = local.bigquery_table_id
}

# ---------------------------------------------------------------------------
# Pod service account (IRSA) — grants app pods DynamoDB + Bedrock access
# without static credentials. Referenced by k8s/backend.yaml + frontend.yaml.
# ---------------------------------------------------------------------------
resource "kubernetes_service_account" "pod_execution" {
  metadata {
    name = "cloudmart-pod-execution-role"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.aws.pod_execution_role_arn
    }
  }
}

# ---------------------------------------------------------------------------
# Backend Kubernetes Secret — built straight from Terraform outputs + tfvars,
# so agent/assistant IDs never get hand-copied into YAML.
# ---------------------------------------------------------------------------
resource "kubernetes_secret" "backend" {
  metadata {
    name = "${var.project_name}-backend-secrets"
  }

  data = {
    AWS_REGION             = var.aws_region
    BEDROCK_AGENT_ID       = module.aws.bedrock_agent_id
    BEDROCK_AGENT_ALIAS_ID = module.aws.bedrock_agent_alias_id
    OPENAI_API_KEY         = var.openai_api_key
    OPENAI_ASSISTANT_ID    = var.openai_assistant_id
    AZURE_ENDPOINT         = var.enable_azure ? module.azure[0].endpoint : ""
    AZURE_API_KEY          = var.enable_azure ? module.azure[0].primary_key : ""
  }

  type = "Opaque"
}
