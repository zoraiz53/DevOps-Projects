# 🚀 GitHub-Docker-ECR-Terraform-ASG-Slack

A complete DevOps automation pipeline that builds Docker images, pushes to AWS ECR, provisions infrastructure via Terraform (Auto Scaling, Networking), and sends real-time Slack alerts — fully production-ready.

---

## 🔧 What This Project Does

- Builds & pushes Docker images from GitHub to **AWS ECR**
- Uses **Terraform** to provision:
  - VPC, Security Groups, IAM
  - Launch Templates & Auto Scaling Group
- Deploys Docker containers on EC2 via ASG
- Sends **Slack alerts** after deployment or infra changes

---

## 📦 Tools & Tech

- **AWS** (ECR, EC2, ASG, IAM, VPC)
- **Terraform** (Infrastructure as Code)
- **Docker** (containerization)
- **Slack** (notifications)

---

## 🚀 How to Run

```bash
# Clone the project
git clone https://github.com/zoraiz53/DevOps-Projects.git
cd DevOps-Projects/Github-Docker-ECR-Terraform-ASG-Slack

# Build and push image to ECR
./scripts/build_and_push.sh

# Deploy infrastructure & app using Terraform
cd terraform
terraform init
terraform apply -auto-approve


Outcome & Organizational Benefits ✅

🔁 Fully automated CI/CD pipeline from code to deployment
📦 Reliable, containerized deployments via Docker and ECR
⚙️ Scalable infrastructure with zero manual intervention
🔒 Secure provisioning using IAM roles and best practices
📡 Slack alerts enable fast feedback and monitoring
📉 Reduces manual ops effort and deployment time
🚀 Accelerates feature delivery with minimal human input
🧩 Modular codebase for easy integration and reuse
📊 Follows industry-standard practices for production readiness

---

Made by [Zoraiz Ahmad](https://github.com/zoraiz53)
Contact ME on [LINKEDIN](https://www.linkedin.com/in/zoraiz-ahmad-89b402330/)