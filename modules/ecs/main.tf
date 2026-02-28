# ─────────────────────────────────────────────────────────────
# ECS Cluster
# ─────────────────────────────────────────────────────────────
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster-${var.region}"

  setting {
    name  = "containerInsights"
    value = "disabled" # cost-optimised: disable for sandbox
  }

  tags = {
    Name    = "${var.project_name}-cluster"
    Project = var.project_name
    Region  = var.region
  }
}

# ─────────────────────────────────────────────────────────────
# IAM — Task Execution Role (ECS agent pulls image, writes logs)
# ─────────────────────────────────────────────────────────────
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-exec-role-${var.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = { Project = var.project_name }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ─────────────────────────────────────────────────────────────
# IAM — Task Role (what the container itself can do)
# ─────────────────────────────────────────────────────────────
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role-${var.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = { Project = var.project_name }
}

resource "aws_iam_role_policy" "ecs_task_sns_publish" {
  name = "${var.project_name}-ecs-sns-policy-${var.region}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sns:Publish"]
      Resource = [var.sns_topic_arn]
    }]
  })
}

# ─────────────────────────────────────────────────────────────
# CloudWatch Log Group for container output
# ─────────────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-fargate-${var.region}"
  retention_in_days = 7

  tags = {
    Project = var.project_name
    Region  = var.region
  }
}

# ─────────────────────────────────────────────────────────────
# Task Definition
# Uses amazon/aws-cli image — entrypoint is the `aws` binary.
# The command array is the CLI arguments that publish to SNS and exit.
# The JSON payload is baked in at Terraform apply time.
# ─────────────────────────────────────────────────────────────
resource "aws_ecs_task_definition" "sns_publisher" {
  family                   = "${var.project_name}-sns-publisher-${var.region}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name = "sns-publisher"
    # ECR Public mirror of amazon/aws-cli — avoids Docker Hub rate limits in AWS.
    # Entrypoint is the `aws` binary; command array supplies the CLI arguments.
    image     = "public.ecr.aws/aws-cli/aws-cli:latest"
    essential = true
    command = [
      "sns", "publish",
      "--topic-arn", var.sns_topic_arn,
      "--region", "us-east-1",
      "--message", "{\"email\":\"${var.email}\",\"source\":\"ECS\",\"region\":\"${var.region}\",\"repo\":\"${var.github_repo}\"}"
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Project = var.project_name
    Region  = var.region
  }
}
