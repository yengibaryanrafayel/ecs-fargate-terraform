variable "project_name" {
  description = "Resource name prefix"
  type        = string
}

variable "region" {
  description = "AWS region (used in naming and IAM policies)"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the regional DynamoDB table"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the regional DynamoDB table (for IAM policy)"
  type        = string
}

variable "ecs_cluster_arn" {
  description = "ECS Cluster ARN for the Dispatcher to target"
  type        = string
}

variable "task_definition_arn" {
  description = "ECS Task Definition ARN for the Dispatcher to launch"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ECS Task Execution Role ARN (Lambda needs PassRole for this)"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ECS Task Role ARN (Lambda needs PassRole for this)"
  type        = string
}

variable "subnet_ids" {
  description = "Public subnet IDs for Fargate task networking (passed to RunTask)"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group for Fargate tasks (passed to RunTask)"
  type        = string
}

variable "email" {
  description = "Email for Greeter SNS verification payload"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo URL for Greeter SNS verification payload"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the Unleash Live verification SNS topic"
  type        = string
}
