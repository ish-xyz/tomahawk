

# Module to create the Kubernetes Controllers and Network Load Balancer

module "controllers" {

  source = "./submodules/kube-controllers"
  # Metadata
  cluster_name = var.cluster_name
  environment  = var.environment
  cluster_cidr = var.cluster_cidr

  # Controllers configuration
  svc_cluster_ip_cidr = "10.32.0.0/24"
  vpc_id              = "vpc-f670c791"
  kube_hostnames      = var.kube_hostnames
  controllers_count   = 3
  controllers_subnets = [
    "subnet-0059f167",
    "subnet-6c9a2b25",
    "subnet-e712e6bc"
  ]

  #Network LoadBalancer - 
  nlb_bucket        = "kube-controllers-nlb"
  nlb_bucket_prefix = "logs"
  nlb_name          = "kube-controllers-nlb"

  #Certificates
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
