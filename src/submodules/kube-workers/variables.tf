# Input variables

variable "ca_cert" {
  type = string
}

variable "ca_key" {
  type = string
}

variable "kube_proxy_cert" {
  type = string
}

variable "kube_proxy_key" {
  type = string
}

variable "cluster_name" {
  description = "The name of the cluster - needs to be the same used fo controllers"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g.: development, production, staging) - needs to be the same used fo controllers"
  type        = string
}

variable "cluster_cidr" {
  description = "CIDR Range for Pods in cluster - needs to be the same used fo controllers"
  type        = string
}

variable "workers_vpc_id" {
  description = "VPC where the AutoScalingGroup will be deployed"
  type        = string
}

variable "workers_min" {
  description = "Minimum amount of workers"
  type        = number
}

variable "workers_max" {
  description = "Maximum amount of workers"
  type        = number
}

variable "workers_count" {
  description = "Desired amount of workers"
  type        = number
}

variable "workers_ami" {
  description = "AMI used to deploy the workers - Currently only one AMI is supported"
  type        = string
  default     = "ami-0334a7a72f69e4d0f"
}

variable "workers_tags" {
  description = "AWS tags to allocate on workers."
  type        = map
}

variable "workers_type" {
  description = "Instance type to use when workers are provisioned"
  type        = string
}

variable "dns_address" {
  description = "ClusterDNS address used to configure the Kubelet."
  type        = string
}

variable "controllers_lb_address" {
  description = "Controllers LB address - needs to be an FQDN {protocol}://{lb}:{port}"
  type        = string
}