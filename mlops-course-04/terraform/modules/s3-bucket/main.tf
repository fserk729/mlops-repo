resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "s3" {
  bucket = "${var.bucket}-${random_id.suffix.hex}"
  tags   = var.tags
}
