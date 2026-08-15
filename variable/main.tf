provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "var-inst" {
  ami = var.ami_id
  instance_type = var.instance_type
}