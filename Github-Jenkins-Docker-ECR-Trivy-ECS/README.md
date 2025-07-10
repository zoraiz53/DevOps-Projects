# 🚀 ECS Fargate Microservices Project

This project demonstrates how to deploy a **secure microservices architecture** using **AWS ECS with Fargate**. It features a **frontend** and **backend**, each containerized and deployed through **Amazon ECR** and **ECS Services**.

## 🧩 Project Overview

- Built two separate Docker images (Frontend & Backend)
- Pushed images to **Amazon ECR**
- Created an **ECS Fargate Cluster**
- Deployed each service on its own ECS Task
- Attached **Application Load Balancer (ALB)** to the frontend
- Enabled frontend to securely communicate with backend over port `3001`

## ⚙️ Key Highlights

- Frontend container exposed publicly through **ALB**
- Backend remains private and only accessible from frontend
- Used **Jenkins pipeline** to automate Docker builds and ECR uploads
- Followed best practices for container port mapping and service isolation

## 📁 Technologies Used

- AWS ECS (Fargate)
- AWS ECR
- AWS ALB
- Docker
- Jenkins (CI/CD)

## 🔐 Security Focus

- Backend not exposed to the internet
- Only frontend service is public-facing
- Clean separation of services with internal networking

## 📌 Notes

Some ECS setup steps were automated via Jenkins, while others (like ALB configuration) were handled manually. This project can be a great base for more advanced CI/CD and infrastructure automation setups.

---

Made by [Zoraiz Ahmad](https://github.com/zoraiz53)
Contact ME on [LINKEDIN](https://www.linkedin.com/in/zoraiz-ahmad-89b402330/)