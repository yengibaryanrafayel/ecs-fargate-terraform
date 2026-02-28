variable "project_name" {
  description = "Resource name prefix"
  type        = string
}

variable "region" {
  description = "AWS region this stack is deployed into (used for naming and payloads)"
  type        = string
}

variable "email" {
  description = "Email for SNS verification payloads"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository URL for SNS verification payloads"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID (always in us-east-1) used by API Gateway JWT authorizer"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito App Client ID used as JWT audience"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the Unleash Live verification SNS topic"
  type        = string
}
