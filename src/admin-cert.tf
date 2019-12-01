#
module "admin" {
	source 			= "./cert-generator"
	org		 		= "system:masters"
	ou		 		= "aws-k8s-lab"
	cn  		 	= "admin"
    country		 	= "United Kindgom"
	location	 	= "London"
	validity_period = 8760
}
