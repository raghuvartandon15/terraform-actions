# s3
# iam
# lambda
# ecr
# api-gateway

resource "aws_s3_bucket" "model_bucket" {
  bucket = "gh-actions-model-bucket-raghuvar"
}

resource "aws_ecr_repository" "image_repo" {
  name = "gh_actions_image_repo"
}

resource "aws_iam_role" "lambda_role" {
  name = "gh_actions_lambda_iam_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_write_logs_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_lambda_function" "actions_lambda" {
  count         = var.deploy_lambda ? 1 : 0
  function_name = "gh_actions_lambda"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.image_repo.repository_url}:${var.image_tag}"
  role          = aws_iam_role.lambda_role.arn
  memory_size   = 512
  timeout       = 30
  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.model_bucket.bucket
      S3_MODEL_FILE  = "ml_pipiline.pkl"
    }
  }
}

resource "aws_apigatewayv2_api" "model_api" {
  name          = "gh-actions-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  count                  = var.deploy_lambda ? 1 : 0
  api_id                 = aws_apigatewayv2_api.model_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.actions_lambda[0].invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_route" {
  count     = var.deploy_lambda ? 1 : 0
  api_id    = aws_apigatewayv2_api.model_api.id
  route_key = "GET /home"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration[0].id}"
}

resource "aws_apigatewayv2_route" "post_route" {
  count     = var.deploy_lambda ? 1 : 0
  api_id    = aws_apigatewayv2_api.model_api.id
  route_key = "POST /predict2"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration[0].id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  count       = var.deploy_lambda ? 1 : 0
  api_id      = aws_apigatewayv2_api.model_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_permission" {
  count         = var.deploy_lambda ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.actions_lambda[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.model_api.execution_arn}/*/*"
}