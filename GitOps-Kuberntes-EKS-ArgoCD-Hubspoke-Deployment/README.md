# 🚀 GitOps on EKS with Jenkins & ArgoCD

This project demonstrates an automated multi-cluster deployment pipeline using **Git tags**, **Jenkins**, **Docker**, **ArgoCD**, and a **hub-spoke EKS model**.

---

## 🔧 Full Pipeline Breakdown

### 📦 GitHub (App Repository)
- Stores the full application code and a `Jenkinsfile`
- **Triggering Mechanism**: Uses **Git tags only** (not commits)
  - Tag format: `<app-name>-v1.0.0`
  - Jenkins uses regex to extract the version (e.g., `1.0.0`)
  - Version is stored in a pipeline variable after validation

### ⚙️ Jenkins (Running on EC2)
- A **Multibranch Pipeline Job** runs on EC2
- When a valid tag is pushed:
  1. Jenkins builds a Docker image using the app code (Stored in Github repo)
  2. Tags the image with the extracted version
  3. Pushes the image to **AWS ECR**
  4. Clones the **Kubernetes Manifest repo**
  5. Updates the image version in:
     ```yaml
     manifests/guest-book/deployment.yml
     - image: 084828598848.dkr.ecr.us-east-1.amazonaws.com/our-project:<version>
     ```
  6. Commits and pushes the updated manifest to GitHub

### 🤖 ArgoCD (Running on Hub Cluster)
- ArgoCD is installed on the **hub EKS cluster**
- Monitors the manifest repo using a **GitHub webhook**
- When it detects a commit:
  - Automatically syncs **spoke-cluster-1** to use the updated Docker image
  - Ensures the declared state in Git is reflected in the running cluster

---

## 🧠 Why This Design Works

- ✅ **Version-controlled Deployments**: Git tags make versioning and rollbacks easier
- 🚀 **End-to-End Automation**: No manual approvals or triggers are needed
- 🔁 **GitOps Philosophy**: Declarative manifests + Git = true single source of truth
- 🌍 **Scalability**: ArgoCD hub manages one or many clusters via config

---

## 💼 Real-World Organizational Benefits

- 🕒 **Faster Delivery**: Code to deployment in minutes
- 🔍 **Audit-Ready**: Every deployment, every change, traceable via Git
- 🔄 **Resilient Rollbacks**: ArgoCD can auto-revert failed or drifted deployments
- 🔒 **Secure & Controlled**: Image builds, tag validations, and cluster updates follow a clear, gated pipeline

---

## 🛣️ Future Enhancements

- Add **test automation** before manifest updates
- Use **image scanning (Trivy)** before push
- Enable **progressive rollouts** (canary or blue-green)
- Add **RBAC & project scoping** in ArgoCD for team isolation

---

Made by [Zoraiz Ahmad](https://github.com/zoraiz53)
Contact ME on [LINKEDIN](https://www.linkedin.com/in/zoraiz-ahmad-89b402330/)


