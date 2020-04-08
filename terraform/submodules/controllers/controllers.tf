data "aws_vpc" "controllers" {
  id = var.vpc_id
}

data "template_file" "kube-encryption" {
  template = file("${path.module}/templates/kube-encryption.yml.tpl")
  vars = {
    encryption_key = "${base64encode(random_string.kube-encryption.result)}"
  }
}

data "template_file" "kube-controller-manager" {
  template = file("${path.module}/templates/kubeconfig.yml.tpl")
  vars = {
    project_name = var.cluster_name
    client_cert  = base64encode(var.controller_manager_cert)
    client_key   = base64encode(var.controller_manager_key)
    ca_cert      = base64encode(var.ca_cert)
    user         = "system:kube-controller-manager"
    kube_address = "https://127.0.0.1:6443"
  }
}

data "template_file" "kube-scheduler" {
  template = file("${path.module}/templates/kubeconfig.yml.tpl")
  vars = {
    project_name = var.cluster_name
    client_cert  = base64encode(var.scheduler_cert)
    client_key   = base64encode(var.scheduler_key)
    ca_cert      = base64encode(var.ca_cert)
    user         = "system:kube-scheduler"
    kube_address = "https://127.0.0.1:6443"
  }
}

data "template_file" "admin" {
  template = file("${path.module}/templates/kubeconfig.yml.tpl")
  vars = {
    project_name = var.cluster_name
    client_cert  = base64encode(var.admin_cert)
    client_key   = base64encode(var.admin_key)
    ca_cert      = base64encode(var.ca_cert)
    user         = "admin"
    kube_address = "https://127.0.0.1:6443"
  }
}

resource "tls_private_key" "controllers_ssh" {
  algorithm = "RSA"
}

resource "aws_key_pair" "controllers_ssh" {
  key_name   = "${var.environment}-${var.cluster_name}-controllers"
  public_key = tls_private_key.controllers_ssh.public_key_openssh
}

resource "aws_security_group" "controllers" {
  name   = "${var.environment}-${var.cluster_name}-controllers"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "allow_egress_all" {
  type             = "egress"
  to_port          = 0
  from_port        = 0
  protocol         = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = aws_security_group.controllers.id
}

resource "aws_security_group_rule" "allow_etcd" {
  type        = "ingress"
  from_port   = 2379
  to_port     = 2380
  protocol    = "tcp"
  cidr_blocks = var.controllers_cidrs

  security_group_id = aws_security_group.controllers.id
}

resource "aws_security_group_rule" "allow_kube_api_ext" {
  type             = "ingress"
  from_port        = 6443
  to_port          = 6443
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = aws_security_group.controllers.id
}

resource "aws_security_group_rule" "allow_ssh_ext" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = split(" ", "${join("/32 ", aws_instance.bastion.*.private_ip)}/32")

  security_group_id = aws_security_group.controllers.id
}

resource "random_string" "kube-encryption" {
  length  = 32
  special = false
}

resource "aws_instance" "controllers" {
  ami           = var.controllers_ami
  count         = var.controllers_count
  key_name      = aws_key_pair.controllers_ssh.key_name
  subnet_id     = element(var.controllers_subnets, count.index)
  instance_type = var.controllers_type

  vpc_security_group_ids = [
    "${aws_security_group.controllers.id}"
  ]

  tags = {
    Name        = "${var.controllers_prefix}-${count.index}"
    Role        = "controllers"
    Environment = var.environment
    Cluster     = var.cluster_name
  }

  connection {
    type                = "ssh"
    timeout             = "7m"
    bastion_host        = aws_instance.bastion.0.public_ip # TODO
    bastion_user        = var.bastion_user
    bastion_private_key = tls_private_key.bastion_ssh.private_key_pem
    bastion_port        = var.bastion_port
    user                = var.ssh_user
    private_key         = tls_private_key.controllers_ssh.private_key_pem
    host                = self.private_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname controller-${count.index}",
      "mkdir -p ~/bootstrap/certs"
    ]
  }
}

resource "null_resource" "import_bootstrap_files" {
  count = var.controllers_count

  triggers = {
    cluster_instance_ids         = "${join(",", aws_instance.controllers.*.id)}"
    ca_cert                      = var.ca_cert
    ca_key                       = var.ca_key
    admin_cert                   = var.admin_cert
    admin_key                    = var.admin_key
    kube_controller_manager_cert = var.controller_manager_cert
    kube_controller_manager_key  = var.controller_manager_key
    kube_scheduler_cert          = var.scheduler_cert
    kube_scheduler_key           = var.scheduler_key
    service_account_cert         = var.service_account_cert
    service_account_key          = var.service_account_key
    kubernetes_cert              = var.kube_cert
    kubernetes_key               = var.kube_key
    tpl_kube_encryption          = data.template_file.kube-encryption.rendered
    tpl_kube_controller_manager  = data.template_file.kube-controller-manager.rendered
    tpl_kube_scheduler           = data.template_file.kube-scheduler.rendered
    tpl_admin                    = data.template_file.admin.rendered
  }

  connection {
    type                = "ssh"
    timeout             = "7m"
    bastion_host        = aws_instance.bastion.0.public_ip # TODO
    bastion_user        = var.bastion_user
    bastion_private_key = tls_private_key.bastion_ssh.private_key_pem
    bastion_port        = var.bastion_port
    user                = var.ssh_user
    private_key         = tls_private_key.controllers_ssh.private_key_pem
    host                = element(aws_instance.controllers.*.private_ip, count.index)
  }

  #Import bootstrap scripts
  provisioner "file" {
    source      = "${path.module}/bin/etcd_bootstrap.sh"
    destination = "~/bootstrap/etcd_bootstrap.sh"
  }

  provisioner "file" {
    source      = "${path.module}/bin/control_plane_bootstrap.sh"
    destination = "~/bootstrap/control_plane_bootstrap.sh"
  }

  #Import certs and keys
  provisioner "file" {
    content     = var.ca_cert
    destination = "~/bootstrap/certs/ca.pem"
  }

  provisioner "file" {
    content     = var.ca_key
    destination = "~/bootstrap/certs/ca-key.pem"
  }

  provisioner "file" {
    content     = var.admin_cert
    destination = "~/bootstrap/certs/admin.pem"
  }

  provisioner "file" {
    content     = var.admin_key
    destination = "~/bootstrap/certs/admin-key.pem"
  }

  provisioner "file" {
    content     = var.controller_manager_cert
    destination = "~/bootstrap/certs/kube-controller-manager.pem"
  }

  provisioner "file" {
    content     = var.controller_manager_key
    destination = "~/bootstrap/certs/kube-controller-manager-key.pem"
  }

  provisioner "file" {
    content     = var.scheduler_cert
    destination = "~/bootstrap/certs/kube-scheduler.pem"
  }

  provisioner "file" {
    content     = var.scheduler_key
    destination = "~/bootstrap/certs/kube-scheduler-key.pem"
  }

  provisioner "file" {
    content     = var.service_account_cert
    destination = "~/bootstrap/certs/service-account.pem"
  }

  provisioner "file" {
    content     = var.service_account_key
    destination = "~/bootstrap/certs/service-account-key.pem"
  }

  provisioner "file" {
    content     = var.kube_cert
    destination = "~/bootstrap/certs/kubernetes.pem"
  }

  provisioner "file" {
    content     = var.kube_key
    destination = "~/bootstrap/certs/kubernetes-key.pem"
  }

  provisioner "file" {
    content     = data.template_file.kube-encryption.rendered
    destination = "~/bootstrap/encryption-config.yaml"
  }

  provisioner "file" {
    content     = data.template_file.kube-controller-manager.rendered
    destination = "~/bootstrap/kube-controller-manager.kubeconfig"
  }

  provisioner "file" {
    content     = data.template_file.kube-scheduler.rendered
    destination = "~/bootstrap/kube-scheduler.kubeconfig"
  }

  provisioner "file" {
    content     = data.template_file.admin.rendered
    destination = "~/bootstrap/admin.kubeconfig"
  }
}

resource "null_resource" "bootstrap-controllers" {
  count      = var.controllers_count
  depends_on = [null_resource.import_bootstrap_files]

  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.controllers.*.id)}"
  }

  connection {
    type                = "ssh"
    timeout             = "7m"
    bastion_host        = aws_instance.bastion.0.public_ip # TODO
    bastion_user        = var.bastion_user
    bastion_private_key = tls_private_key.bastion_ssh.private_key_pem
    bastion_port        = var.bastion_port
    user                = var.ssh_user
    private_key         = tls_private_key.controllers_ssh.private_key_pem
    host                = element(aws_instance.controllers.*.private_ip, count.index)
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/bootstrap/*.sh",
      "cd ~/bootstrap && sudo ./etcd_bootstrap.sh \"${join(" ", aws_instance.controllers.*.private_ip)}\"",
      "cd ~/bootstrap && sudo ./control_plane_bootstrap.sh \"${join(" ", aws_instance.controllers.*.private_ip)}\" ${var.cluster_cidr} ${var.svc_cluster_ip_cidr}",
      "rm -rf ~/bootstrap"
    ]
  }
}
