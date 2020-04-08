## Global Metadata

variable "cluster_name" {
  type    = string
  default = "kubernetes-tomahawk"
}

variable "environment" {
  type    = string
  default = "development"
}

variable "cluster_cidr" {
  type    = string
  default = "10.200.0.0/16"
}

## Network

variable "vpc_cidr" {
  type    = string
  default = "180.60.0.0/21"
}

variable "prv_subnets_cidrs" {
  type = list
  default = [
    "180.60.3.0/24",
    "180.60.4.0/24",
    "180.60.5.0/24"
  ]
}

variable "prv_subnets_azs" {
  type = list
  default = [
    "eu-west-1a",
    "eu-west-1b",
    "eu-west-1c"
  ]
}

variable "pub_subnets_cidrs" {
  type = list
  default = [
    "180.60.1.0/24",
    "180.60.2.0/24"
  ]
}

variable "pub_subnets_azs" {
  type = list
  default = [
    "eu-west-1a",
    "eu-west-1b"
  ]
}
## Workers

variable "workers_tags" {
  type = map
  default = {
    Name        = "kube-workers-asg"
    Environment = "development"
  }
}

variable "kube_hostnames" {
  type = list
  default = [
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.svc.cluster.local"
  ]
}
