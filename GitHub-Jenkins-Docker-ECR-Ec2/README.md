🚀 DevOps Project: Flask App CI/CD with Jenkins, Docker & AWS
This project showcases an end-to-end CI/CD pipeline that builds, stores, and deploys a Dockerized Flask application using Jenkins and AWS infrastructure.

---

⚙️ Key Components
Flask App: Simple Python web app as the base.

Docker: Image built via a custom Dockerfile (/GitHub-Jenkins-Docker-ECR-Ec2/Dockerfile).

Jenkins: Hosted on EC2 (port 8080), used to automate the entire pipeline.

AWS ECR: Stores Docker images pushed from Jenkins.

EC2 (App Server): Pulls the image from ECR and runs the container.

---

📄 Jenkinsfile Overview
Located at /GitHub-Jenkins-Docker-ECR-Ec2/Jenkinsfile, it includes:

Cloning the GitHub repo

Building the Docker image

Pushing to ECR

SSH into EC2 and running the latest container

The pipeline uses environment variables, AWS CLI, and GitHub credentials via Jenkins for clean, automated flow.

---

🧠 Skills Highlighted
CI/CD with Jenkins

Docker + AWS ECR

Secure EC2-based deployment

GitHub-Jenkins integration

---

✅ Summary
A practical DevOps project demonstrating CI/CD, Dockerization, and AWS-based deployment. Built for automation, reliability, and clean infrastructure flow.

Made by [Zoraiz Ahmad](https://github.com/zoraiz53)
Contact ME on [LINKEDIN](https://www.linkedin.com/in/zoraiz-ahmad-89b402330/)
