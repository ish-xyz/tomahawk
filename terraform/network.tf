

# Module to create the Kubernetes Controllers and Network Load Balancer

module "network" {

  source = "./submodules/network"

  environment = var.environment
  vpc_name    = var.cluster_name
  vpc_cidr    = var.vpc_cidr

  pub_subnets_cidr = var.pub_subnets_cidrs
  pub_subnets_azs  = var.pub_subnets_azs
  prv_subnets_cidr = var.prv_subnets_cidrs
  prv_subnets_azs  = var.prv_subnets_azs
}
