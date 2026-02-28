"""
Lambda 2 — Dispatcher
POST /dispatch

Calls ECS RunTask to launch a standalone Fargate task in the same region.
The Fargate task (amazon/aws-cli image) publishes to SNS and exits.
"""

import json
import os

import boto3


def handler(event, context):
    region = os.environ["AWS_REGION"]
    cluster_arn = os.environ["ECS_CLUSTER_ARN"]
    task_definition_arn = os.environ["ECS_TASK_DEFINITION_ARN"]
    subnet_ids = os.environ["SUBNET_IDS"].split(",")
    security_group_id = os.environ["SECURITY_GROUP_ID"]

    ecs = boto3.client("ecs", region_name=region)

    response = ecs.run_task(
        cluster=cluster_arn,
        taskDefinition=task_definition_arn,
        launchType="FARGATE",
        networkConfiguration={
            "awsvpcConfiguration": {
                "subnets": subnet_ids,
                # Public IP required — tasks run in a public subnet with no NAT gateway
                "assignPublicIp": "ENABLED",
                "securityGroups": [security_group_id],
            }
        },
    )

    task_arn = None
    failures = response.get("failures", [])
    if response.get("tasks"):
        task_arn = response["tasks"][0]["taskArn"]

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "message": "ECS Fargate task dispatched!",
                "region": region,
                "taskArn": task_arn,
                "failures": failures,
            }
        ),
    }
