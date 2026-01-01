# 🚀 Terraform + GitHub Actions: One-Click Auto-Scaling Deployment

> **The Problem:** A client needed to deploy multiple simple API applications. Their developers weren't familiar with Terraform or cloud infrastructure, but needed a way to deploy apps with a single click/command. Plus, apps should automatically update whenever code is pushed to GitHub.

> **The Solution:** A fully automated, production-ready infrastructure setup that handles everything from networking to auto-scaling, with seamless CI/CD integration! 🎯

---

## 📋 What This Project Does

- ✅ Deploys a **Flask API application** with a single command
- ✅ Automatically **scales up/down** based on CPU usage (1-3 instances)
- ✅ **Auto-updates** when code is pushed to GitHub (via GitHub Actions)
- ✅ Uses **modular Terraform** architecture for easy maintenance

---

## 🏗️ Architecture

```
Internet → ALB → Target Group → Auto Scaling Group (EC2 instances in private subnets)
```

**Infrastructure Components:**
- 🌐 **Networking**: VPC, Public/Private Subnets, NAT Gateway
- ⚖️ **ALB**: Application Load Balancer with Target Group
- 🚀 **Launch Template**: EC2 with Docker, ECR access, spot instances
- 📈 **ASG**: Auto Scaling with CloudWatch CPU-based scaling

---

## 🛠️ Tech Stack

Terraform | AWS | Docker | ECR | GitHub Actions | Flask

---

## 🚦 Quick Start

**Prerequisites:** AWS CLI, Terraform, Docker

**One-Command Deployment:**
```bash
./scripts/deploy.sh
```

The script automatically: Creates ECR repo → Builds & pushes Docker image → Deploys infrastructure

**Manual Steps:**
```bash
cd terraform
terraform init
terraform apply
```

---

## 🔄 Auto-Update on GitHub Push

GitHub Actions automatically: Builds Docker image → Pushes to ECR → Triggers ASG refresh → Deploys update 🎉

---

## 🎯 Key Features

- 🔄 **Auto-Scaling**: Autoscaling Ec2s based on CPU (65% scale-out, 20% scale-in)
- 🛡️ **Secure**: Private subnets for EC2, public only for ALB
- 🏥 **Health Checks**: ALB ensures only healthy instances receive traffic
- 🚀 **Zero-Downtime**: Rolling updates with instance refresh

---

## 📁 Project Structure

```
├── app/              # Flask application
├── scripts/          # deploy.sh, destroy.sh, test.sh
└── terraform/        # Infrastructure code (modular)
    └── modules/      # networking, ALB, LT, ASG
```

---

## 🧪 Testing & Cleanup

```bash
./scripts/test.sh      # Test health endpoint
./scripts/destroy.sh   # Cleanup all resources
```
