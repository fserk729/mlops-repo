#!/bin/bash

#function to check exit status and sisplay an error message if it failed
check_exit_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Specify the username for the new IAM user
USER_NAME="terraform_user-$RANDOM"

# Create IAM User and capture the response
USER_RESPONSE=$(aws iam create-user --user-name "$USER_NAME")
check_exit_status "Failed to create IAM user"

# Extract user ARN from the response
USER_ARN=$(echo "$USER_RESPONSE" | jq -r '.User.Arn')
                                        
# Attach Admin Access Policy to IAM User
aws iam attach-user-policy --user-name "$USER_NAME" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
check_exit_status "Failed to attach AdministratorAccess policy to IAM user"

# Create Access and Secret Access Keys
CREDS_JSON=$(aws iam create-access-key --user-name "$USER_NAME")
check_exit_status "Failed to create access and secret access key for IAM user"

# Extract access key ID and secret access key
ACCESS_KEY=$(echo "$CREDS_JSON" | jq -r '.AccessKey.AccessKeyId')
SECRET_KEY=$(echo "$CREDS_JSON" | jq -r '.AccessKey.SecretAccessKey')

# Create text file to export keys
echo "Access Key: $ACCESS_KEY" >> terraform_user_accessKeys.txt
echo "Secret Access Key: $SECRET_KEY" >> terraform_user_accessKeys.txt                                     

# Create S3 Bucket
S3_BUCKET_NAME="tf-remote-backend-ehb-$RANDOM"
aws s3 mb "s3://$S3_BUCKET_NAME" --region "eu-north-1"
check_exit_status "Failed to create S3 bucket"

# Enable Versioning for S3 Bucket
aws s3api put-bucket-versioning --bucket "$S3_BUCKET_NAME" --versioning-configuration Status=Enabled
check_exit_status "Failed to enable versioning for S3 bucket"

# Create DynamoDB Table
aws dynamodb create-table \
    --table-name tf-lock-table-ehb-$RANDOM \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region "eu-north-1"
check_exit_status "Failed to create DynamoDB table"

# Apply the sed command to a JSON file
sed -e "s/RESOURCE/arn:aws:s3:::$S3_BUCKET_NAME/g" \
    -e "s/KEY/terraform.tfstat/g" \
    -e "s|ARN|$USER_ARN|g" "$(dirname "$0")/s3-policy.json" > new-policy.json
check_exit_status "Failed to execute the 'sed' command on s3-policy.json"
aws s3api put-bucket-policy --bucket "$S3_BUCKET_NAME" --policy file://new-policy.json
check_exit_status "Failed to apply bucket policy to S3 bucket"
rm new-policy.json

# Echo a confirmation message
echo "IAM user created successfully. Usename: $USER_NAME"
echo "S3 Bucket created successfully. Name: $S3_BUCKET_NAME (Versioning Enabled)"
echo "Access and Secret Access Keys have been saved to terraform_user_accessKeys.txt"