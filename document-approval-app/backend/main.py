from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from functools import lru_cache
from io import BytesIO
from pathlib import Path
from typing import Literal
from urllib.error import URLError
from urllib.request import urlopen
from uuid import uuid4

import boto3
import jwt
from botocore.exceptions import BotoCoreError, ClientError
from fastapi import Depends, FastAPI, File, Form, HTTPException, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import InvalidTokenError
from pydantic import BaseModel, Field
from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
UPLOAD_DIR = BASE_DIR / "local_uploads"
DB_PATH = DATA_DIR / "documents.json"

load_dotenv(BASE_DIR.parent / ".env")

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
S3_BUCKET_NAME = os.getenv("S3_BUCKET_NAME", "")
DOCUMENT_QUEUE_URL = os.getenv("DOCUMENT_QUEUE_URL", "")
DYNAMODB_TABLE_NAME = os.getenv("DYNAMODB_TABLE_NAME", "")
COGNITO_REGION = os.getenv("COGNITO_REGION", AWS_REGION)
COGNITO_USER_POOL_ID = os.getenv("COGNITO_USER_POOL_ID", "")
COGNITO_APP_CLIENT_ID = os.getenv("COGNITO_APP_CLIENT_ID", "")

ALLOWED_STATUSES = {
    "queued",
    "in_review",
    "approved",
    "rejected",
    "processing_failed",
}
PRIORITIES = {"low", "medium", "high"}
MANAGER_GROUP = "manager"
EMPLOYEE_GROUP = "employee"

bearer_scheme = HTTPBearer(auto_error=False)

app = FastAPI(title="Document Approval Workflow API", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class HistoryEvent(BaseModel):
    timestamp: str
    type: str
    message: str
    actor: str | None = None


class DocumentRecord(BaseModel):
    id: str
    title: str
    file_name: str
    content_type: str
    size_bytes: int
    uploaded_by: str
    department: str
    priority: Literal["low", "medium", "high"]
    tags: list[str] = Field(default_factory=list)
    notes: str = ""
    status: str
    storage_key: str
    storage_location: str
    reviewer: str | None = None
    decision_comment: str | None = None
    created_at: str
    updated_at: str
    history: list[HistoryEvent] = Field(default_factory=list)


class RetryRequest(BaseModel):
    note: str = ""


class CurrentUser(BaseModel):
    username: str
    email: str | None = None
    name: str
    groups: list[str] = Field(default_factory=list)
    token_use: str

    @property
    def is_manager(self) -> bool:
        return MANAGER_GROUP in self.groups

    @property
    def is_employee(self) -> bool:
        return EMPLOYEE_GROUP in self.groups


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def ensure_storage() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


def get_cognito_issuer() -> str:
    return f"https://cognito-idp.{COGNITO_REGION}.amazonaws.com/{COGNITO_USER_POOL_ID}"


def require_auth_config() -> None:
    if COGNITO_USER_POOL_ID and COGNITO_APP_CLIENT_ID:
        return
    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail="Cognito is not configured on the backend.",
    )


@lru_cache(maxsize=1)
def load_jwks() -> dict:
    jwks_url = f"{get_cognito_issuer()}/.well-known/jwks.json"
    try:
        with urlopen(jwks_url, timeout=5) as response:
            return json.loads(response.read().decode("utf-8"))
    except (URLError, TimeoutError, json.JSONDecodeError) as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Unable to load Cognito signing keys.",
        ) from exc


def build_seed_documents() -> list[DocumentRecord]:
    now = utc_now()
    return [
        DocumentRecord(
            id="doc-sample-001",
            title="Vendor Contract Renewal",
            file_name="vendor-contract-q3.pdf",
            content_type="application/pdf",
            size_bytes=241_220,
            uploaded_by="Ayesha Khan",
            department="Procurement",
            priority="high",
            tags=["contract", "vendor", "q3"],
            notes="Needs sign-off before Friday's vendor call.",
            status="in_review",
            storage_key="local/sample/vendor-contract-q3.pdf",
            storage_location="local",
            reviewer="Operations Manager",
            created_at=now,
            updated_at=now,
            history=[
                HistoryEvent(
                    timestamp=now,
                    type="uploaded",
                    message="Document uploaded and queued for workflow.",
                    actor="Ayesha Khan",
                ),
                HistoryEvent(
                    timestamp=now,
                    type="status_change",
                    message="Review started by Operations Manager.",
                    actor="Operations Manager",
                ),
            ],
        ),
        DocumentRecord(
            id="doc-sample-002",
            title="Employee Onboarding Pack",
            file_name="onboarding-pack-v4.docx",
            content_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            size_bytes=128_445,
            uploaded_by="Usman Ali",
            department="HR",
            priority="medium",
            tags=["hr", "policy"],
            notes="Waiting for HR head approval.",
            status="queued",
            storage_key="local/sample/onboarding-pack-v4.docx",
            storage_location="local",
            created_at=now,
            updated_at=now,
            history=[
                HistoryEvent(
                    timestamp=now,
                    type="uploaded",
                    message="Document uploaded and queued for workflow.",
                    actor="Usman Ali",
                )
            ],
        ),
        DocumentRecord(
            id="doc-sample-003",
            title="Marketing Budget Amendment",
            file_name="marketing-budget-amendment.xlsx",
            content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            size_bytes=87_512,
            uploaded_by="Maha Noor",
            department="Finance",
            priority="low",
            tags=["budget", "marketing"],
            notes="Revision submitted after CFO comments.",
            status="approved",
            storage_key="local/sample/marketing-budget-amendment.xlsx",
            storage_location="local",
            reviewer="CFO Office",
            decision_comment="Approved with revised allocation caps.",
            created_at=now,
            updated_at=now,
            history=[
                HistoryEvent(
                    timestamp=now,
                    type="uploaded",
                    message="Document uploaded and queued for workflow.",
                    actor="Maha Noor",
                ),
                HistoryEvent(
                    timestamp=now,
                    type="approved",
                    message="Document approved after finance review.",
                    actor="CFO Office",
                ),
            ],
        ),
    ]


def load_documents() -> list[DocumentRecord]:
    ensure_storage()
    if not DB_PATH.exists():
        DB_PATH.write_text(
            json.dumps(
                [doc.model_dump(mode="json") for doc in build_seed_documents()],
                indent=2,
            )
        )
    raw = json.loads(DB_PATH.read_text())
    return [DocumentRecord.model_validate(item) for item in raw]


def save_documents(documents: list[DocumentRecord]) -> None:
    ensure_storage()
    DB_PATH.write_text(json.dumps([doc.model_dump(mode="json") for doc in documents], indent=2))


def get_document_or_404(document_id: str) -> DocumentRecord:
    for document in load_documents():
        if document.id == document_id:
            return document
    raise HTTPException(status_code=404, detail="Document not found")


def replace_document(updated_document: DocumentRecord) -> DocumentRecord:
    documents = load_documents()
    replaced = False
    for index, document in enumerate(documents):
        if document.id == updated_document.id:
            documents[index] = updated_document
            replaced = True
            break
    if not replaced:
        raise HTTPException(status_code=404, detail="Document not found")
    save_documents(documents)
    sync_document_to_dynamodb(updated_document)
    return updated_document


def upload_file_bytes(file_name: str, content_type: str, payload: bytes) -> tuple[str, str]:
    storage_key = f"documents/{datetime.now(timezone.utc).strftime('%Y/%m/%d')}/{uuid4()}-{file_name}"
    if S3_BUCKET_NAME:
        try:
            s3_client = boto3.client("s3", region_name=AWS_REGION)
            s3_client.upload_fileobj(
                BytesIO(payload),
                S3_BUCKET_NAME,
                storage_key,
                ExtraArgs={"ContentType": content_type},
            )
            return storage_key, "s3"
        except (BotoCoreError, ClientError):
            pass

    local_path = UPLOAD_DIR / storage_key.replace("/", "_")
    local_path.parent.mkdir(parents=True, exist_ok=True)
    local_path.write_bytes(payload)
    return str(local_path.relative_to(BASE_DIR)), "local"


def enqueue_document(record: DocumentRecord) -> str:
    if DOCUMENT_QUEUE_URL:
        try:
            sqs_client = boto3.client("sqs", region_name=AWS_REGION)
            sqs_client.send_message(
                QueueUrl=DOCUMENT_QUEUE_URL,
                MessageBody=json.dumps(
                    {
                        "document_id": record.id,
                        "title": record.title,
                        "status": record.status,
                        "uploaded_by": record.uploaded_by,
                        "department": record.department,
                    }
                ),
            )
            return "SQS message queued."
        except (BotoCoreError, ClientError):
            return "Queue delivery failed. Review locally before retrying."
    return "Running in local mode. Queue message simulated."


def sync_document_to_dynamodb(record: DocumentRecord) -> None:
    if not DYNAMODB_TABLE_NAME:
        return
    try:
        dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
        item = record.model_dump(mode="json")
        item["pk"] = f"DOCUMENT#{record.id}"
        item["sk"] = "METADATA"
        table.put_item(Item=item)
    except (BotoCoreError, ClientError):
        return


def add_history(
    document: DocumentRecord,
    event_type: str,
    message: str,
    actor: str | None = None,
) -> DocumentRecord:
    document.history.append(
        HistoryEvent(
            timestamp=utc_now(),
            type=event_type,
            message=message,
            actor=actor,
        )
    )
    document.updated_at = utc_now()
    return document


def summarize_documents(documents: list[DocumentRecord]) -> dict:
    status_counts = {status: 0 for status in ALLOWED_STATUSES}
    department_counts: dict[str, int] = {}
    priority_counts = {priority: 0 for priority in PRIORITIES}

    for document in documents:
        status_counts[document.status] = status_counts.get(document.status, 0) + 1
        department_counts[document.department] = department_counts.get(document.department, 0) + 1
        priority_counts[document.priority] = priority_counts.get(document.priority, 0) + 1

    return {
        "total_documents": len(documents),
        "status_counts": status_counts,
        "department_counts": department_counts,
        "priority_counts": priority_counts,
    }


def extract_groups(payload: dict) -> list[str]:
    groups = payload.get("cognito:groups", [])
    if isinstance(groups, list):
        return [str(group).lower() for group in groups]
    return []


def get_public_key(token: str):
    unverified_header = jwt.get_unverified_header(token)
    kid = unverified_header.get("kid")
    for key in load_jwks().get("keys", []):
        if key.get("kid") == kid:
            return jwt.algorithms.RSAAlgorithm.from_jwk(json.dumps(key))
    raise HTTPException(status_code=401, detail="Unable to match Cognito signing key.")


def verify_cognito_token(token: str) -> CurrentUser:
    require_auth_config()
    public_key = get_public_key(token)
    issuer = get_cognito_issuer()

    try:
        payload = jwt.decode(
            token,
            public_key,
            algorithms=["RS256"],
            issuer=issuer,
            options={"verify_aud": False},
        )
    except InvalidTokenError as exc:
        raise HTTPException(status_code=401, detail="Invalid or expired Cognito token.") from exc

    token_use = payload.get("token_use")
    if token_use not in {"access", "id"}:
        raise HTTPException(status_code=401, detail="Unsupported Cognito token type.")

    if token_use == "access" and payload.get("client_id") != COGNITO_APP_CLIENT_ID:
        raise HTTPException(status_code=401, detail="Cognito token client mismatch.")
    if token_use == "id" and payload.get("aud") != COGNITO_APP_CLIENT_ID:
        raise HTTPException(status_code=401, detail="Cognito token audience mismatch.")

    username = payload.get("cognito:username") or payload.get("username") or payload.get("sub")
    email = payload.get("email")
    name = payload.get("name") or email or username
    if not username:
        raise HTTPException(status_code=401, detail="Cognito token missing username.")

    return CurrentUser(
        username=str(username),
        email=str(email) if email else None,
        name=str(name),
        groups=extract_groups(payload),
        token_use=str(token_use),
    )


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> CurrentUser:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=401, detail="Missing Bearer token.")
    return verify_cognito_token(credentials.credentials)


def require_employee_or_manager(user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
    if user.is_employee or user.is_manager:
        return user
    raise HTTPException(status_code=403, detail="Employee or manager group required.")


def require_manager(user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
    if user.is_manager:
        return user
    raise HTTPException(status_code=403, detail="Manager group required.")


def visible_documents_for_user(user: CurrentUser) -> list[DocumentRecord]:
    documents = load_documents()
    if user.is_manager:
        return documents
    owner_keys = {user.name.lower(), user.username.lower()}
    if user.email:
        owner_keys.add(user.email.lower())
    return [document for document in documents if document.uploaded_by.lower() in owner_keys]


@app.on_event("startup")
def startup() -> None:
    ensure_storage()


@app.get("/health")
def health():
    return {
        "status": "ok",
        "mode": "aws" if any([S3_BUCKET_NAME, DOCUMENT_QUEUE_URL, DYNAMODB_TABLE_NAME]) else "local",
        "services": {
            "s3_bucket_configured": bool(S3_BUCKET_NAME),
            "sqs_queue_configured": bool(DOCUMENT_QUEUE_URL),
            "dynamodb_table_configured": bool(DYNAMODB_TABLE_NAME),
            "cognito_user_pool_configured": bool(COGNITO_USER_POOL_ID),
            "cognito_app_client_configured": bool(COGNITO_APP_CLIENT_ID),
        },
    }


@app.get("/me")
def me(user: CurrentUser = Depends(require_employee_or_manager)):
    return user


@app.get("/dashboard/summary")
def dashboard_summary(user: CurrentUser = Depends(require_employee_or_manager)):
    return summarize_documents(visible_documents_for_user(user))


@app.get("/documents")
def list_documents(
    status: str | None = None,
    department: str | None = None,
    search: str | None = None,
    user: CurrentUser = Depends(require_employee_or_manager),
):
    documents = visible_documents_for_user(user)
    if status:
        documents = [doc for doc in documents if doc.status == status]
    if department:
        documents = [doc for doc in documents if doc.department.lower() == department.lower()]
    if search:
        search_term = search.lower()
        documents = [
            doc
            for doc in documents
            if search_term in doc.title.lower()
            or search_term in doc.file_name.lower()
            or search_term in doc.uploaded_by.lower()
            or search_term in doc.notes.lower()
        ]
    documents.sort(key=lambda doc: doc.updated_at, reverse=True)
    return documents


@app.get("/documents/{document_id}")
def get_document(document_id: str, user: CurrentUser = Depends(require_employee_or_manager)):
    document = get_document_or_404(document_id)
    if user.is_manager or document.uploaded_by.lower() in {
        user.name.lower(),
        user.username.lower(),
        (user.email or "").lower(),
    }:
        return document
    raise HTTPException(status_code=403, detail="You do not have access to this document.")


@app.post("/documents/upload")
async def upload_document(
    file: UploadFile = File(...),
    title: str = Form(""),
    department: str = Form("General"),
    priority: str = Form("medium"),
    notes: str = Form(""),
    tags: str = Form(""),
    user: CurrentUser = Depends(require_employee_or_manager),
):
    if priority not in PRIORITIES:
        raise HTTPException(status_code=400, detail="Priority must be low, medium, or high")

    payload = await file.read()
    if not payload:
        raise HTTPException(status_code=400, detail="Uploaded file is empty")

    document_id = str(uuid4())
    created_at = utc_now()
    actor_name = user.name
    safe_title = title.strip() or Path(file.filename or "Untitled").stem.replace("-", " ").title()
    parsed_tags = [tag.strip() for tag in tags.split(",") if tag.strip()]
    storage_key, storage_location = upload_file_bytes(
        file_name=file.filename or f"{document_id}.bin",
        content_type=file.content_type or "application/octet-stream",
        payload=payload,
    )

    documents = load_documents()
    record = DocumentRecord(
        id=document_id,
        title=safe_title,
        file_name=file.filename or f"{document_id}.bin",
        content_type=file.content_type or "application/octet-stream",
        size_bytes=len(payload),
        uploaded_by=actor_name,
        department=department.strip() or "General",
        priority=priority,
        tags=parsed_tags,
        notes=notes.strip(),
        status="queued",
        storage_key=storage_key,
        storage_location=storage_location,
        created_at=created_at,
        updated_at=created_at,
        history=[
            HistoryEvent(
                timestamp=created_at,
                type="uploaded",
                message="Document uploaded successfully.",
                actor=actor_name,
            )
        ],
    )

    queue_message = enqueue_document(record)
    add_history(record, "queued", queue_message, actor_name)
    documents.append(record)
    save_documents(documents)
    sync_document_to_dynamodb(record)
    return record


@app.post("/documents/{document_id}/approve")
def approve_document(document_id: str, note: RetryRequest, user: CurrentUser = Depends(require_manager)):
    document = get_document_or_404(document_id)
    document.status = "approved"
    document.reviewer = user.name
    document.decision_comment = note.note.strip()
    add_history(document, "approved", note.note.strip() or "Document approved.", user.name)
    return replace_document(document)


@app.post("/documents/{document_id}/reject")
def reject_document(document_id: str, note: RetryRequest, user: CurrentUser = Depends(require_manager)):
    document = get_document_or_404(document_id)
    document.status = "rejected"
    document.reviewer = user.name
    document.decision_comment = note.note.strip()
    add_history(document, "rejected", note.note.strip() or "Document rejected.", user.name)
    return replace_document(document)


@app.post("/documents/{document_id}/retry")
def retry_document(document_id: str, payload: RetryRequest, user: CurrentUser = Depends(require_manager)):
    document = get_document_or_404(document_id)
    document.status = "queued"
    document.reviewer = None
    document.decision_comment = None
    queue_message = enqueue_document(document)
    add_history(
        document,
        "retried",
        payload.note.strip() or queue_message,
        user.name,
    )
    return replace_document(document)
