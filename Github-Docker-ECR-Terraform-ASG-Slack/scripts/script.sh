#!/bin/bash

echo ":broom: Deleting old Launch Template versions..."
LAUNCH_TEMPLATE_ID="lt-0e3121a72512146bd"
REGION="us-east-1"

ALL_VERSIONS=$(aws ec2 describe-launch-template-versions \
  --launch-template-id $LAUNCH_TEMPLATE_ID \
  --region $REGION \
  --query 'LaunchTemplateVersions[].VersionNumber' \
  --output text | tr '\t' '\n' | sort -n)

LATEST_TWO=$(echo "$ALL_VERSIONS" | tail -n 2)

DEFAULT_VERSION=$(aws ec2 describe-launch-templates \
  --launch-template-ids $LAUNCH_TEMPLATE_ID \
  --region $REGION \
  --query 'LaunchTemplates[].DefaultVersionNumber' \
  --output text)

EXCLUDE=$(echo -e "$LATEST_TWO\n$DEFAULT_VERSION" | sort -n | uniq)

comm -23 <(echo "$ALL_VERSIONS") <(echo "$EXCLUDE") | while read VERSION; do
  if [ -n "$VERSION" ]; then
    echo ":wastebasket: Deleting version $VERSION"
    aws ec2 delete-launch-template-versions \
      --launch-template-id $LAUNCH_TEMPLATE_ID \
      --versions $VERSION \
      --region $REGION
  fi
done

echo ":white_check_mark: Cleanup complete."

