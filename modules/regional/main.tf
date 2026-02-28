# ─────────────────────────────────────────────────────────────
# Regional stack — called once per region from the root module.
# Each sub-module inherits the provider alias passed by the caller.
# ─────────────────────────────────────────────────────────────

module "networking" {
  source = "../networking"

  project_name = var.project_name
  region       = var.region
}

module "dynamodb" {
  source = "../dynamodb"

  project_name = var.project_name
  region       = var.region
}

module "ecs" {
  source = "../ecs"

  project_name  = var.project_name
  region        = var.region
  email         = var.email
  github_repo   = var.github_repo
  sns_topic_arn = var.sns_topic_arn
}

module "lambda" {
  source = "../lambda"

  project_name                = var.project_name
  region                      = var.region
  dynamodb_table_name         = module.dynamodb.table_name
  dynamodb_table_arn          = module.dynamodb.table_arn
  ecs_cluster_arn             = module.ecs.cluster_arn
  task_definition_arn         = module.ecs.task_definition_arn
  ecs_task_execution_role_arn = module.ecs.execution_role_arn
  ecs_task_role_arn           = module.ecs.task_role_arn
  subnet_ids                  = module.networking.public_subnet_ids
  security_group_id           = module.networking.ecs_security_group_id
  email                       = var.email
  github_repo                 = var.github_repo
  sns_topic_arn               = var.sns_topic_arn
}

module "api_gateway" {
  source = "../api_gateway"

  project_name             = var.project_name
  region                   = var.region
  greeter_invoke_arn       = module.lambda.greeter_invoke_arn
  dispatcher_invoke_arn    = module.lambda.dispatcher_invoke_arn
  greeter_function_name    = module.lambda.greeter_function_name
  dispatcher_function_name = module.lambda.dispatcher_function_name
  cognito_user_pool_id     = var.cognito_user_pool_id
  cognito_client_id        = var.cognito_client_id
}
