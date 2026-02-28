variable "project_name" {
  description = "Resource name prefix"
  type        = string
}

variable "region" {
  description = "AWS region this ECS cluster lives in"
  type        = string
}

variable "email" {
  description = "Email for SNS verification payload"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository URL for SNS verification payload"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the Unleash Live verification SNS topic"
  type        = string
}
