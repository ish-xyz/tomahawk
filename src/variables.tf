## Global
variable "project_name" {
  type    = string
  default = "aws-k8s"
}

variable "vpc_id" {
  type    = string
  default = "vpc-f670c791"
}

variable "environment" {
  type    = string
  default = "development"
}

## Controllers instances
variable "controllers_count" {
  type    = number
  default = 3
}

variable "controllers_subnets" {
  type = list
  default = [
    "subnet-0059f167",
    "subnet-6c9a2b25",
    "subnet-e712e6bc"
  ]
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


variable "controllers_ami" {
  type    = string
  default = "ami-0334a7a72f69e4d0f"
}

## NLB

variable "nlb_bucket" {
  type    = string
  default = "kube-controllers-nlb"
}

variable "nlb_bucket_prefix" {
  type    = string
  default = "logs"
}

variable "nlb_name" {
  type    = string
  default = "kube-controllers-nlb"
}

## Workers

variable "workers_count" {
  type    = number
  default = 5
}

variable "workers_ami" {
  type    = string
  default = "ami-x"
}

variable "workers_subnet" {
  type    = string
  default = "ami-x"
}
