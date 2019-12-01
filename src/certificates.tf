#
module "ca" {
	source 		= "./certificates-generator"
	org			= "aws-k8s-lab-CA"
	ou			= "aws-k8s-lab"
	cn			= "CA"
	country		= "United Kindgom"
	location	= "London"
	validity_period	= 8760
}

module "admin" {
	source 		= "./certificates-generator"
	org			= "system:masters"
	ou			= "aws-k8s-lab"
	cn			= "admin"
	ca_cert		= module.ca.ca_cert
	ca_key		= module.ca.ca_key
	country		= "United Kindgom"
	location	= "London"
	validity_period	= 8760
}

module "admin" {
	source 		= "./certificates-generator"
	org			= "system:masters"
	ou			= "aws-k8s-lab"
	cn			= "admin"
	ca_cert		= module.ca.ca_cert
	ca_key		= module.ca.ca_key
	country		= "United Kindgom"
	location	= "London"
	validity_period	= 8760
}