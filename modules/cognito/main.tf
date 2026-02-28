resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-user-pool"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # USER_PASSWORD_AUTH is required for the test script to authenticate programmatically
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  generate_secret = false
}

# Test user — email verified, password in FORCE_CHANGE_PASSWORD state initially.
# The test script handles the NEW_PASSWORD_REQUIRED challenge automatically.
resource "aws_cognito_user" "test_user" {
  user_pool_id = aws_cognito_user_pool.main.id
  username     = var.email

  attributes = {
    email          = var.email
    email_verified = "true"
  }

  temporary_password = var.temp_password
  message_action     = "SUPPRESS"
}
