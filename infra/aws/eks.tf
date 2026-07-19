module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = var.project_name
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  # The identity running `terraform apply` becomes a cluster admin.
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    standard = {
      instance_types = [var.eks_node_instance_type]
      min_size       = var.eks_min_size
      max_size       = var.eks_max_size
      desired_size   = var.eks_desired_size
    }
  }

  # Let GitHub Actions (via the OIDC deploy role) run kubectl against the cluster.
  access_entries = {
    github_actions = {
      principal_arn = aws_iam_role.github_actions_deploy.arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# IRSA role for application pods (DynamoDB + Bedrock agent), assumed by the
# `cloudmart-pod-execution-role` service account.
# ---------------------------------------------------------------------------
resource "aws_iam_role" "pod_execution" {
  name = "cloudmart-pod-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = module.eks.oidc_provider_arn }
      Condition = {
        StringEquals = {
          "${module.eks.oidc_provider}:sub" = "system:serviceaccount:default:cloudmart-pod-execution-role"
          "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "pod_execution" {
  name = "cloudmart-pod-execution-policy"
  role = aws_iam_role.pod_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDb"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.products.arn,
          aws_dynamodb_table.orders.arn,
          aws_dynamodb_table.tickets.arn
        ]
      },
      {
        Sid    = "BedrockAgent"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeAgent",
          "bedrock:InvokeModel"
        ]
        Resource = "*"
      }
    ]
  })
}
