provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available"{ // its gives the information of the existing data. here it gives me aviability zone in the current using region.

}

resource "random_string" "eks-suffix-name" { //random string 
  length = 4
  special = false //use of special charatcter is true or not 
}

locals { // local variable that we can use through out the terraform configuration. if we don't want to give use access to specify the things and use locally
  cluster_name = "eks-${random_string.eks-suffix-name.result}"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0,2) //["ap-south-1a", "ap-south-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
 
  enable_nat_gateway = true
  single_nat_gateway = true // crete only 1 NAT gateway for the VPC
  enable_dns_hostnames = true //helps to resolve dns. recieve the DNS from the aws
  enable_dns_support= true // enables dns support inside the vpc

  tags = {  // this will add the tag to the VPC 
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

// when we create the ALB it will specify the ALB subnets using the below configuration automatically. we dont need specify the subnet with the ALB.
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared" // tag is used to identify that subnet is associated with the EKS cluster
    "kubernetes.io/role/elb" = "1" // it will specifying that consider this subnet for the Elastic load balancers
  }

  private_subnet_tags = {
     "kubernetes.io/cluster/${local.cluster_name}" = "shared" // associate the private subnet with the EKS cluster
     "kubernetes.io//role/internal-elb" = "1" // this is private subnet and consider this subnet for interanl facing load balancer
  }
}