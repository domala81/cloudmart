.DEFAULT_GOAL := help
INFRA := infra
LAMBDA_CREDS := backend/src/lambda/addToBigQuery/google_credentials.json

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

.PHONY: bootstrap
bootstrap: ## Create the OpenAI assistant (prints OPENAI_ASSISTANT_ID for tfvars)
	npm install --prefix scripts --no-audit --no-fund
	node scripts/bootstrap-openai-assistant.mjs

.PHONY: build-lambdas
build-lambdas: ## Install Lambda dependencies so Terraform can package them
	bash scripts/build-lambdas.sh

.PHONY: infra
infra: build-lambdas ## terraform init + apply (stands up all cloud resources)
	terraform -chdir=$(INFRA) init
	terraform -chdir=$(INFRA) apply

.PHONY: plan
plan: ## terraform plan
	terraform -chdir=$(INFRA) plan

.PHONY: gcp-credentials
gcp-credentials: ## Write the BigQuery SA key from TF output to google_credentials.json (enable_gcp)
	terraform -chdir=$(INFRA) output -raw gcp_service_account_key_base64 | base64 --decode > $(LAMBDA_CREDS)
	@echo "Wrote $(LAMBDA_CREDS). Re-run 'make infra' to repackage the Lambda."

.PHONY: seed
seed: ## Seed sample products into DynamoDB
	npm install --prefix scripts --no-audit --no-fund
	node scripts/seed-products.mjs

.PHONY: outputs
outputs: ## Show Terraform outputs
	terraform -chdir=$(INFRA) output

.PHONY: destroy
destroy: ## Tear everything down (kubectl delete + terraform destroy)
	bash scripts/teardown.sh
