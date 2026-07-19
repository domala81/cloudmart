locals {
  lambda_src = "${path.module}/../../backend/src/lambda"
}

# Zips are built from the Lambda source dirs. Run `make build-lambdas`
# (scripts/build-lambdas.sh) first so node_modules and google_credentials.json
# are present before `terraform apply` archives them.

# ---------------------------------------------------------------------------
# listProducts — Bedrock action-group executor
# ---------------------------------------------------------------------------
data "archive_file" "list_products" {
  type        = "zip"
  source_dir  = "${local.lambda_src}/listProducts"
  output_path = "${path.module}/build/list_products.zip"
}

resource "aws_lambda_function" "list_products" {
  function_name    = "cloudmart-list-products"
  filename         = data.archive_file.list_products.output_path
  source_code_hash = data.archive_file.list_products.output_base64sha256
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 30

  environment {
    variables = {
      PRODUCTS_TABLE = aws_dynamodb_table.products.name
    }
  }
}

resource "aws_lambda_permission" "allow_bedrock" {
  statement_id  = "AllowBedrockInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_products.function_name
  principal     = "bedrock.amazonaws.com"
}

# ---------------------------------------------------------------------------
# addToBigQuery — DynamoDB stream -> BigQuery (gated on enable_gcp)
# ---------------------------------------------------------------------------
data "archive_file" "add_to_bigquery" {
  count       = var.enable_bigquery_pipeline ? 1 : 0
  type        = "zip"
  source_dir  = "${local.lambda_src}/addToBigQuery"
  output_path = "${path.module}/build/dynamodb_to_bigquery.zip"
}

resource "aws_lambda_function" "add_to_bigquery" {
  count            = var.enable_bigquery_pipeline ? 1 : 0
  function_name    = "cloudmart-dynamodb-to-bigquery"
  filename         = data.archive_file.add_to_bigquery[0].output_path
  source_code_hash = data.archive_file.add_to_bigquery[0].output_base64sha256
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 60

  environment {
    variables = {
      GOOGLE_CLOUD_PROJECT_ID        = var.gcp_project_id
      BIGQUERY_DATASET_ID            = var.bigquery_dataset_id
      BIGQUERY_TABLE_ID              = var.bigquery_table_id
      GOOGLE_APPLICATION_CREDENTIALS = "/var/task/google_credentials.json"
    }
  }
}

resource "aws_lambda_event_source_mapping" "orders_stream" {
  count             = var.enable_bigquery_pipeline ? 1 : 0
  event_source_arn  = aws_dynamodb_table.orders.stream_arn
  function_name     = aws_lambda_function.add_to_bigquery[0].arn
  starting_position = "LATEST"
}
