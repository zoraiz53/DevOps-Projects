resource "aws_instance" "backend_instance" {
  ami = "ami-020cba7c55df1f615" # Ubuntu AMI
  instance_type = "t2.micro"
  subnet_id = var.private_subnet_id
  vpc_security_group_ids = [var.backend_security_group_id]
  key_name = "<PRIVATE_KEY_FILENAME>"
  user_data = <<-EOF
#!/bin/bash
cat > /home/ubuntu/backend.sh <<'EOS'
#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y git
sudo git clone https://<GITHUB_USERNAME>:<GITHUB_TOKEN>@github.com/<GITHUB_USERNAME>/<REPO_NAME>.git
bash /<REPO_NAME>/application-code/deploy-backend.sh
EOS
  
sudo chmod +x /home/ubuntu/backend.sh
bash /home/ubuntu/backend.sh

# Create the backend update script
cat <<'EOS' > /home/ubuntu/backend-update.sh
#!/bin/bash

# Variables
REGION="<DEPLOYMENT_REGION>"
REPO_URI="<AWS_ACCOUNT_ID>.dkr.ecr.<DEPLOYMENT_REGION>.amazonaws.com/backend"
CONTAINER_NAME="backend-container"

# Authenticate Docker to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO_URI

# Get the latest image digest from ECR
LATEST_DIGEST=$(aws ecr describe-images \
    --repository-name backend \
    --region $REGION \
    --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageDigest' \
    --output text)

# Get the digest of currently running container image
CURRENT_IMAGE_ID=$(docker inspect --format='{{.Image}}' $CONTAINER_NAME 2>/dev/null)

# Get the digest of current image (if exists)
CURRENT_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' $CURRENT_IMAGE_ID 2>/dev/null | cut -d'@' -f2)

# Compare digests
if [ "$LATEST_DIGEST" != "$CURRENT_DIGEST" ]; then
    echo "New image detected. Updating container..."

    # Pull latest image
    sudo docker pull $${REPO_URI}@$${LATEST_DIGEST}

    # Stop and remove old container
    sudo docker stop $CONTAINER_NAME
    sudo docker rm $CONTAINER_NAME

    # Run new container (update with your custom run command if needed)
    sudo docker run -d --name $CONTAINER_NAME $${REPO_URI}@$${LATEST_DIGEST}

    # Remove old image if exists and is different
    if [ ! -z "$CURRENT_IMAGE_ID" ]; then
        sudo docker rmi $CURRENT_IMAGE_ID || true
    fi

    echo "Container updated successfully."
else
    echo "No updates found. Container is up to date."
fi
EOS

# Make the script executable
sudo chmod +x /home/ubuntu/backend-update.sh

# Set up cronjob to run every minute
( sudo crontab -l 2>/dev/null; echo "*/1 * * * * /home/ubuntu/backend-update.sh >> /var/log/backend-update.log 2>&1" ) | sudo crontab -

# Done
echo "User data script complete. Backend auto-update script is installed."
EOF

  tags = {
    Role = "backend"
  }
}

resource "aws_instance" "frontend_instance" {
  ami = "ami-020cba7c55df1f615" # Ubuntu AMI
  instance_type = "t2.micro"
  subnet_id = var.public_subnet_id
  vpc_security_group_ids = [var.frontend_security_group_id]
  key_name = "<PRIVATE_KEY_FILENAME>"
  associate_public_ip_address = true
  depends_on = [ aws_instance.backend_instance ]
  user_data = <<-EOF
#!/bin/bash
cat > /home/ubuntu/frontend.sh <<'EOS'
#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y git
sudo git clone https://<GITHUB_USERNAME>:<GITHUB_TOKEN>@github.com/<GITHUB_USERNAME>/<REPO_NAME>.git
bash /<REPO_NAME>/application-code/deploy-frontend.sh
EOS
  
sudo chmod +x /home/ubuntu/frontend.sh && bash /home/ubuntu/frontend.sh

# Create the frontend update script
cat <<'EOS' > /home/ubuntu/frontend-update.sh
#!/bin/bash

# Variables
REGION="<DEPLOYMENT_REGION>"
REPO_URI="<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/frontend"
CONTAINER_NAME="frontend-container"

# Authenticate Docker to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO_URI

# Get the latest image digest from ECR
LATEST_DIGEST=$(aws ecr describe-images \
    --repository-name frontend \
    --region $REGION \
    --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageDigest' \
    --output text)

# Get the digest of currently running container image
CURRENT_IMAGE_ID=$(docker inspect --format='{{.Image}}' $CONTAINER_NAME 2>/dev/null)

# Get the digest of current image (if exists)
CURRENT_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' $CURRENT_IMAGE_ID 2>/dev/null | cut -d'@' -f2)

# Compare digests
if [ "$LATEST_DIGEST" != "$CURRENT_DIGEST" ]; then
    echo "New frontend image detected. Updating container..."

    # Pull latest image
    sudo docker pull $${REPO_URI}@$${LATEST_DIGEST}

    # Stop and remove old container
    sudo docker stop $CONTAINER_NAME
    sudo docker rm $CONTAINER_NAME

    # Run new container (update with your custom run command if needed)
    sudo docker run -d --name $CONTAINER_NAME $${REPO_URI}@$${LATEST_DIGEST}

    # Remove old image if exists and is different
    if [ ! -z "$CURRENT_IMAGE_ID" ]; then
        sudo docker rmi $CURRENT_IMAGE_ID || true
    fi

    echo "Frontend container updated successfully."
else
    echo "No updates found for frontend. Container is up to date."
fi
EOS

# Make the script executable
sudo chmod +x /home/ubuntu/frontend-update.sh

# Set up cronjob to run every minute
( sudo crontab -l 2>/dev/null; echo "*/1 * * * * bash /home/ubuntu/frontend-update.sh >> /var/log/frontend-update.log 2>&1" ) | sudo crontab -

echo "User data for frontend setup complete."
EOF
}
