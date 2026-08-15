provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "ec2_inst_1" {
  ami = var.ami_id
  instance_type = var.instance_type
}

