variable "controllers_count" {
	type = number
	default = 3
}

variable "vpc_id" {
	type = string
	default = "vpc-f670c791"
}

variable "environment" {
	type = string
	default = "development"
}

variable "controllers_ami" {
	type = string
	default = "ami-0334a7a72f69e4d0f"
}
