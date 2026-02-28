# ─────────────────────────────────────────────────────────────
# Package Lambda source code into ZIP archives
# ─────────────────────────────────────────────────────────────
data "archive_file" "greeter" {
  type       = "zip"
  source_dir = "${path.module}/functions/greeter"
  # Include region so both module instances write to separate files.
  # (path.module resolves to the same directory for both us-east-1 and eu-west-1
  # instances of this module, so a shared output_path would cause a write conflict.)
  output_path = "${path.module}/functions/greeter-${var.region}.zip"
}

data "archive_file" "dispatcher" {
  type        = "zip"
  source_dir  = "${path.module}/functions/dispatcher"
  output_path = "${path.module}/functions/dispatcher-${var.region}.zip"
}

# ─────────────────────────────────────────────────────────────
# Shared IAM Execution Role for both Lambda functions
# ─────────────────────────────────────────────────────────────
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-role-${var.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = { Project = var.project_name }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name = "${var.project_name}-lambda-policy-${var.region}"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Greeter: write greeting records to the regional DynamoDB table
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = [var.dynamodb_table_arn]
      },
      # Greeter: cross-region publish to the SNS verification topic
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = [var.sns_topic_arn]
      },
      # Dispatcher: launch the ECS Fargate task
      {
        Effect   = "Allow"
        Action   = ["ecs:RunTask", "ecs:DescribeTasks"]
        Resource = ["*"]
      },
      # Dispatcher: pass IAM roles to ECS (required by RunTask)
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = [var.ecs_task_execution_role_arn, var.ecs_task_role_arn]
      }
    ]
  })
}

# ─────────────────────────────────────────────────────────────
# CloudWatch Log Groups (pre-create to control retention)
# ─────────────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "greeter" {
  name              = "/aws/lambda/${var.project_name}-greeter-${var.region}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "dispatcher" {
  name              = "/aws/lambda/${var.project_name}-dispatcher-${var.region}"
  retention_in_days = 7
}

# ─────────────────────────────────────────────────────────────
# Lambda 1 — Greeter
# Triggered by GET /greet
# Writes to DynamoDB → publishes SNS → returns region
# ─────────────────────────────────────────────────────────────
resource "aws_lambda_function" "greeter" {
  function_name    = "${var.project_name}-greeter-${var.region}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.greeter.output_path
  source_code_hash = data.archive_file.greeter.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      SNS_TOPIC_ARN       = var.sns_topic_arn
      EMAIL               = var.email
      GITHUB_REPO         = var.github_repo
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_logs,
    aws_cloudwatch_log_group.greeter,
  ]

  tags = {
    Project = var.project_name
    Region  = var.region
  }
}

# ─────────────────────────────────────────────────────────────
# Lambda 2 — Dispatcher
# Triggered by POST /dispatch
# Calls ECS RunTask to launch the Fargate SNS-publisher task
# ─────────────────────────────────────────────────────────────
resource "aws_lambda_function" "dispatcher" {
  function_name    = "${var.project_name}-dispatcher-${var.region}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.dispatcher.output_path
  source_code_hash = data.archive_file.dispatcher.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      ECS_CLUSTER_ARN         = var.ecs_cluster_arn
      ECS_TASK_DEFINITION_ARN = var.task_definition_arn
      SUBNET_IDS              = join(",", var.subnet_ids)
      SECURITY_GROUP_ID       = var.security_group_id
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_logs,
    aws_cloudwatch_log_group.dispatcher,
  ]

  tags = {
    Project = var.project_name
    Region  = var.region
  }
}
