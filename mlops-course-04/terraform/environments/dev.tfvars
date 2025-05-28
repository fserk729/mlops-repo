environment = "dev"
aws_region  = "eu-west-1"


s3_buckets = [
  {
    key  = "mlops-course-ehb-data"
    tags = {}
  }
]

ecr_repositories = [
  {
    key                  = "mlops-course-ehb-repository"
    image_tag_mutability = "MUTABLE"
    image_scanning_configuration = {
      scan_on_push = true
    }
    tags = {}
  }
]
