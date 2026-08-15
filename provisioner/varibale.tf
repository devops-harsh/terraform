variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
  description = "cidr block for the vpc"
}

variable "dev-subnet-cidr" {
  type = string
  default = "10.0.0.0/24"
  description = "cidr block for the subnet dev"
}