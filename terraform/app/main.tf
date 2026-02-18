# ----------------------------
# Security Group
# ----------------------------
resource "aws_security_group" "emp_sg" {
  name        = "employee-sg"
  description = "Allow SSH, HTTP, Employee Management System ports"

  # If you have a VPC, attach it:
  vpc_id = aws_vpc.my_vpc.id

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
  associate_public_ip_address = true
  subnet_id = aws_subnet.public_subnet.id


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



# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  tags = {
    Name = "my_vpc"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.my_vpc.id
  tags = {
    Name = "private_subnet"
  }

}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.my_vpc.id
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet"
  }

}

# Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my_igw"
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.my_igw.id
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
