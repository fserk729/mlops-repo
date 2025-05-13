# AWS Infrastructure Setup with Terraform and GitHub Actions 

This guide provides a complete workflow for deploying AWS infrastructure using Terraform, automated through GitHub Actions. It's ideal for infrastructure-as-code (IaC) projects with continuous integration and delivery (CI/CD) needs.

## Prerequisites

* [Terraform](https://developer.hashicorp.com/terraform/downloads)
* AWS CLI configured (`aws configure`)
* Access Key under root account
* GitHub repository

## 1. Environment Variables
```bash
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
```

## 2. Project Structure
```
mlops-course-02  
├── docs/  
├── src/  
├── terraform/  
│   ├── backends/  
│   │   ├── dev.conf  
│   │   ├── prd.conf  
│   │   ├── sandbox.conf  
│   │   └── tst.conf  
│   ├── environments/  
│   │   ├── dev.tfvars  
│   │   ├── prd.tfvars  
│   │   ├── sandbox.tfvars  
│   │   └── tst.tfvars  
│   ├── modules/  
│   │   └── s3-bucket/  
│   │       ├── locals.tf  
│   │       ├── main.tf  
│   │       ├── outputs.tf  
│   │       └── variables.tf  
│   ├── provider.tf  
│   ├── s3_buckets.tf  
│   └── variables.tf  
├── README.md
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
  
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
```

`backends/{env}.conf`
```terraform
bucket  = "terraform-backends-ehb"
key     = "{project}-{env}.tfstate"
region  = "eu-north-1"
```

`variables.tf`
```hcl
variable "aws_region" {
  description = "AWS region"
  default     = "eu-north-1"
}

variable "environment" {
  description = "Specifies the deployment environment of the resources (e.g., sandbox, dev, tst, acc, prd)"
  type        = string
  default     = "sandbox"
}

variable "delimiter" {
  description = "Resource name delimiter"
  type        = string
  default     = "-"
}

variable "s3_buckets" {
  description = "A list of S3 Buckets"
  type        = list(any)
  default     = []
}
```

`s3_buckets.tf`
```hcl
module "s3_bucket" {
  for_each = { for s3 in var.s3_buckets : s3.key => s3 }
  source   = "./modules/s3-bucket"

  bucket = join(var.delimiter, [each.value.key, var.environment])
  tags   = merge(try(each.value.tags, {}), { environment = var.environment })
}
```

`environments/{env}.tfvars`
```hcl
environment = "sandbox"
location    = "eu-north-1"


s3 = [
  {
    key  = "mlops-course-ehb-data"
    tags = {}
  }
]
```

### 4. Apply Terraform Configuration using Terraform CLI
```bash
terraform validate
terraform fmt --recursive
terraform init --backend-config='backends/{env}.conf'
terraform plan --var-file='environments/{env}.tfvars' 
terraform apply --var-file='environments/{env}.tfvars'
terraform destroy --var-file='environments/{env}.tfvars'
```
