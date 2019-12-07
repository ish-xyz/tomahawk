#
module "init-ca" {
  source          = "./certificates-generator"
  cn              = "CA"
  org             = "aws-k8s-lab-init-CA"
  ou              = "aws-k8s-lab"
  country         = "United Kindgom"
  location        = "London"
  validity_period = 8760
}

module "admin" {
  source          = "./certificates-generator"
  cn              = "admin"
  org             = "system:masters"
  ou              = "aws-k8s-lab"
  ca_cert         = module.init-ca.ca_cert
  ca_key          = module.init-ca.ca_key
  country         = "United Kindgom"
  location        = "London"
  validity_period = 8760
}

module "kube-controller-manager" {
  source          = "./certificates-generator"
  cn              = "system:kube-controller-manager"
  org             = "system:kube-controller-manager"
  ou              = "aws-k8s-lab"
  ca_cert         = module.init-ca.ca_cert
  ca_key          = module.init-ca.ca_key
  country         = "United Kindgom"
  location        = "London"
  validity_period = 8760
}

module "kube-proxy" {
  source          = "./certificates-generator"
  cn              = "system:kube-proxy"
  org             = "system:kube-proxy"
  ou              = "aws-k8s-lab"
  ca_cert         = module.init-ca.ca_cert
  ca_key          = module.init-ca.ca_key
  country         = "United Kindgom"
  location        = "London"
  validity_period = 8760
}

module "kube-scheduler" {
  source          = "./certificates-generator"
  cn              = "system:kube-scheduler"
  org             = "system:kube-scheduler"
  ou              = "aws-k8s-lab"
  ca_cert         = module.init-ca.ca_cert
  ca_key          = module.init-ca.ca_key
  country         = "United Kindgom"
  location        = "London"
  validity_period = 8760
}

module "service-accounts" {
  source          = "./certificates-generator"
  cn              = "service-accounts"
  org             = "Kubernetes"
  ou              = "aws-k8s-lab"
  ca_cert         = module.init-ca.ca_cert
  ca_key          = module.init-ca.ca_key
  country         = "United Kindgom"
  location        = "London"
  validity_period = 8760
}

module "kubernetes" {
  source          = "./certificates-generator"
  cn              = "Kubernetes"
  org             = "Kubernetes"
  ou              = "aws-k8s-lab"
  ca_cert         = module.init-ca.ca_cert
  ca_key          = module.init-ca.ca_key
  country         = "United Kindgom"
  location        = "London"
  dns_names       = aws_instance.controllers.*.public_dns
  ip_addresses    = concat(["10.32.0.1", "127.0.0.1"], aws_instance.controllers.*.private_ip, aws_instance.controllers.*.public_ip)
  validity_period = 8760
}
