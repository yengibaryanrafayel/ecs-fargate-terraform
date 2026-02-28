variable "email" {
  description = "Your email address used for the Cognito test user and SNS verification payloads"
  type        = string
}

variable "github_repo" {
  description = "Your public GitHub repository URL (e.g. https://github.com/username/aws-assessment)"
  type        = string
}

variable "project_name" {
  description = "Prefix applied to every resource name for easy identification"
  type        = string
  default     = "unleash-live"
}

variable "cognito_temp_password" {
  description = "Temporary password for the Cognito test user (must satisfy pool policy)"
  type        = string
  sensitive   = true
}
