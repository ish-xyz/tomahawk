## Global
variable "cluster_name" {
  type    = string
  default = "kubernetes-on-aws"
}

variable "environment" {
  type    = string
  default = "development"
}

variable "cluster_cidr" {
  type    = string
  default = "10.200.0.0/16"
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