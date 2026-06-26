from __future__ import annotations

import json
import os
from datetime import datetime, timezone

import boto3
from botocore.exceptions import BotoCoreError, ClientError


AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
DYNAMODB_TABLE_NAME = os.getenv("DYNAMODB_TABLE_NAME", "")


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def update_document_status(document_id: str, title: str) -> dict:
    if not DYNAMODB_TABLE_NAME:
        return {
            "document_id": document_id,
            "status": "in_review",
            "message": "Local mode: DynamoDB table not configured.",
        }

    dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
    table = dynamodb.Table(DYNAMODB_TABLE_NAME)
    updated_at = utc_now()
    history_event = {
        "timestamp": updated_at,
        "type": "lambda_processed",
        "message": f"Workflow processor picked up {title}.",
        "actor": "workflow_processor",
    }

    table.update_item(
        Key={"pk": f"DOCUMENT#{document_id}", "sk": "METADATA"},
        UpdateExpression=(
            "SET #status = :status, updated_at = :updated_at, "
            "history = list_append(if_not_exists(history, :empty_list), :history_event)"
        ),
        ExpressionAttributeNames={"#status": "status"},
        ExpressionAttributeValues={
            ":status": "in_review",
            ":updated_at": updated_at,
            ":empty_list": [],
            ":history_event": [history_event],
        },
    )
    return {"document_id": document_id, "status": "in_review", "message": "Workflow updated."}


def handler(event, context):
    processed = []
    for record in event.get("Records", []):
        try:
            payload = json.loads(record["body"])
            result = update_document_status(
                document_id=payload["document_id"],
                title=payload.get("title", "document"),
            )
            processed.append(result)
        except (KeyError, json.JSONDecodeError, BotoCoreError, ClientError) as error:
            processed.append({"status": "failed", "error": str(error), "record": record.get("body")})
    return {"processed": processed}
