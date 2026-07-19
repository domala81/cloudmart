output "service_account_email" {
  value = google_service_account.bigquery.email
}

# Base64-encoded service-account JSON key. Materialize into
# backend/src/lambda/addToBigQuery/google_credentials.json before building the
# Lambda (the Makefile does this via `make gcp-credentials`).
output "service_account_key_base64" {
  value     = google_service_account_key.bigquery.private_key
  sensitive = true
}
