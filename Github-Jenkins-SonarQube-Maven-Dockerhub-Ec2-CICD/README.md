# 🚀 CI/CD Pipeline: GitHub + Jenkins + SonarQube + Maven + OWASP + DockerHub + EC2

This project showcases a full DevOps CI/CD pipeline I built and tested successfully 💪.  
It automates the process of building, testing, analyzing, scanning, packaging, and deploying a Java-based application using modern tools.

---

## 🔧 Tools & Services Used

- **GitHub** – Code versioning and webhook trigger  
- **Jenkins** – CI/CD orchestration  
- **SonarQube** – Static code analysis and code quality checks  
- **OWASP Dependency-Check** – Vulnerability scanning of dependencies  
- **Maven** – Build and dependency management  
- **Docker & DockerHub** – Containerization and image registry  
- **EC2 (Ubuntu)** – Final deployment environment

---

## 📦 Pipeline Workflow

1. **Source Code Push** – Triggered from GitHub via webhook 🪝
2. **Jenkins Builds the App** – Using Maven  
3. **SonarQube Code Analysis** – Static code quality checks ✅
4. **OWASP Dependency-Check** – Scans for known CVEs (Common Vulnerabilities and Exposures) in dependencies 🔐  
5. **Docker Image Created** – Packaged and tagged 📦
6. **DockerHub Push** – Image uploaded to public/private registry  
7. **EC2 Deployment** – Docker container launched and exposed

---

## ✅ Key Highlights

- Connected **GitHub** triggers directly to Jenkins  
- Integrated **SonarQube** and **OWASP** scans into CI workflow  
- Docker image is automatically built and pushed to **DockerHub**  
- Final app is deployed inside a container on **AWS EC2**  
- All orchestrated through a clean **Jenkinsfile**


---

## 🔍 Why This Matters?

This project reflects a **real-world CI/CD pipeline**, built with multiple layers of quality and security:

- Continuous build, test, and deploy 🔄  
- Code quality and bug detection through **SonarQube** 📊  
- Security-first with **OWASP CVE scanning** 🛡️  
- Lightweight deployments using Docker 🐳  
- Cloud-ready with deployment to **AWS EC2** ☁️

---

## 🙌 Project Status

✅ **Tested**  
✅ **Working**  
✅ **End-to-End Connected**

---

Made by [Zoraiz Ahmad](https://github.com/zoraiz53)
Contact ME on [LINKEDIN](https://www.linkedin.com/in/zoraiz-ahmad-89b402330/)
