#!/bin/bash
echo -e "\n###### Before Testing #######\nMake sure you have AWS cli Installed and Configured the Right AWS Credentials\n\n"

endpoint = $(aws elbv2 describe-load-balancers --region ****** --query 'LoadBalancers[*].DNSName' --output text)
curl http://$endpoint/health
if [ $? -eq 0 ]; then
  echo -e "\n###### Test Passed #######\n"
else
  echo -e "\n###### Test Failed #######\n"
fi