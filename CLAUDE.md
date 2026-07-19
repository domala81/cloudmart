# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

CloudMart: multicloud e-commerce + AI demo. Self-contained monorepo — every step is code (no console clicks). See `README.md` (setup runbook) and `PROJECT.md` (architecture + zero-console-clicks ledger).

## Layout

```
frontend/  React 18 + Vite 5 + Tailwind 3 SPA (JS/JSX, no TS)
backend/   Node/Express API (ESM); src/lambda/{listProducts,addToBigQuery}
infra/     Terraform root module -> aws/ (always) + azure/ + gcp/ (toggled)
k8s/       backend.yaml, frontend.yaml (image placeholders BACKEND_IMAGE/FRONTEND_IMAGE)
scripts/   bootstrap-openai-assistant, seed-products, build-lambdas, teardown
.github/workflows/  ci.yml (PR lint/build), deploy.yml (OIDC deploy)
docs/architecture/  .drawio (source of truth) + .png
```

## Commands

- Frontend (`cd frontend`): `npm ci` · `npm run dev` · `npm run build` · `npm run lint`
- Backend (`cd backend`): `npm install` · `npm run dev` (nodemon) · `npm start`
- Backend syntax gate (what CI runs): `node --check src/server.js`
- Infra: `make infra` (build-lambdas → tf init+apply) · `make plan` · `make outputs` · `make destroy`
- Deploy path: push to `main` → `deploy.yml`. No standalone test suite exists.

## Architecture

- **Frontend ↔ backend** over REST. `frontend/src/config/axiosConfig.js` baseURL = `VITE_API_BASE_URL`, **baked at build time** (Vite build-arg in `frontend/Dockerfile`) — changing the API URL requires a rebuild, not a runtime env.
- **Backend** = controllers → services (`backend/src/services/*`). DynamoDB table names are **hardcoded** (`cloudmart-products/orders/tickets`). `aiService.js` is the AI hub: OpenAI Assistants (thread + `delete_order`/`cancel_order` tools), Bedrock Agent Runtime, Azure Text Analytics. All config via env vars.
- **Lambdas**: `listProducts` (Bedrock action-group executor) and `addToBigQuery` (DynamoDB stream → BigQuery). Packaged by Terraform `archive_file` from `backend/src/lambda/*` — **run `make build-lambdas` (or `make infra`) first** so `node_modules` are present in the zip.
- **Terraform** (`infra/`): root calls `module.aws` (always) + `module.azure`/`module.gcp` gated by `enable_azure`/`enable_gcp` count, so an AWS-only `apply` works. `infra/main.tf` builds the backend **`kubernetes_secret` from TF outputs** (Bedrock IDs) + tfvars (OpenAI/Azure) — IDs are never hand-copied into YAML.
- **Auth model, no static keys**: pods get AWS access via **IRSA** (`cloudmart-pod-execution-role` SA annotated with an IAM role); CI gets AWS access via **GitHub OIDC** (deploy role trust scoped to `repo:<owner>/cloudmart:ref:refs/heads/main`).

## Gotchas

- **Bedrock model access** (Claude 3 Sonnet) is an account-level grant with no Terraform resource — enable once before `terraform apply`.
- **ESLint** (`frontend/eslint.config.js`): `react/prop-types` and `react/no-unescaped-entities` are intentionally off (plain-JSX app, no prop-types dep); `no-unused-vars` ignores `^React$`. CI fails on lint errors, not warnings.
- **Never commit** tfvars, `*.tfstate`, `.env`, `google_credentials.json` (all gitignored). Use `*.example` files as templates.
- CI runs on `actions/checkout@v5` + `setup-node@v5` (Node 24 runtime); app targets Node 18.
- Editing the architecture: modify `docs/architecture/cloudmart_architecture.drawio` and re-export the PNG (no drawio renderer in-repo).
