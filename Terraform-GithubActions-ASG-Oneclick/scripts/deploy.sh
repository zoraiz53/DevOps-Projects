echo -e "make sure terraform is installed and AWS CLI is configured with proper creds, before deploying\n"
echo -e "Creating ECR Repository...\n"
aws ecr create-repository --repository-name ****** --region ******
ECR_URI=$(aws ecr describe-repositories --repository-names ****** --query "repositories[0].repositoryUri" --output text)

echo -e "Docker should also be installed and running\n"
echo -e "Building dokcer Image...\n"
cd ../app
docker build -t atp-img:latest .


echo -e "Pushing docker Image\n"
aws ecr get-login-password --region ****** | docker login --username AWS --password-stdin $ECR_URI
sudo docker tag atp-img:latest ******.dkr.ecr.******.amazonaws.com/******:latest
docker push ******.dkr.ecr.******.amazonaws.com/******:latest


cd ../terraform

echo -e "\nInititializing Terraform...\n"
terraform init

echo -e "\nPlanning Terraform Configuration...\n"
terraform plan --auto-approve

echo -e "\nApplying Terraform Configuration...\n"
terraform apply --auto-approve

