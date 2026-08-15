resource "aws_instance" "example_inst" {
  instance_type = "t2.micro"
  provider = aws.ap-south-a
}

resource "aws_instance" "example_inst-2" {
  instance_type = "t2.micro"
  provider = aws.us-east-a
}