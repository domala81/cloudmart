# CloudMart — Self-Contained, Zero-Console-Click Monorepo

**Date:** 2026-07-18
**Status:** Approved design, pending spec review

## Context

CloudMart is a multicloud e-commerce + DevOps + AI project originally built as a 5-day bootcamp
challenge. The build steps live only in Notion (`MultiCloud, DevOps & AI Challenge Documentation`,
Day 1–5 + Resource Cleanup) and rely heavily on **manual AWS/Azure/GCP console clicks** and
ad-hoc CLI commands (create IAM roles by hand, launch an EC2 workstation, `eksctl` a cluster,
click-build a Bedrock agent, wire CodePipeline via console OAuth, create the OpenAI assistant in
the dashboard, provision Azure Text Analytics and GCP BigQuery by hand).

The GitHub repo currently contains **only the frontend** (React/Vite SPA). The backend, all
infrastructure, and the AI/CI wiring exist only as prose in Notion.

**Goal:** turn this into a single, self-contained, reproducible monorepo where **every manual
console step becomes code** (Terraform + scripts + GitHub Actions), so the project reads as a
professional, deployable, portfolio-grade "I built and shipped a full multicloud AI app" — not a
frontend plus a page of clicking instructions.

**Non-goal:** this spec covers authoring code and configuration only. No live cloud resources are
deployed as part of this work; the maintainer runs `terraform apply` with their own credentials.

## Decisions (locked with user)

| Decision | Choice |
| --- | --- |
| Backend | Use the **real** bootcamp backend (`cloudmart-backend-final.zip`), already downloaded and inspected — not a reconstruction. |
| Layout | **Monorepo**: `frontend/`, `backend/`, `infra/`, `k8s/`, `scripts/`, `.github/`. |
| IaC | **Terraform** for everything possible (AWS + Azure + GCP). |
| Multicloud | **All 3 clouds authored, Azure/GCP behind enable flags** so AWS-only `apply` still works. |
| CI/CD | **GitHub Actions + OIDC** (no stored keys, no console handshake). CodePipeline dropped. |

## Source facts (verified against the real code)

Backend (`cloudmart-backend-final.zip`, ES modules, Express 4):
- `src/server.js` — mounts `/api/products`, `/api/orders`, `/api/ai`, `/api/tickets`; port from `PORT` (5000).
- Controllers/routes/services per domain: `product`, `order`, `ai`, `ticket`.
- `src/services/aiService.js` integrates: OpenAI Assistants API (thread + function tools
  `delete_order`, `cancel_order`), Amazon Bedrock Agent Runtime (`InvokeAgentCommand`), Azure
  Text Analytics (`analyzeSentiment`), DynamoDB DocumentClient (writes `cloudmart-tickets`).
- Env contract consumed by backend: `PORT`, `AWS_REGION`, `AWS_ACCESS_KEY_ID`,
  `AWS_SECRET_ACCESS_KEY`, `BEDROCK_AGENT_ID`, `BEDROCK_AGENT_ALIAS_ID`, `OPENAI_API_KEY`,
  `OPENAI_ASSISTANT_ID`, `AZURE_ENDPOINT`, `AZURE_API_KEY`.
- Lambdas: `src/lambda/listProducts/index.mjs` (Bedrock action-group executor; scans
  `cloudmart-products`), `src/lambda/addToBigQuery/index.mjs` (DynamoDB Streams → BigQuery insert;
  env `GOOGLE_CLOUD_PROJECT_ID`, `BIGQUERY_DATASET_ID`, `BIGQUERY_TABLE_ID`,
  `GOOGLE_APPLICATION_CREDENTIALS`). `google_credentials.json` in the zip is **empty** (placeholder).

Frontend (repo root today):
- React 18 + Vite 5 + Tailwind 3 + axios + react-router 6. `src/config/axiosConfig.js` reads
  `VITE_API_BASE_URL`. `Dockerfile` serves `dist` on 5001. `cloudmart-frontend.yaml` is an EKS
  Deployment + LoadBalancer with a `CONTAINER_IMAGE` placeholder.

DynamoDB tables (from Notion IaC): `cloudmart-products`, `cloudmart-orders` (stream:
`NEW_AND_OLD_IMAGES`), `cloudmart-tickets`. All `PAY_PER_REQUEST`, hash key `id` (string).

## Target repository structure

```
cloudmart/
├── frontend/                     # current React app, moved from root (history preserved)
│   ├── src/ ...
│   ├── Dockerfile                # serves dist on :5001 (unchanged)
│   ├── package.json ...
├── backend/                      # real Express API from the zip
│   ├── src/ ...                  # server, controllers, routes, services
│   ├── Dockerfile                # Node 18, npm install, :5000
│   ├── .dockerignore
│   └── package.json
├── infra/
│   ├── aws/                      # always-on AWS stack
│   │   ├── providers.tf  variables.tf  outputs.tf
│   │   ├── dynamodb.tf           # 3 tables (+stream on orders)
│   │   ├── lambda.tf             # listProducts + addToBigQuery (archive_file)
│   │   ├── iam.tf                # lambda role/policy, EKS roles, GitHub OIDC provider+role
│   │   ├── bedrock.tf            # agent + action group + alias
│   │   ├── ecr.tf                # frontend + backend repos
│   │   ├── eks.tf                # cluster + managed node group (via terraform-aws-modules/eks)
│   │   └── k8s_secret.tf         # kubernetes_secret from TF outputs + tfvars
│   ├── azure/                    # count/enable_azure flag
│   │   └── text_analytics.tf     # azurerm_cognitive_account -> endpoint + key outputs
│   ├── gcp/                      # count/enable_gcp flag
│   │   └── bigquery.tf           # dataset + table + service account + key
│   ├── terraform.tfvars.example
│   └── README.md                 # apply order, remote-state note
├── k8s/
│   ├── backend.yaml              # Deployment + LoadBalancer Service (:5000), env from Secret
│   └── frontend.yaml             # Deployment + LoadBalancer Service (:5001), CONTAINER_IMAGE
├── scripts/
│   ├── bootstrap-openai-assistant.mjs   # creates GPT-4o assistant, prints ID
│   ├── seed-products.mjs                 # optional: load sample products into DynamoDB
│   └── teardown.sh                       # ordered destroy (mirrors Notion cleanup)
├── .github/workflows/
│   ├── ci.yml                    # lint + build both apps on PR
│   └── deploy.yml                # OIDC -> build -> ECR -> kubectl apply, on push to main
├── Makefile                      # bootstrap / infra / deploy / destroy targets
├── PROJECT.md                    # updated (no longer "frontend only")
├── README.md                    # quickstart + architecture
├── .gitignore                    # tfvars, *.tfstate, google_credentials.json, .env, node_modules
└── docs/                         # this spec + reference
```

## Component design

### 1. Frontend (move only)
`git mv` the current root app into `frontend/`. No code change except: `VITE_API_BASE_URL` now
documented to point at the backend LoadBalancer. Keep `frontend/Dockerfile` as-is.

### 2. Backend (import real source)
Copy the unpacked `backend-src/` (minus `__MACOSX/`, `.DS_Store`) into `backend/`. Add a
`backend/Dockerfile` (Node 18, `COPY package*.json`, `npm install`, `COPY . .`, `EXPOSE 5000`,
`CMD ["npm","start"]`) matching the Notion Day-2 backend Dockerfile. Add `.dockerignore`
(`node_modules`, `.env`). The two Lambda source dirs stay under `backend/src/lambda/` and are the
inputs to `infra/aws/lambda.tf` (Terraform `archive_file` zips them at plan time).

### 3. AWS Terraform (`infra/aws/`)
- **DynamoDB** — 3 tables per source facts; `cloudmart-orders` has `stream_enabled=true`,
  `stream_view_type=NEW_AND_OLD_IMAGES`.
- **IAM** — Lambda execution role/policy (DynamoDB scan + stream read + logs); EKS cluster and
  node roles; **GitHub OIDC provider** (`token.actions.githubusercontent.com`) + a deploy role
  whose trust policy is scoped to this repo/`main`, granting ECR push + EKS describe.
- **Lambda** — `listProducts` (env `PRODUCTS_TABLE`) and `addToBigQuery` (env for GCP project /
  dataset / table / credentials path), packaged with `archive_file`. Bedrock invoke permission on
  `listProducts`; DynamoDB-stream event-source mapping → `addToBigQuery` (gated by `enable_gcp`).
- **Bedrock** — `aws_bedrockagent_agent` (Claude 3 Sonnet, instructions from Notion Day 4),
  `aws_bedrockagent_agent_action_group` (OpenAPI schema from Notion, executor = `listProducts`),
  `aws_bedrockagent_agent_alias` (`cloudmart-prod`). Outputs `agent_id`, `agent_alias_id`.
- **ECR** — repos `cloudmart-frontend`, `cloudmart-backend`.
- **EKS** — cluster `cloudmart` + one managed node group (`t3.medium`, 1–2 nodes) via
  `terraform-aws-modules/eks`; IRSA for the pod execution role used by the manifests.
- **K8s Secret** — `kubernetes_secret.cloudmart_backend` built from TF outputs (`agent_id`,
  `agent_alias_id`, region) + tfvars (`openai_api_key`, `openai_assistant_id`, `azure_endpoint`,
  `azure_api_key`). `k8s/backend.yaml` references it via `envFrom.secretRef`. This closes the
  copy-paste loop — no manual editing of YAML with IDs.

### 4. Azure Terraform (`infra/azure/`, `enable_azure`)
`azurerm_resource_group` + `azurerm_cognitive_account` (kind `TextAnalytics`). Outputs `endpoint`
and `primary_access_key`, consumed into the backend Secret when the flag is on.

### 5. GCP Terraform (`infra/gcp/`, `enable_gcp`)
`google_bigquery_dataset` (`cloudmart`), `google_bigquery_table` (`cloudmart-orders`, schema:
id STRING, items JSON/STRING, userEmail STRING, total FLOAT, status STRING, createdAt TIMESTAMP),
`google_service_account` (`cloudmart-bigquery-sa`) + key. The BigQuery Lambda + stream mapping in
AWS are gated on the same flag.

### 6. OpenAI bootstrap (`scripts/bootstrap-openai-assistant.mjs`)
Node script using the `openai` SDK: creates the "CloudMart Customer Support" assistant on
`gpt-4o` with the Notion Day-4 instructions, prints the assistant ID. Maintainer copies it into
`terraform.tfvars` (or the script writes it there). Replaces the dashboard clicking.

### 7. CI/CD (`.github/workflows/`)
- `ci.yml` (PRs): install + lint + build frontend and backend.
- `deploy.yml` (push to `main`): `permissions: id-token: write`; `aws-actions/configure-aws-credentials`
  assumes the OIDC deploy role; build+push both images to ECR (tag = commit SHA); `aws eks
  update-kubeconfig`; `sed` the image into the manifests; `kubectl apply -f k8s/`.

### 8. Makefile + README
Targets: `make bootstrap` (OpenAI assistant), `make infra` (`terraform -chdir=infra/aws apply`,
plus azure/gcp when enabled), `make images`/`make deploy` (local build+push+apply for the
non-CI path), `make destroy` (calls `scripts/teardown.sh`). README documents prerequisites, the
one-time Bedrock model-access grant, apply order, and how to point the frontend at the backend LB.

### 9. Teardown (`scripts/teardown.sh`)
Ordered destroy mirroring the Notion Resource Cleanup guide: delete K8s services/deployments →
`terraform destroy` (removes EKS, Lambdas, DynamoDB, Bedrock, ECR, IAM, and Azure/GCP when
enabled). No leftover manual-only resources because there is no hand-created EC2/eksctl cluster.

## The "zero console clicks" ledger

Every Notion manual step and how it is eliminated:

| Notion manual step | Replaced by |
| --- | --- |
| Create IAM roles in console (EC2Admin, lambda, pod exec) | `infra/aws/iam.tf` |
| Launch EC2 workstation, install Terraform/kubectl | Removed — run Terraform locally / in CI |
| S3 bucket (Day 1 warm-up) | Dropped (not used by the app) |
| DynamoDB tables in console/CLI | `infra/aws/dynamodb.tf` |
| `eksctl create cluster` | `infra/aws/eks.tf` |
| ECR repos + "View push commands" | `infra/aws/ecr.tf` + CI build/push |
| Build Bedrock agent, action group, alias in console | `infra/aws/bedrock.tf` |
| Create OpenAI assistant in dashboard | `scripts/bootstrap-openai-assistant.mjs` |
| Provision Azure Text Analytics in portal | `infra/azure/text_analytics.tf` |
| Create GCP project/dataset/table/SA in console | `infra/gcp/bigquery.tf` |
| Edit YAML with agent/assistant IDs by hand | `kubernetes_secret` from TF outputs |
| CodePipeline + GitHub OAuth handshake | GitHub Actions + OIDC (`deploy.yml`, `iam.tf`) |
| Manual teardown clicking | `scripts/teardown.sh` + `terraform destroy` |

**Residual, genuinely unavoidable (documented in README, not console "clicking" of resources):**
- **Bedrock foundation-model access grant** — account-level enablement of Claude 3 Sonnet; no
  first-class Terraform resource. One-time `aws bedrock`/console action, documented.
- **Providing secrets** — AWS creds for Terraform, `OPENAI_API_KEY`, Azure/GCP credentials, via
  `terraform.tfvars` / GitHub OIDC. This is configuration, not resource-creation clicking.

## Security / correctness constraints

- No secrets committed. `.gitignore` covers `*.tfvars` (except `.example`), `*.tfstate*`,
  `google_credentials.json`, `.env`, `node_modules`. Verify the empty creds placeholder stays empty.
- OIDC deploy role trust policy scoped to `repo:<owner>/cloudmart:ref:refs/heads/main` — not `*`.
- IAM policies for the app follow least privilege where practical (note where the bootcamp used
  `AdministratorAccess` for teaching and flag it as a deliberate, documented simplification).
- Terraform state: default local state; README notes S3+DynamoDB remote-state backend as the
  production upgrade (not wired by default to keep first `apply` frictionless).

## Testing / verification

Author-time (no cloud spend):
- `terraform -chdir=infra/aws init` + `validate` + `plan` (with a sample tfvars) — succeeds, no errors.
- `terraform fmt -check` clean across `infra/`.
- `terraform -chdir=infra/azure validate` and `infra/gcp validate` with their providers.
- `cd frontend && npm ci && npm run build` — succeeds. `cd backend && npm ci && node --check src/server.js`.
- `docker build` both images locally — succeed.
- `node --check scripts/bootstrap-openai-assistant.mjs`; workflow YAML linted (`actionlint` if available).
- Grep the repo for accidental secrets before commit.

Deploy-time (maintainer, out of scope for this work, documented in README):
- `make bootstrap` → assistant ID; `terraform apply`; push to `main` → Actions deploys;
  hit frontend LB, exercise store + Bedrock widget + support chat + sentiment ticket;
  confirm an order lands in BigQuery when `enable_gcp`.

## Implementation phasing (for the plan)

1. Restructure: move frontend → `frontend/`, import backend → `backend/`, root housekeeping,
   `.gitignore`, PROJECT.md/README skeleton.
2. AWS Terraform core: providers/vars, DynamoDB, IAM, Lambda, ECR.
3. AWS Terraform advanced: Bedrock agent, EKS, K8s Secret.
4. Multicloud: Azure + GCP modules behind flags; wire GCP Lambda/stream gating.
5. AI bootstrap script + seed script.
6. CI/CD: `ci.yml`, `deploy.yml`, OIDC role.
7. Makefile, teardown, docs, final verification (`terraform validate/plan`, builds).

Each phase ends with a green `terraform validate`/build check before the next.
