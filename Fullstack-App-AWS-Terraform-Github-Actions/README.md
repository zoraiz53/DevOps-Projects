# 🚀 Full-Stack App on AWS with Terraform & GitHub Actions

This project deploys a full-stack app on two AWS EC2 instances (frontend + backend) using Terraform and GitHub Actions. It’s clean, modular, and fully automated! 💥

---

## 🌐 App Overview

🐍 Built with Python Flask  
🖥️ Frontend shows the UI, calls the API  
🛠️ Backend serves API (e.g., /api/users)  
🐳 Both are Dockerized  
🌍 Frontend gets BACKEND_URL via env var  
🔒 Frontend in public subnet ☁️  
🔐 Backend in private subnet (secure!)  

---

## 🛠️ Terraform: Infra as Code

Everything is defined as code in `terraform-code/`. Key components:

### 🌐 Networking

✅ VPC with public + private subnets  
🌐 Public subnet → Internet Gateway  
🔒 Private subnet → NAT Gateway  

### 🔐 Security Groups

🖥️ Frontend SG: allows HTTP (3000), SSH  
🔧 Backend SG: only allows traffic from frontend on port 5000  

### 💻 EC2 Instances

🧩 2 instances: frontend (public), backend (private)  
🚀 Uses user-data scripts to pull Docker images from ECR & run containers  
☁️ SSH access with key pairs  
📦 State stored in S3 + DynamoDB for safe collaboration  

### 📦 Modular Terraform

Clean modules: VPC, subnets, SGs, EC2  
Plug & play structure (inputs/outputs defined)  
🔍 Preview changes before applying with `terraform plan`  

---

## 🔄 CI/CD with GitHub Actions

We’ve automated the entire workflow! 🧠

### 1. ☁️ Infra Provisioning

Push to `main` → runs `terraform init`, `plan`, `apply`  
Secrets handled securely 🔒  

### 2. 🐳 Docker Build & Push

Auto builds frontend & backend images  
Pushes to Amazon ECR  
No more manual Docker hustle 🚫  

### 3. ⚙️ Auto Deploy on EC2

EC2 runs user-data scripts at boot  
Pulls latest Docker images from ECR  
Runs containers instantly 💨  
Bonus: ✅ Cron jobs keep them up-to-date automatically  

---

## 🎯 Why This Rocks for Organizations

🔁 **Consistency**: Same infra every time with Terraform  
⚡ **Speed**: CI/CD means fast, error-free updates  
📈 **Scalability**: Easily scale or replicate the stack  
🛡️ **Security**: Only required ports open; secrets managed  
🤝 **Team-Friendly**: Everything in Git — transparent & traceable  

---

## 💡 TL;DR

**Infrastructure?** Code.  
**Deployments?** Automated.  
**Workflow?** DevOps-ready.  
**This repo = 🔥 for any team aiming for speed, quality, and scalability.**


Made by [Zoraiz Ahmad](https://github.com/zoraiz53)
Contact ME on [LINKEDIN](https://www.linkedin.com/in/zoraiz-ahmad-89b402330/)