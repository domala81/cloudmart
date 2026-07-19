output "aws_region" {
  value = var.aws_region
}

output "eks_cluster_name" {
  description = "EKS cluster name (use with: aws eks update-kubeconfig)."
  value       = module.aws.eks_cluster_name
}

output "ecr_frontend_repository_url" {
  value = module.aws.ecr_frontend_repository_url
}

output "ecr_backend_repository_url" {
  value = module.aws.ecr_backend_repository_url
}

output "bedrock_agent_id" {
  value = module.aws.bedrock_agent_id
}

output "bedrock_agent_alias_id" {
  value = module.aws.bedrock_agent_alias_id
}

output "github_actions_deploy_role_arn" {
  description = "Set this as the AWS_DEPLOY_ROLE_ARN GitHub Actions variable/secret."
  value       = module.aws.github_actions_deploy_role_arn
}

output "backend_secret_name" {
  description = "Kubernetes Secret consumed by the backend Deployment (envFrom)."
  value       = kubernetes_secret.backend.metadata[0].name
}

output "azure_text_analytics_endpoint" {
  value = var.enable_azure ? module.azure[0].endpoint : null
}

output "bigquery_dataset" {
  value = var.enable_gcp ? "${var.gcp_project_id}.${local.bigquery_dataset_id}.${local.bigquery_table_id}" : null
}

output "gcp_service_account_key_base64" {
  description = "Base64 GCP SA key for the BigQuery Lambda (make gcp-credentials writes it to google_credentials.json)."
  value       = var.enable_gcp ? module.gcp[0].service_account_key_base64 : null
  sensitive   = true
}
