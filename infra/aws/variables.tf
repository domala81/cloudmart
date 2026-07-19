variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "github_owner" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "github_branch" {
  type = string
}

variable "eks_node_instance_type" {
  type = string
}

variable "eks_min_size" {
  type = number
}

variable "eks_desired_size" {
  type = number
}

variable "eks_max_size" {
  type = number
}

variable "bedrock_model_id" {
  type = string
}

variable "enable_bigquery_pipeline" {
  description = "Create the addToBigQuery Lambda + DynamoDB stream mapping."
  type        = bool
  default     = false
}

variable "gcp_project_id" {
  type    = string
  default = ""
}

variable "bigquery_dataset_id" {
  type    = string
  default = "cloudmart"
}

variable "bigquery_table_id" {
  type    = string
  default = "cloudmart-orders"
}
