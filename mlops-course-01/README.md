# AWS Infrastructure Setup with Terraform for Local Development

This guide walks through setting up basic AWS infrastructure using Terraform. It assumes you have Terraform installed and an AWS account.

## Prerequisites

* [Terraform](https://developer.hashicorp.com/terraform/downloads)
* AWS CLI configured (`aws configure`)
* Access Key under root account

## 1. Environment Variables
```bash
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
```

## 2. Project Structure
```
mlops-course-01/
├── terraform/
│   ├── provider.tf
│   ├── s3.tf
├── src/
├── docs/
└── README.md
```

## 3. Terraform Configuration
`provider.tf`
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.97"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}
```

`s3.tf`
```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-tf-test-d9237282392372dsdsd8"
}
```

### 4. Apply Terraform Configuration using Terraform CLI
```bash
terraform validate
terraform fmt --recursive
terraform init
terraform plan
terraform apply
terraform destroy
```
