output "api_url" {
  description = "API Gateway invoke URL for this region"
  value       = module.api_gateway.api_url
}

output "greeter_function_name" {
  description = "Greeter Lambda function name"
  value       = module.lambda.greeter_function_name
}

output "dispatcher_function_name" {
  description = "Dispatcher Lambda function name"
  value       = module.lambda.dispatcher_function_name
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN for this region"
  value       = module.ecs.cluster_arn
}
