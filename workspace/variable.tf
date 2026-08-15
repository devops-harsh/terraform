variable "ami_id" {
    description = "value"
#   type = string 
#   default = "ami-01a00762f46d584a1"

}

variable "instance_type" {
    description = "value"

    type = map(string)
    default = {
      "dev" = "t2.micro" // if workspace is dev the instace type is this
      "stage" = "t2.medium" 
      "prod" = "t3.xlarge"
    }
#   type = string
#   default = "t2.micro"
}