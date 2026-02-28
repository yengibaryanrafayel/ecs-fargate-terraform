variable "project_name" {
  description = "Resource name prefix"
  type        = string
}

variable "email" {
  description = "Email address for the Cognito test user"
  type        = string
}

variable "temp_password" {
  description = "Temporary password for the test user"
  type        = string
  sensitive   = true
}
