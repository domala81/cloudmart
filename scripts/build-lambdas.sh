#!/usr/bin/env bash
# Installs each Lambda's production dependencies so Terraform's archive_file
# packages a complete deployment zip. Run before `terraform apply`.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAMBDA_DIR="$ROOT/backend/src/lambda"

echo "==> Building listProducts Lambda"
( cd "$LAMBDA_DIR/listProducts" && npm install --omit=dev --no-audit --no-fund )

if [ "${ENABLE_GCP:-false}" = "true" ]; then
  echo "==> Building addToBigQuery Lambda"
  ( cd "$LAMBDA_DIR/addToBigQuery" && npm install --omit=dev --no-audit --no-fund )

  if [ ! -f "$LAMBDA_DIR/addToBigQuery/google_credentials.json" ]; then
    echo "WARNING: $LAMBDA_DIR/addToBigQuery/google_credentials.json is missing."
    echo "         Run 'make gcp-credentials' after 'terraform apply' (or copy the .example)."
  fi
else
  echo "==> Skipping addToBigQuery Lambda (ENABLE_GCP != true)"
fi

echo "==> Lambda build complete."
