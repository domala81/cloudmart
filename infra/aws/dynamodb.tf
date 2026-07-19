# DynamoDB tables backing CloudMart. Names are referenced verbatim by the
# backend services and Lambdas, so they are fixed (not prefixed).

resource "aws_dynamodb_table" "products" {
  name         = "cloudmart-products"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "orders" {
  name         = "cloudmart-orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Stream feeds the DynamoDB -> BigQuery Lambda (Use Case 2).
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
}

resource "aws_dynamodb_table" "tickets" {
  name         = "cloudmart-tickets"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
