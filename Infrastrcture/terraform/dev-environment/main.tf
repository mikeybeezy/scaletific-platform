terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.50.0"
    }
  }
}

# provider "aws" {
#   # Configuration options
# }

provider "aws" {
  region                   = "eu-west-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "scaletfic-lab"
}


### VPC ###

resource "aws_vpc" "main_dev_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags = {
    Name = "main Dev VPC"
  }
}

### IGW ###

resource "aws_internet_gateway" "main_dev_igw" {
  vpc_id = aws_vpc.main_dev_vpc.id

  tags = {
    Name = "Main Dev Internet gateway"
  }
}

### main subnet  ###
resource "aws_subnet" "main_dev_public_subnet" {
  vpc_id                  = aws_vpc.main_dev_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1a"

  tags = {
    Name = "Main Dev subnet "
  }
}


resource "aws_route_table" "main_dev_roue_table" {
  vpc_id = aws_vpc.main_dev_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_dev_igw.id
  }


  tags = {
    Name = "Main "
  }
}

### Security Groups ###
resource "aws_security_group" "main_dev_security_group" {
  name        = "main_dev_sg"
  description = "main_dev_security_group"
  vpc_id      = aws_vpc.main_dev_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




### Datasource  ####


data "aws_ami" "example" {
  executable_users = ["self"]
  most_recent      = true
  name_regex       = "^myami-\\d{3}"
  owners           = ["self"]

  filter {
    name   = "name"
    values = ["myami-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
