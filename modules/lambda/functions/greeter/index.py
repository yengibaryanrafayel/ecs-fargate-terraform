"""
Lambda 1 — Greeter
GET /greet

1. Writes a greeting record to the regional DynamoDB table.
2. Publishes a verification payload to the Unleash Live SNS topic (always us-east-1).
3. Returns 200 OK with the executing region in the JSON body.
"""

import json
import os
import uuid
from datetime import datetime, timezone

import boto3


def handler(event, context):
    region = os.environ["AWS_REGION"]
    table_name = os.environ["DYNAMODB_TABLE_NAME"]
    sns_topic_arn = os.environ["SNS_TOPIC_ARN"]
    email = os.environ["EMAIL"]
    github_repo = os.environ["GITHUB_REPO"]

    # 1. Write greeting record to the regional DynamoDB table
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(table_name)
    table.put_item(
        Item={
            "id": str(uuid.uuid4()),
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "region": region,
            "source": "Lambda-Greeter",
        }
    )

    # 2. Publish verification payload to SNS.
    #    The topic lives in us-east-1; we always target that region explicitly
    #    so this works correctly even when executing from eu-west-1.
    sns = boto3.client("sns", region_name="us-east-1")
    payload = {
        "email": email,
        "source": "Lambda",
        "region": region,
        "repo": github_repo,
    }
    sns.publish(TopicArn=sns_topic_arn, Message=json.dumps(payload))

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "message": f"Hello from Greeter!",
                "region": region,
            }
        ),
    }
