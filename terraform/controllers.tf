

# Module to create the Kubernetes Controllers and Network Load Balancer

module "controllers" {

  source = "./submodules/controllers"

  # Metadata
  cluster_name = var.cluster_name
  environment  = var.environment
  cluster_cidr = var.cluster_cidr

  # Controllers configuration
  controllers_type    = "t2.micro"
  svc_cluster_ip_cidr = "10.32.0.0/24"
  vpc_id              = module.network.vpc_id
  kube_hostnames      = var.kube_hostnames
  controllers_count   = length(module.network.private_subnets) % 2 != 1 ? length(module.network.private_subnets) - 1 : length(module.network.private_subnets) # Ensure odd numbers
  controllers_subnets = module.network.private_subnets
  controllers_cidrs   = var.prv_subnets_cidrs

  # Bastion host configuration
  bastion_count   = 1
  bastion_type    = "t2.micro"
  bastion_user    = "ec2-user"
  bastion_port    = 22
  bastion_subnets = module.network.public_subnets


  # Network LoadBalancer
  nlb_bucket        = "kube-controllers-nlb"
  nlb_bucket_prefix = "logs"
  nlb_name          = "kube-controllers-nlb"
  nlb_subnets       = module.network.public_subnets

  # Certificates
  ca_cert                 = module.init-ca.ca_cert
  ca_key                  = module.init-ca.ca_key
  admin_cert              = module.admin.cert
  admin_key               = module.admin.key
  controller_manager_cert = module.kube-controller-manager.cert
  controller_manager_key  = module.kube-controller-manager.key
  scheduler_cert          = module.kube-scheduler.cert
  scheduler_key           = module.kube-scheduler.key
  service_account_cert    = module.service-account.cert
  service_account_key     = module.service-account.key
  kube_cert               = module.kubernetes.cert
  kube_key                = module.kubernetes.key
}
