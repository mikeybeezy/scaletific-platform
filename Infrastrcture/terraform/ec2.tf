terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.50.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "eu-west-1"
}





resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "HelloWorld"
  }
}
