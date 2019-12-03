variable "count_masters" {
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

resource "tls_private_key" "bootstrap_key" {
	algorithm = "RSA"
}

resource "local_file" "bootstrap_private_key" {
	content = tls_private_key.bootstrap_key.private_key_pem
	filename = "${path.module}/installer/.bootstrap.pem"
	file_permission = "0600"
}

resource "aws_key_pair" "k8s_bootstrap" {
	key_name   = "k8s_bootstrap"
	public_key = tls_private_key.bootstrap_key.public_key_openssh
}

resource "aws_instance" "master" {
	ami = "ami-0334a7a72f69e4d0f"
	count = var.count_masters
	key_name = aws_key_pair.k8s_bootstrap.key_name
	instance_type = "t2.micro"

  	security_groups = [
		  "${aws_security_group.ingress.name}"
	]

	tags = {
		Name = "k8s-master"
		role = "master"
		environment = var.environment
	}

	provisioner "file" {
		source      = "${path.module}/installer/etcd_bootstrap.sh"
		destination = "~/.etcd_bootstrap.sh"

		connection {
			type     	= "ssh"
			user     	= "centos"
			private_key = tls_private_key.bootstrap_key.private_key_pem
			host     	= self.public_ip
		}
	}
}

resource "aws_security_group" "ingress" {
	name = "allow-ssh"
	vpc_id = var.vpc_id

	ingress {
		cidr_blocks = [
			"0.0.0.0/0"
		]
		from_port = 22
		to_port = 22
		protocol = "tcp"
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}