variable "aws_region" {
  description = "AWS region for all AWS resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix used across resources."
  type        = string
  default     = "cloudmart"
}

# ---------------------------------------------------------------------------
# CI/CD (GitHub Actions OIDC)
# ---------------------------------------------------------------------------
variable "github_owner" {
  description = "GitHub org/user that owns the repo (used to scope the OIDC deploy role)."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
  default     = "cloudmart"
}

variable "github_branch" {
  description = "Branch allowed to assume the deploy role."
  type        = string
  default     = "main"
}

# ---------------------------------------------------------------------------
# EKS
# ---------------------------------------------------------------------------
variable "eks_node_instance_type" {
  description = "Instance type for the EKS managed node group."
  type        = string
  default     = "t3.medium"
}

variable "eks_min_size" {
  type    = number
  default = 1
}

variable "eks_desired_size" {
  type    = number
  default = 1
}

variable "eks_max_size" {
  type    = number
  default = 2
}

# ---------------------------------------------------------------------------
# Bedrock
# ---------------------------------------------------------------------------
variable "bedrock_model_id" {
  description = "Foundation model backing the product-recommendation agent."
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

# ---------------------------------------------------------------------------
# AI assistant secrets (injected into the backend Kubernetes Secret)
# ---------------------------------------------------------------------------
variable "openai_api_key" {
  description = "OpenAI API key for the customer-support assistant."
  type        = string
  default     = ""
  sensitive   = true
}

variable "openai_assistant_id" {
  description = "OpenAI assistant id (from scripts/bootstrap-openai-assistant.mjs)."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Azure (sentiment analysis) — only used when enable_azure = true
# ---------------------------------------------------------------------------
variable "enable_azure" {
  description = "Provision Azure Text Analytics for sentiment analysis."
  type        = bool
  default     = false
}

variable "azure_location" {
  description = "Azure region for the Text Analytics resource."
  type        = string
  default     = "eastus"
}

variable "azure_subscription_id" {
  description = "Azure subscription id (required only when enable_azure = true)."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# GCP (BigQuery analytics) — only used when enable_gcp = true
# ---------------------------------------------------------------------------
variable "enable_gcp" {
  description = "Provision GCP BigQuery + the DynamoDB->BigQuery pipeline."
  type        = bool
  default     = false
}

variable "gcp_project_id" {
  description = "GCP project id (required only when enable_gcp = true)."
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "GCP region for BigQuery."
  type        = string
  default     = "US"
}
