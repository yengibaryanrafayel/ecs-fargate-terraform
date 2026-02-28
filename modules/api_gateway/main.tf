# ─────────────────────────────────────────────────────────────
# HTTP API (API Gateway v2)
# ─────────────────────────────────────────────────────────────
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api-${var.region}"
  protocol_type = "HTTP"
  description   = "Unleash Live regional API — ${var.region}"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Authorization", "Content-Type"]
    max_age       = 300
  }

  tags = {
    Project = var.project_name
    Region  = var.region
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Project = var.project_name
    Region  = var.region
  }
}

# ─────────────────────────────────────────────────────────────
# JWT Authorizer — validates tokens issued by Cognito (us-east-1)
# The Cognito pool always lives in us-east-1 regardless of which
# region this API Gateway is deployed in.
# ─────────────────────────────────────────────────────────────
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.project_name}-cognito-jwt-authorizer"

  jwt_configuration {
    audience = [var.cognito_client_id]
    issuer   = "https://cognito-idp.us-east-1.amazonaws.com/${var.cognito_user_pool_id}"
  }
}

# ─────────────────────────────────────────────────────────────
# Lambda integrations
# ─────────────────────────────────────────────────────────────
resource "aws_apigatewayv2_integration" "greeter" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.greeter_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "dispatcher" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.dispatcher_invoke_arn
  payload_format_version = "2.0"
}

# ─────────────────────────────────────────────────────────────
# Routes — both protected by Cognito JWT authorizer
# ─────────────────────────────────────────────────────────────
resource "aws_apigatewayv2_route" "greet" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /greet"
  target             = "integrations/${aws_apigatewayv2_integration.greeter.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "dispatch" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /dispatch"
  target             = "integrations/${aws_apigatewayv2_integration.dispatcher.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# ─────────────────────────────────────────────────────────────
# Lambda resource-based permissions — allow API GW to invoke
# ─────────────────────────────────────────────────────────────
resource "aws_lambda_permission" "greeter" {
  statement_id  = "AllowAPIGatewayInvokeGreeter"
  action        = "lambda:InvokeFunction"
  function_name = var.greeter_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "dispatcher" {
  statement_id  = "AllowAPIGatewayInvokeDispatcher"
  action        = "lambda:InvokeFunction"
  function_name = var.dispatcher_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
