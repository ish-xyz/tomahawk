# Input variables 

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

## Controllers instances

variable "svc_cluster_ip_cidr" {
  description = "CIDR reserved for Kubernetes services"
  type        = string
}

variable "vpc_id" {
  description = "AWS vpc ID for Kubernetes controllers instances"
  type        = string
}

variable "controllers_count" {
  description = "The desired amount of Kubernetes controllers"
  type        = number
  default     = 3
}

variable "controllers_subnets" {
  description = "List of Subnet ID - best to use a different subnet/AZ per controller"
  type        = list
}

variable "kube_hostnames" {
  description = "List of the internal Kubernetes hostnames"
  type        = list
}

## NLB

variable "nlb_bucket" {
  description = "Bucket used to store the load balancer logs"
  type        = string
  default     = "kube-controllers-nlb"
}

variable "nlb_bucket_prefix" {
  description = "Network LoadBalancer bucket prefix"
  type        = string
}

variable "nlb_name" {
  description = "Network LoadBalancer name"
  type        = string
}

variable "ca_cert" {
  description = "The Certificate Authority's certificate"
  type        = string
}

variable "ca_key" {
  description = "The Certificate Authority's key"
  type        = string
}

variable "admin_cert" {
  description = "TLS Certificate for the Kubernetes admin user"
  type        = string
}

variable "admin_key" {
  description = "TLS Key for the Kubernetes admin user"
  type        = string
}

variable "controller_manager_cert" {
  description = "TLS certificate for the Kubernetes controller manager"
  type        = string
}

variable "controller_manager_key" {
  description = "TLS Key for the for the Kubernetes controller manager"
  type        = string
}

variable "scheduler_cert" {
  description = "TLS certificate for the Kubernetes scheduler"
  type        = string
}

variable "scheduler_key" {
  description = "TLS key for the Kubernetes scheduler"
  type        = string
}

variable "service_account_cert" {
  description = "TLS certificate for the Kubernetes Service Account"
  type        = string
}

variable "service_account_key" {
  description = "TLS Key for the Kubernetes Service Account"
  type        = string
}

variable "kube_cert" {
  description = "Kube API TLS certificate"
  type        = string
}

variable "kube_key" {
  description = "Kube API TLS Key"
  type        = string
}

# Default

variable "ssh_user" {
  description = "The ssh user used to connect and configure the controllers"
  type = string
  default = "centos"
}

variable "controllers_ami" {
  description = "AMI used for controllers - currently the only one supported"
  type        = string
  default     = "ami-0334a7a72f69e4d0f"
}