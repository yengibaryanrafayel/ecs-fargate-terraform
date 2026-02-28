output "greeter_invoke_arn" {
  description = "Greeter Lambda invoke ARN (used by API Gateway integration)"
  value       = aws_lambda_function.greeter.invoke_arn
}

output "dispatcher_invoke_arn" {
  description = "Dispatcher Lambda invoke ARN (used by API Gateway integration)"
  value       = aws_lambda_function.dispatcher.invoke_arn
}

output "greeter_function_name" {
  description = "Greeter Lambda function name (used for API GW permission)"
  value       = aws_lambda_function.greeter.function_name
}

output "dispatcher_function_name" {
  description = "Dispatcher Lambda function name (used for API GW permission)"
  value       = aws_lambda_function.dispatcher.function_name
}
