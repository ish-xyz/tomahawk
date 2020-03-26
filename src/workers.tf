data "aws_subnet_ids" "workers" {
  vpc_id = var.workers_vpc_id
}

data "template_file" "kube-proxy" {
  template = file("${path.module}/templates/kubeconfig.yml.tpl")
  vars = {
    project_name = var.cluster_name
    client_cert  = base64encode(module.kube-proxy.cert)
    client_key   = base64encode(module.kube-proxy.key)
    ca_cert      = base64encode(module.init-ca.ca_cert)
    user         = "system:kube-proxy"
    kube_address = "https://${aws_lb.controllers.dns_name}:6443"
  }
}

data "template_file" "workers_bootstrap" {
  template = file("${path.module}/templates/workers-bootstrap.sh.tpl")
  vars = {
    POD_CIDR          = var.cluster_cidr
    CA_CERT           = module.init-ca.ca_cert
    CA_KEY            = module.init-ca.ca_key
    CERT_VALIDITY     = 8760
    COUNTRY           = "UK"
    LOCATION          = "London"
    STATE             = "United Kingdom"
    ORG               = "system:nodes"
    OU                = var.cluster_name
    CN                = "system:node"
    PROJECT_NAME      = var.cluster_name
    KUBECONFIG_PROXY  = data.template_file.kube-proxy.rendered
    KUBE_ADDRESS      = "https://${aws_lb.controllers.dns_name}:6443"
  }
}


data "template_cloudinit_config" "bootstrap" {
  gzip           = true
  base64_encode  = true

  part {
    filename     = "bootstrap.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.workers_bootstrap.rendered
  }
}

resource "tls_private_key" "workers_ssh" {
  algorithm = "RSA"
}

resource "aws_key_pair" "workers_ssh" {
  key_name   = "kube-workers"
  public_key = tls_private_key.workers_ssh.public_key_openssh
}

resource "aws_launch_configuration" "worker" {

  name_prefix = "kube-workers-"

  image_id         = var.workers_ami
  instance_type    = var.workers_type
  security_groups  = ["${aws_security_group.workers.id}"]
  key_name         = aws_key_pair.workers_ssh.key_name 

  user_data_base64 = data.template_cloudinit_config.bootstrap.rendered

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "workers" {
  name   = "kube-workers"
  vpc_id = var.workers_vpc_id
}

resource "aws_security_group_rule" "workers_allow_ingress_all" {
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.workers.id
}

resource "aws_security_group_rule" "workers_allow_egress_all" {
  type        = "egress"
  to_port     = 0
  from_port   = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.workers.id
}

resource "aws_autoscaling_group" "worker" {

  name = aws_launch_configuration.worker.name

  min_size             = var.workers_min
  desired_capacity     = var.workers_count
  max_size             = var.workers_max
  health_check_type    = "EC2"
  launch_configuration = aws_launch_configuration.worker.name
  vpc_zone_identifier  = data.aws_subnet_ids.workers.ids


  lifecycle {
    create_before_destroy = true
  }

  dynamic "tag" {
    for_each = var.workers_tags
    iterator = asg_tag
    content {
      key                 = asg_tag.key
      value               = asg_tag.value
      propagate_at_launch = true
    }
  }
}
