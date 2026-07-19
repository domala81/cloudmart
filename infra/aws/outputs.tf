output "ecr_frontend_repository_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "ecr_backend_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "github_actions_deploy_role_arn" {
  value = aws_iam_role.github_actions_deploy.arn
}

output "bedrock_agent_id" {
  value = aws_bedrockagent_agent.product_recommendation.agent_id
}

output "bedrock_agent_alias_id" {
  value = aws_bedrockagent_agent_alias.prod.agent_alias_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_ca_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "eks_cluster_arn" {
  value = module.eks.cluster_arn
}

output "pod_execution_role_arn" {
  value = aws_iam_role.pod_execution.arn
}
