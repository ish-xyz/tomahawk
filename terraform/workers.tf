# Module to create an ASG for workers and deploy the init script within them.

module "workers" {
  source = "./submodules/workers"

  # Metadata
  cluster_name = var.cluster_name
  environment  = var.environment
  cluster_cidr = var.cluster_cidr

  # Certificates
  ca_cert         = module.init-ca.ca_cert
  ca_key          = module.init-ca.ca_key
  kube_proxy_cert = module.kube-proxy.cert
  kube_proxy_key  = module.kube-proxy.key

  # Workers Configuration
  workers_vpc_id         = module.network.vpc_id
  workers_min            = 2
  workers_max            = 6
  workers_count          = 4
  workers_tags           = var.workers_tags
  workers_type           = "t2.large"
  workers_subnets        = module.network.private_subnets
  dns_address            = "10.32.0.10"
  controllers_lb_address = module.controllers.kube_address
}
