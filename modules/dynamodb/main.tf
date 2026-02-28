resource "aws_dynamodb_table" "greeting_logs" {
  name         = "${var.project_name}-GreetingLogs-${var.region}"
  billing_mode = "PAY_PER_REQUEST" # on-demand — no capacity planning needed
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name    = "${var.project_name}-GreetingLogs"
    Project = var.project_name
    Region  = var.region
  }
}
