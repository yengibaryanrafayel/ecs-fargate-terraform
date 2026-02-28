output "cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.main.name
}

output "task_definition_arn" {
  description = "ECS Task Definition ARN"
  value       = aws_ecs_task_definition.sns_publisher.arn
}

output "execution_role_arn" {
  description = "ECS Task Execution Role ARN (for Lambda PassRole)"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "task_role_arn" {
  description = "ECS Task Role ARN (for Lambda PassRole)"
  value       = aws_iam_role.ecs_task_role.arn
}
