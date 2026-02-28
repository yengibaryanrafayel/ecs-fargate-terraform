variable "project_name" {
  description = "Resource name prefix"
  type        = string
}

variable "region" {
  description = "AWS region this API is deployed in"
  type        = string
}

variable "greeter_invoke_arn" {
  description = "Greeter Lambda invoke ARN"
  type        = string
}

variable "dispatcher_invoke_arn" {
  description = "Dispatcher Lambda invoke ARN"
  type        = string
}

variable "greeter_function_name" {
  description = "Greeter Lambda function name (for resource-based policy)"
  type        = string
}

variable "dispatcher_function_name" {
  description = "Dispatcher Lambda function name (for resource-based policy)"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID used to construct the JWT issuer URL"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito App Client ID used as JWT audience"
  type        = string
}
