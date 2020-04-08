# Create Certificate Authority
module "init-ca" {
  source          = "./submodules/tls-certificates-generator"
  cn              = "Kubernetes"
  org             = "Kubernetes"
  ou              = "CA"
  country         = "United Kindgom"
  location        = "London"
  validity_period = 8760
}

# Generate certificates
module "admin" {
  source          = "./submodules/tls-certificates-generator"
  cn              = "admin"
  org             = "system:masters"
  ou              = var.cluster_name
  ca_cert         = module.init-ca.ca_cert
  ca_key          = module.init-ca.ca_key
  country         = "United Kindgom"
  location        = "London"
  validity_period = 8760
}

module "kube-controller-manager" {
  source          = "./submodules/tls-certificates-generator"
  cn              = "system:kube-controller-manager"
  org             = "system:kube-controller-manager"
  ou              = var.cluster_name
  ca_cert         = module.init-ca.ca_cert
  ca_key          = module.init-ca.ca_key
  country         = "United Kindgom"
  location        = "London"
  validity_period = 8760
}

module "kube-proxy" {
  source          = "./submodules/tls-certificates-generator"
  cn              = "system:kube-proxy"
  org             = "system:node-proxier"
  ou              = var.cluster_name
  ca_cert         = module.init-ca.ca_cert
  ca_key          = module.init-ca.ca_key
  country         = "United Kindgom"
  location        = "London"
  validity_period = 8760
}

module "kube-scheduler" {
  source          = "./submodules/tls-certificates-generator"
  cn              = "system:kube-scheduler"
  org             = "system:kube-scheduler"
  ou              = var.cluster_name
  ca_cert         = module.init-ca.ca_cert
  ca_key          = module.init-ca.ca_key
  country         = "United Kindgom"
  location        = "London"
  validity_period = 8760
}

module "service-account" {
  source          = "./submodules/tls-certificates-generator"
  cn              = "service-accounts"
  org             = "Kubernetes"
  ou              = var.cluster_name
  ca_cert         = module.init-ca.ca_cert
  ca_key          = module.init-ca.ca_key
  country         = "United Kindgom"
  location        = "London"
  validity_period = 8760
}

module "kubernetes" {
  source          = "./submodules/tls-certificates-generator"
  cn              = "kubernetes"
  org             = "Kubernetes"
  ou              = var.cluster_name
  ca_cert         = module.init-ca.ca_cert
  ca_key          = module.init-ca.ca_key
  country         = "United Kindgom"
  location        = "London"
  dns_names       = concat([module.controllers.lb_dns_name], var.kube_hostnames)
  ip_addresses    = concat(["10.32.0.1", "127.0.0.1"], module.controllers.private_ips)
  validity_period = 8760
}
