output "cognito_user_pool_id" {
  description = "Cognito User Pool ID (us-east-1)"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito App Client ID used for JWT authentication"
  value       = module.cognito.client_id
}

output "us_east_1_api_url" {
  description = "API Gateway invoke URL for us-east-1"
  value       = module.us_east_1.api_url
}

output "eu_west_1_api_url" {
  description = "API Gateway invoke URL for eu-west-1"
  value       = module.eu_west_1.api_url
}
