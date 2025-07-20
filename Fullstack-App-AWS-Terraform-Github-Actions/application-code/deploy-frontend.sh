#!/bin/bash
echo ":art: Deploying Frontend to EC2"
echo "============================"

# Configuration
FRONTEND_PORT=3000
DOCKER_IMAGE_NAME="<AWS_ACCOUNT_ID>.dkr.ecr.<DEPLOYMENT_REGION>.amazonaws.com/frontend"
CONTAINER_NAME="frontend-container"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_blue() {
    echo -e "${BLUE}[INPUT]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Installing Docker..."
    
    # Update package list
    sudo apt-get update
    
    # Install prerequisites
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    print_warning "Docker installed. You may need to log out and back in for group changes to take effect."
fi

# Check if Docker is running
if ! sudo docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Starting Docker..."
    sudo systemctl start docker
    sudo systemctl enable docker
fi


# Installing AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❗ AWS CLI is not installed. Installing AWS CLI..."

     sudo apt-get update -y
     sudo apt-get install -y unzip curl
     curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
     unzip awscliv2.zip
     sudo ./aws/install

    echo "✅ AWS CLI installation completed."
else
    echo "✅ AWS CLI is already installed."
fi

# Configuring AWS
aws configure set <AWS_ACCESS_KEY>
aws configure set <AWS_SECRET_ACCESS_KEY>
aws configure set <DEPLOYMENT_REGION>
aws configure set json

#Getting Backend instance's Private IP
BACKEND_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Role,Values=backend" \
  --query "Reservations[*].Instances[*].PrivateIpAddress" \
  --output text \
  --region <DEPLOYMENT_REGION>)

BACKEND_URL="http://$BACKEND_IP:5000"
print_status "Detected backend URL: $BACKEND_URL"

# Test backend connectivity
print_status "Testing backend connectivity..."
if curl -f "$BACKEND_URL/api/health" > /dev/null 2>&1; then
    print_status ":white_check_mark: Backend is accessible"
else
    print_warning ":warning:  Backend is not accessible. Make sure:"
    print_warning "   - Backend EC2 is running"
    print_warning "   - Security group allows inbound traffic on port 5000"
    print_warning "   - Backend URL is correct"
fi

# Stop and remove existing container if it exists
if sudo docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_status "Stopping existing container..."
    sudo docker stop $CONTAINER_NAME
    sudo docker rm $CONTAINER_NAME
fi

# Remove existing image if it exists
if sudo docker images --format 'table {{.Repository}}' | grep -q "^${DOCKER_IMAGE_NAME}$"; then
    print_status "Removing existing image..."
    sudo docker rmi $DOCKER_IMAGE_NAME
fi

# Login to AWS ECR
aws ecr get-login-password --region <DEPLOYMENT_REGION> | \
sudo docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.<DEPLOYMENT_REGION>.amazonaws.com

# Pull the Docker image
sudo docker pull <AWS_ACCOUNT_ID>.dkr.ecr.<DEPLOYMENT_REGION>.amazonaws.com/frontend

# Run the container
print_status "Starting frontend container..."
sudo docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p $FRONTEND_PORT:$FRONTEND_PORT \
    -e BACKEND_URL="$BACKEND_URL" \
    -e FLASK_ENV=production \
    $DOCKER_IMAGE_NAME

if [ $? -ne 0 ]; then
    print_error "Failed to start container"
    exit 1
fi

# Wait a moment for the container to start
sleep 5

# Check if container is running
if sudo docker ps --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_status ":white_check_mark: Frontend deployed successfully!"
    print_status "Container name: $CONTAINER_NAME"
    print_status "Port: $FRONTEND_PORT"

    # Get the public IP
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")
    print_status "Frontend URL: http://$PUBLIC_IP:$FRONTEND_PORT"

    # Test the frontend
    print_status "Testing frontend..."
    sleep 3
    if curl -f http://localhost:$FRONTEND_PORT/health > /dev/null 2>&1; then
        print_status ":white_check_mark: Frontend is responding correctly"
    else
        print_warning ":warning:  Frontend test failed, but container is running"
    fi

else
    print_error ":x: Container failed to start"
    sudo docker logs $CONTAINER_NAME
    exit 1
fi

echo ""
print_status "Frontend deployment complete!"
print_status "Make sure to:"
print_status "1. Configure your EC2 security group to allow inbound traffic on port $FRONTEND_PORT"
print_status "2. Access your application at: http://$PUBLIC_IP:$FRONTEND_PORT"
print_status "3. Backend URL configured as: $BACKEND_URL"

# Show current configuration
echo ""
print_status "Current configuration:"
sudo docker exec $CONTAINER_NAME python -c "
import os
print('Backend URL:', os.environ.get('BACKEND_URL', 'Not set'))
print('Frontend Port:', os.environ.get('PORT', '3000'))"