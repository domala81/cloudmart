#!/usr/bin/env bash
# Tears down CloudMart in the correct order (mirrors the Notion Resource
# Cleanup guide, but as code). Everything provisioned by Terraform — EKS,
# Lambdas, DynamoDB, Bedrock, ECR, IAM, and optional Azure/GCP — is destroyed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Deleting Kubernetes workloads (best effort)"
kubectl delete -f "$ROOT/k8s/" --ignore-not-found=true || true

echo "==> terraform destroy"
terraform -chdir="$ROOT/infra" destroy -auto-approve

echo "==> Teardown complete. Verify in the AWS/Azure/GCP consoles that nothing lingers."
