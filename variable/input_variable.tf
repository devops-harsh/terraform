variable "ami_id" {
  description = "this is ami id"
  type = string
  default = "ami-01a00762f46d584a1"
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}