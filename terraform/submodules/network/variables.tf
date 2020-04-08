variable "environment" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "prv_subnets_cidr" {
  type = list
}

variable "prv_subnets_azs" {
  type = list
}

variable "pub_subnets_cidr" {
  type = list
}

variable "pub_subnets_azs" {
  type = list
}
