# Document Approval Workflow on AWS ECS

Production-style document approval platform built around ECS Fargate, Amazon Cognito, S3, SQS, Lambda, and DynamoDB. Employees upload approval documents through a React frontend, managers review them through protected workflows, and the backend keeps audit history and status updates in sync across the pipeline.

## Architecture Flow

Browser signs in with Cognito  
--> React frontend served from ECS behind an ALB  
--> FastAPI backend on ECS verifies Cognito JWTs and accepts document actions  
--> Uploaded files go to S3  
--> Metadata and approval history go to DynamoDB  
--> Processing jobs go to SQS  
--> Lambda workers consume queue messages and update workflow state  
--> Managers approve, reject, or retry documents from the dashboard

## What I Implemented

- Containerized frontend and backend services for ECS Fargate
- Cognito-based authentication with role separation through user groups
- JWT verification and role-based access control in FastAPI
- Document upload, review, retry, and audit timeline handling
- S3, SQS, Lambda, and DynamoDB integration for the workflow pipeline
- ALB-based service exposure and environment-driven deployment config

## Stack

- Frontend: React + TypeScript
- Backend: FastAPI
- Compute: ECS Fargate
- Auth: Amazon Cognito
- Storage: Amazon S3
- Messaging: Amazon SQS
- Data: Amazon DynamoDB
- Async processing: AWS Lambda

## Local Run

```bash
cp .env.example .env
# fill in your own AWS resource values

docker compose up --build
```

Frontend:

```text
http://localhost:8080
```

Backend:

```text
http://localhost:8000
```

## Notes

- This repo is sanitized for portfolio use. Real environment values are not included.
- Cognito users and AWS resource identifiers should be supplied through `.env` or ECS task definition environment variables.
- This is juts a POC (Proof Of Concept). The actual app I deployed into Production had several other features and functionality.