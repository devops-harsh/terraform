terraform {
    backend "s3"{
      bucket = "vpc.proj.backend.state.com"
      key = "terraform/backend/terraform.tfstate"
      encrypt = true
      region =  "ap-south-1"
      use_lockfile = true
    } 
}