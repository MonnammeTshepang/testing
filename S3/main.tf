terraform {
  backend "s3" {
    bucket = "1st-bucket-for-testing"
    key = "Dev/terraform.tfstate"
    region     = "eu-central-1"
    dynamodb_table = "TerraformStateLockTable"
  }
}

resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name = "TerraformStateLockTable"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }
}

provider "aws" {
  region     = "eu-central-1"
  profile    = "AWSprofile1"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "1st-bucket-for-testing"

  tags = {
    Name        = "My bucket-1"
    Environment = "Dev"
  }
}
resource "aws_s3_bucket_acl" "bucket-acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

resource "aws_vpc" "my_vpc2" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "TEST VPC-1"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc2.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1c"

  tags = {
    Name = "production SUBNET"
  }
}