# BigQuery data warehouse for CloudMart orders (Use Case 2), plus the service
# account the addToBigQuery Lambda uses to stream rows in.

resource "google_bigquery_dataset" "cloudmart" {
  dataset_id = var.dataset_id
  location   = var.region
}

resource "google_bigquery_table" "orders" {
  dataset_id          = google_bigquery_dataset.cloudmart.dataset_id
  table_id            = var.table_id
  deletion_protection = false

  schema = jsonencode([
    { name = "id", type = "STRING", mode = "NULLABLE" },
    { name = "items", type = "STRING", mode = "NULLABLE" },
    { name = "userEmail", type = "STRING", mode = "NULLABLE" },
    { name = "total", type = "FLOAT", mode = "NULLABLE" },
    { name = "status", type = "STRING", mode = "NULLABLE" },
    { name = "createdAt", type = "TIMESTAMP", mode = "NULLABLE" },
  ])
}

resource "google_service_account" "bigquery" {
  account_id   = "cloudmart-bigquery-sa"
  display_name = "CloudMart BigQuery writer"
}

resource "google_bigquery_dataset_iam_member" "editor" {
  dataset_id = google_bigquery_dataset.cloudmart.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.bigquery.email}"
}

resource "google_service_account_key" "bigquery" {
  service_account_id = google_service_account.bigquery.name
}
