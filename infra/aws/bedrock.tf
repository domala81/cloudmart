locals {
  bedrock_agent_instructions = <<-EOT
    You are a product recommendations agent for CloudMart, an online e-commerce store. Your role is to assist customers in finding products that best suit their needs. Follow these instructions carefully:
    1. Begin each interaction by retrieving the full list of products from the API. This will inform you of the available products and their details.
    2. Your goal is to help users find suitable products based on their requirements. Ask questions to understand their needs and preferences if they're not clear from the user's initial input.
    3. Use the 'name' parameter to filter products when appropriate. Do not use or mention any other filter parameters that are not part of the API.
    4. Always base your product suggestions solely on the information returned by the API. Never recommend or mention products that are not in the API response.
    5. When suggesting products, provide the name, description, and price as returned by the API. Do not invent or modify any product details.
    6. If the user's request doesn't match any available products, politely inform them that we don't currently have such products and offer alternatives from the available list.
    7. Be conversational and friendly, but focus on helping the user find suitable products efficiently.
    8. Do not mention the API, database, or any technical aspects of how you retrieve the information. Present yourself as a knowledgeable sales assistant.
    9. If you're unsure about a product's availability or details, always check with the API rather than making assumptions.
    10. If the user asks about product features or comparisons, use only the information provided in the product descriptions from the API.
    11. Be prepared to assist with a wide range of product inquiries, as our e-commerce store may carry various types of items.
    12. If a user is looking for a specific type of product, use the 'name' parameter to search for relevant items, but be aware that this may not capture all categories or types of products.
    Remember, your primary goal is to help users find the best products for their needs from what's available in our store. Be helpful, informative, and always base your recommendations on the actual product data provided by the API.
  EOT

  product_api_schema = jsonencode({
    openapi = "3.0.0"
    info = {
      title       = "Product Details API"
      version     = "1.0.0"
      description = "This API retrieves product information. Filtering parameters are passed as query strings. If query strings are empty, it performs a full scan and retrieves the full product list."
    }
    paths = {
      "/products" = {
        get = {
          summary     = "Retrieve product details"
          description = "Retrieves a list of products based on the provided query string parameters. If no parameters are provided, it returns the full list of products."
          parameters = [{
            name        = "name"
            in          = "query"
            description = "Retrieve details for a specific product by name"
            schema      = { type = "string" }
          }]
          responses = {
            "200" = {
              description = "Successful response"
              content = {
                "application/json" = {
                  schema = {
                    type = "array"
                    items = {
                      type = "object"
                      properties = {
                        name        = { type = "string" }
                        description = { type = "string" }
                        price       = { type = "number" }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  })
}

# Role assumed by the Bedrock agent to call the model and the Lambda.
resource "aws_iam_role" "bedrock_agent" {
  name = "cloudmart-bedrock-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "bedrock.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "bedrock_agent" {
  name = "cloudmart-bedrock-agent-policy"
  role = aws_iam_role.bedrock_agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "bedrock:InvokeModel"
        Resource = "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.bedrock_model_id}"
      },
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = aws_lambda_function.list_products.arn
      }
    ]
  })
}

resource "aws_bedrockagent_agent" "product_recommendation" {
  agent_name              = "cloudmart-product-recommendation-agent"
  agent_resource_role_arn = aws_iam_role.bedrock_agent.arn
  foundation_model        = var.bedrock_model_id
  instruction             = local.bedrock_agent_instructions
  prepare_agent           = true
}

resource "aws_bedrockagent_agent_action_group" "get_product_recommendations" {
  action_group_name          = "Get-Product-Recommendations"
  agent_id                   = aws_bedrockagent_agent.product_recommendation.agent_id
  agent_version              = "DRAFT"
  skip_resource_in_use_check = true

  action_group_executor {
    lambda = aws_lambda_function.list_products.arn
  }

  api_schema {
    payload = local.product_api_schema
  }
}

resource "aws_bedrockagent_agent_alias" "prod" {
  agent_alias_name = "cloudmart-prod"
  agent_id         = aws_bedrockagent_agent.product_recommendation.agent_id

  # Ensure the action group is attached before the alias snapshots a version.
  depends_on = [aws_bedrockagent_agent_action_group.get_product_recommendations]
}
