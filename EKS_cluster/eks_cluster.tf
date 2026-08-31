module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"
  name = local.cluster_name 

  kubernetes_version = "1.33"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets

  addons = {
    coredns                = {} // core dns is DNS serivce of kubernetes. it will allow pods comminication using the name or DNS resolution insted of IP.
    eks-pod-identity-agent = { // used for pod identity management with the iam role and serivce account of pod.
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = { // connect network interface used for connecting kubernetes pods to AWS VPC network. it will allows to pods to get IP address form VPC configuration.
      before_compute = true
    }
  }

// giving the cluster view policy through the access to the end user role
   access_entries = {
    developer = {
      principal_arn = aws_iam_role.cluster_access_role.arn

      policy_associations = {
        developer = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    example = { // it has the template for autoscaling group

      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.large"]

      min_size     = 2
      max_size     = 4
      desired_size = 2
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}