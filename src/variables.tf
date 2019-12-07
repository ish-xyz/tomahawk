##Global
variable "vpc_id" {
  type    = string
  default = "vpc-f670c791"
}

variable "environment" {
  type    = string
  default = "development"
}

##Controllers
variable "controllers_count" {
  type    = number
  default = 3
}


variable "controllers_ami" {
  type    = string
  default = "ami-0334a7a72f69e4d0f"
}

##ELB

variable "elb_bucket" {
  type    = string
  default = "kube-controllers-elb"
}

variable "elb_bucket_prefix" {
  type    = string
  default = "logs"
}

variable "elb_name" {
  type    = string
  default = "kube-controllers-elb"
}
