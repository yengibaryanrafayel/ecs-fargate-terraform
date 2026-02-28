# ─────────────────────────────────────────────────────────────
# Authentication — Cognito lives exclusively in us-east-1
# ─────────────────────────────────────────────────────────────
module "cognito" {
  source = "./modules/cognito"

  providers = {
    aws = aws.us_east_1
  }

  project_name  = var.project_name
  email         = var.email
  temp_password = var.cognito_temp_password
}

# ─────────────────────────────────────────────────────────────
# Regional compute stack — us-east-1
# ─────────────────────────────────────────────────────────────
module "us_east_1" {
  source = "./modules/regional"

  providers = {
    aws = aws.us_east_1
  }

  project_name         = var.project_name
  region               = "us-east-1"
  email                = var.email
  github_repo          = var.github_repo
  cognito_user_pool_id = module.cognito.user_pool_id
  cognito_client_id    = module.cognito.client_id
  sns_topic_arn        = "arn:aws:sns:us-east-1:637226132752:Candidate-Verification-Topic"
}

# ─────────────────────────────────────────────────────────────
# Regional compute stack — eu-west-1 (identical module, different provider)
# ─────────────────────────────────────────────────────────────
module "eu_west_1" {
  source = "./modules/regional"

  providers = {
    aws = aws.eu_west_1
  }

  project_name         = var.project_name
  region               = "eu-west-1"
  email                = var.email
  github_repo          = var.github_repo
  cognito_user_pool_id = module.cognito.user_pool_id
  cognito_client_id    = module.cognito.client_id
  sns_topic_arn        = "arn:aws:sns:us-east-1:637226132752:Candidate-Verification-Topic"
}
