variable "ami_id" {
  type = string
  default = "ami-01a00762f46d584a1"
  description = "this is ami id for the ec2 instance"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
  description = "this is instance type for ec2 instance"
}
