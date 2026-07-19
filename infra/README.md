# infra/

Terraform for all CloudMart resources. Single root module; AWS is always created, Azure/GCP are
gated by `enable_azure` / `enable_gcp`.

```
infra/
├── providers.tf   aws, archive, tls, kubernetes, azurerm, google
├── variables.tf   inputs (see terraform.tfvars.example)
├── main.tf        module wiring + backend Secret + pod service account
├── outputs.tf
├── aws/           dynamodb, iam, lambda, ecr, bedrock, vpc, eks
├── azure/         text analytics (module)
└── gcp/           bigquery + service account (module)
```

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in github_owner + OpenAI + toggles
../scripts/build-lambdas.sh                     # or: make -C .. build-lambdas
terraform init
terraform apply
```

Prefer `make infra` from the repo root — it builds the Lambda zips first.

## Notes

- **State:** local by default. For real use, add an S3 + DynamoDB backend (`backend "s3"`).
- **Bedrock model access** must be granted once at the account level (no Terraform resource) —
  enable Claude 3 Sonnet before `apply`.
- **Kubernetes provider** authenticates to the new EKS cluster via `aws eks get-token`, so the AWS
  CLI must be on PATH during `apply`.
- Key outputs: `github_actions_deploy_role_arn`, `eks_cluster_name`, `ecr_*_repository_url`,
  `bedrock_agent_id`, `bedrock_agent_alias_id`.
