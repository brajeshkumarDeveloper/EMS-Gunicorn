# ----------------------------
# S3 Bucket and DynamoDB Table for Terraform State Locking
resource "aws_s3_bucket" "s3_bucket" {
  bucket= "employee-tf-s3-bucket"
  force_destroy = true
}

# ----------------------------
# DynamoDB Table for Terraform State Locking
resource "aws_dynamodb_table" "terraform-lock-employee-table" {
  name           = "terraform-lock-employees-table"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

}