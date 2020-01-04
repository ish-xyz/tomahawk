#Create Certificate Authority
module "init-ca" {
  source          = "ish-xyz/certificates-generator/tls"
  version         = "0.1.0"
  cn              = "Kubernetes"
  org             = "Kubernetes"
  ou              = "CA"
  country         = "United Kindgom"
  location        = "London"
  validity_period = 8760
}

#Generate certificates
module "admin" {
  source          = "ish-xyz/certificates-generator/tls"
  version         = "0.1.0"
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
  source          = "ish-xyz/certificates-generator/tls"
  version         = "0.1.0"
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
  source          = "ish-xyz/certificates-generator/tls"
  version         = "0.1.0"
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
  source          = "ish-xyz/certificates-generator/tls"
  version         = "0.1.0"
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
  source          = "ish-xyz/certificates-generator/tls"
  version         = "0.1.0"
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
  source          = "ish-xyz/certificates-generator/tls"
  version         = "0.1.0"
  cn              = "kubernetes"
  org             = "Kubernetes"
  ou              = var.cluster_name
  ca_cert         = module.init-ca.ca_cert
  ca_key          = module.init-ca.ca_key
  country         = "United Kindgom"
  location        = "London"
  dns_names       = concat(aws_instance.controllers.*.public_dns, [aws_lb.controllers.dns_name], var.kube_hostnames)
  ip_addresses    = concat(["10.32.0.1", "127.0.0.1"], aws_instance.controllers.*.private_ip, aws_instance.controllers.*.public_ip)
  validity_period = 8760
}
