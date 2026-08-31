output "cluster-id" {
  value = module.eks.cluster_id
}

output "cluster_endpoint" {
  value= module.eks.cluster_endpoint
}

output "region" {
   value= var.aws_region
}

# output "oidc" {
#   value = module.eks.oidc_provider.id
# }