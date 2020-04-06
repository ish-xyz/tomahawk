provider "aws" {
  version = "~> 2.54.0"
  region  = "eu-west-1"
}

provider "helm" {
  kubernetes {
    host     = "https://${aws_lb.controllers.dns_name}:6443"
    username = "admin"

    client_certificate     = module.admin.cert
    client_key             = module.admin.key
    cluster_ca_certificate = module.init-ca.ca_cert
  }
}