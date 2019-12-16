variable "workers_ami" {
  type    = string
  default = "ami-0334a7a72f69e4d0f"
}

variable "vpc_id" {
  type    = string
  default = "vpc-f670c791"
}

variable "environment" {
  type    = string
  default = "development"
}

variable "worker_tags" {
  type = map
  default = {
    Name        = "kube-worker-asg"
    Environment = "development"
  }
}

/*
data "aws_subnet_ids" "workers" {
  vpc_id = var.vpc_id
}

resource "aws_launch_configuration" "worker" {

  name_prefix = "kube-workers-"

  image_id        = var.workers_ami
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.workers.id}"]

  user_data = data.template_file.workers_bootstrap.rendered

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "workers" {
  name   = "kube-workers"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "allow_all" {
  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.workers.id
}

resource "aws_autoscaling_group" "worker" {

  name = aws_launch_configuration.worker.name

  min_size             = 4
  desired_capacity     = 4
  max_size             = 4
  health_check_type    = "EC2"
  launch_configuration = aws_launch_configuration.worker.name
  vpc_zone_identifier  = data.aws_subnet_ids.workers.ids

  Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  dynamic "tag" {
    for_each = var.worker_tags
    iterator = asg_tag
    content {
      key                 = asg_tag.key
      value               = asg_tag.value
      propagate_at_launch = true
    }
  }
}
*/

module "init-ca" {
  source          = "ish-xyz/certificates-generator/tls"
  version         = "0.1.0"
  cn              = "CA"
  org             = "kubernetes-on-aws-init-CA"
  ou              = "kubernetes-on-aws"
  country         = "United Kindgom"
  location        = "London"
  validity_period = 8760
}

data "template_file" "workers_bootstrap" {
  template = file("${path.module}/bootstrap.sh.tpl")
  vars = {
    CA_CERT = module.init-ca.ca_cert
    CA_KEY  = module.init-ca.ca_key
    CERT_VALIDITY = 8760
    COUNTRY = "UK"
    LOCATION = "London"
    STATE = "United Kingdom"
    ORG = "kubernetes-on-aws"
    OU = "system:nodes"
    CN = "system:nodes:worker"
  }
}

resource "local_file" "workers_boostrap" {
  content = data.template_file.workers_bootstrap.rendered
  filename = "${path.module}/bootstrap.sh"
  file_permission = "0655"
}
