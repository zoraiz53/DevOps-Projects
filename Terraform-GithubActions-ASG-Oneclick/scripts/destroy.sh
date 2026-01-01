echo -e "Are you sure you want to destroy all the resources? (yes/no)"
read confirmation
if [ "$confirmation" == "yes" ]; then
  cd ../terraform
  terraform init
  terraform destroy --auto-approve
  echo -e "\nAlso destroying ECR Repo\n"
  aws ecr delete-repository --repository-name ****** --region ****** --force

else
  echo -e "Aborting destruction of resources."
fi