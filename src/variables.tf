##Global
variable "vpc_id" {
  type    = string
  default = "vpc-f670c791"
}

variable "environment" {
  type    = string
  default = "development"
}

variable "kube_api_port" {
	type = number
	default = 6443
}

## Controllers instances
variable "controllers_count" {
  type    = number
  default = 3
}

variable "controllers_subnets" {
	type 	= list
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

##Controllers ALB

variable "alb_bucket" {
  type    = string
  default = "kube-controllers-alb"
}

variable "alb_bucket_prefix" {
  type    = string
  default = "logs"
}

variable "alb_name" {
  type    = string
  default = "kube-controllers-alb"
}

variable "alb_ssl_policy" {
	type = string
	default = "ELBSecurityPolicy-2016-08"
}