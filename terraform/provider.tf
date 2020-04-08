provider "aws" {
  version = "~> 2.54.0"
  region  = "eu-west-1"
}

provider "helm" {
  kubernetes {
    host     = module.controllers.kube_address
    username = "admin"

    client_certificate     = module.admin.cert
    client_key             = module.admin.key
    cluster_ca_certificate = module.init-ca.ca_cert
  }
}