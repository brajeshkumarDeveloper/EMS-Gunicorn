# ----------------------------
# Security Group
# ----------------------------
resource "aws_security_group" "emp_sg" {
  name        = "employee-sg"
  description = "Allow SSH, HTTP, Employee Management System ports"

  # If you have a VPC, attach it:
  # vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Employee Management System"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Employee-Management-System-SG"
  }
}

# ----------------------------
# EC2 Instance
# ----------------------------
resource "aws_instance" "emp_ec2" {
  ami           = "ami-0b6c6ebed2801a5cb"  # replace with your region's AMI
  instance_type = var.instance_type
  key_name      = "web-api"  # make sure this key exists in AWS

  vpc_security_group_ids = [
    aws_security_group.emp_sg.id
  ]

  tags = {
    Name = "Employee-Management-System-WebServer"
  }
}

# ----------------------------
# Elastic IP
# ----------------------------
resource "aws_eip" "emp_eip" {
  instance = aws_instance.emp_ec2.id

  tags = {
    Name = "Employee-Management-System-EIP"
  }
}

# ----------------------------
# Output: Public IP
# ----------------------------
output "ec2_public_ip" {
  value = aws_eip.emp_eip.public_ip
}

# ----------------------------
# S3 Bucket and DynamoDB Table for Terraform State Locking
# resource "aws_s3_bucket" "s3_bucket" {
#   bucket= "employee-tf-s3-bucket"
# }

# ----------------------------
# DynamoDB Table for Terraform State Locking
# resource "aws_dynamodb_table" "terraform-lock-employee-table" {
#   name           = "terraform-lock-employees-table"
#   billing_mode     = "PAY_PER_REQUEST"
#   hash_key       = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }

# }