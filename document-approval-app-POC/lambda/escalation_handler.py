from __future__ import annotations

import os
from datetime import datetime, timedelta, timezone
from decimal import Decimal

import boto3
from botocore.exceptions import BotoCoreError, ClientError


AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
DYNAMODB_TABLE_NAME = os.getenv("DYNAMODB_TABLE_NAME", "")
ESCALATION_WINDOW_HOURS = int(os.getenv("ESCALATION_WINDOW_HOURS", "24"))


def iso_to_datetime(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def handler(event, context):
    if not DYNAMODB_TABLE_NAME:
        return {"status": "skipped", "message": "DynamoDB table not configured."}

    try:
        table = boto3.resource("dynamodb", region_name=AWS_REGION).Table(DYNAMODB_TABLE_NAME)
        response = table.scan()
        threshold = datetime.now(timezone.utc) - timedelta(hours=ESCALATION_WINDOW_HOURS)
        escalated = []

        for item in response.get("Items", []):
            status = item.get("status")
            updated_at = item.get("updated_at")
            if status not in {"queued", "in_review"} or not updated_at:
                continue

            if iso_to_datetime(updated_at) > threshold:
                continue

            history = item.get("history", [])
            history.append(
                {
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "type": "escalated",
                    "message": "Document exceeded review window and was flagged for attention.",
                    "actor": "escalation_handler",
                }
            )
            table.update_item(
                Key={"pk": item["pk"], "sk": item["sk"]},
                UpdateExpression="SET history = :history, escalation_hours = :hours",
                ExpressionAttributeValues={
                    ":history": history,
                    ":hours": Decimal(str(ESCALATION_WINDOW_HOURS)),
                },
            )
            escalated.append(item.get("id"))

        return {"status": "done", "escalated_documents": escalated}
    except (BotoCoreError, ClientError) as error:
        return {"status": "failed", "error": str(error)}
