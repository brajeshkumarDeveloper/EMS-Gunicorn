# # Configure the Terraform backend to use Amazon S3 for storing the state file and DynamoDB for state locking.
terraform {
  backend "s3" {
    bucket         = "employee-tf-s3-bucket"
    key            = "employee/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-employees-table"
  }
}
