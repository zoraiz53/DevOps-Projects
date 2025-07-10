#!/bin/bash

echo "🚀 Deploying Backend to EC2"
echo "============================"

# Configuration
BACKEND_PORT=5000
DOCKER_IMAGE_NAME="<AWS_ACCOUNT_ID>.dkr.ecr.<DEPLOYMENT_REGION>.amazonaws.com/backend"
CONTAINER_NAME="backend-container"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Starting Docker..."
    sudo systemctl start docker
    sudo systemctl enable docker
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
aws configure set aws_access_key_id <AWS_ACCESS_KEY>
aws configure set aws_secret_access_key <AWS_SECRET_ACCESS_KEY>
aws configure set default.region <DEPLOYMENT_REGION>
aws configure set output json

# Login to AWS ECR
aws ecr get-login-password --region <DEPLOYMENT_REGION> | \
sudo docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.<DEPLOYMENT_REGION>.amazonaws.com

# Pull the Docker image
sudo docker pull <AWS_ACCOUNT_ID>.dkr.ecr.<DEPLOYMENT_REGION>.amazonaws.com/backend
 
# Run the container
print_status "Starting backend container..."
sudo docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p $BACKEND_PORT:$BACKEND_PORT \
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
    print_status "✅ Backend deployed successfully!"
    print_status "Container name: $CONTAINER_NAME"
    print_status "Port: $BACKEND_PORT"
    
    # Get the public IP
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")
    print_status "Backend URL: http://$PUBLIC_IP:$BACKEND_PORT"
    
    # Test the API
    print_status "Testing API..."
    sleep 3
    if curl -f http://localhost:$BACKEND_PORT/api/health > /dev/null 2>&1; then
        print_status "✅ API is responding correctly"
    else
        print_warning "⚠️  API test failed, but container is running"
    fi
    
else
    print_error "❌ Container failed to start"
    sudo docker logs $CONTAINER_NAME
    exit 1
fi

echo ""
print_status "Backend deployment complete!"
print_status "Make sure to:"
print_status "1. Configure your EC2 security group to allow inbound traffic on port $BACKEND_PORT"
print_status "2. Update your frontend's BACKEND_URL environment variable to: http://$PUBLIC_IP:$BACKEND_PORT" 