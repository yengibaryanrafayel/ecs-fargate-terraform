output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "client_id" {
  description = "Cognito App Client ID"
  value       = aws_cognito_user_pool_client.main.id
}

output "user_pool_endpoint" {
  description = "Cognito User Pool endpoint (for JWT issuer URL construction)"
  value       = aws_cognito_user_pool.main.endpoint
}
