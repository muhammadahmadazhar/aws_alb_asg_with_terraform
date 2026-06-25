#!/bin/bash

PROFILE="hsw"
PROJECT="my-terraform-1"
ENV="test"
REGION="us-east-2"

# =========================
# DB USERNAME
# =========================
aws ssm put-parameter \
  --region $REGION \
  --name "/$PROJECT/$ENV/db/username" \
  --value "postgres" \
  --type "String" \
  --overwrite \
  --profile $PROFILE

# =========================
# DB PASSWORD
# =========================
aws ssm put-parameter \
  --region $REGION \
  --name "/$PROJECT/$ENV/db/password" \
  --value "postgres" \
  --type "SecureString" \
  --overwrite \
  --profile $PROFILE

echo "SSM parameters created successfully ✅"