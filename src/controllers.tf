resource "tls_private_key" "bootstrap_key" {
  algorithm = "RSA"
}

resource "local_file" "bootstrap_private_key" {
  content         = tls_private_key.bootstrap_key.private_key_pem
  filename        = "${path.module}/installer/.bootstrap.pem"
  file_permission = "0600"
}

resource "aws_key_pair" "k8s_bootstrap" {
  key_name   = "k8s_bootstrap"
  public_key = tls_private_key.bootstrap_key.public_key_openssh
}

resource "aws_security_group" "controllers" {
  name   = "kube-controllers"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "allow_egress_all" {
  type        = "egress"
  to_port     = 0
  from_port   = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.controllers.id
}

resource "aws_security_group_rule" "allow_etcd_ext" {
  type        = "ingress"
  from_port   = 2380
  to_port     = 2380
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.controllers.id
}

resource "aws_security_group_rule" "allow_kube_api_ext" {
  type        = "ingress"
  from_port   = 6443
  to_port     = 6443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.controllers.id
}

resource "aws_security_group_rule" "allow_ssh_ext" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.controllers.id
}

resource "random_string" "kube-encryption" {
  length           = 32
  special          = true
  override_special = "/@£$"
}

data "template_file" "kube-encryption" {
  template = file("${path.module}/templates/kube-encryption.yml.tpl")
  vars = {
    encryption_key = "${base64encode(random_string.kube-encryption.result)}"
  }
}

data "template_file" "kube-controller-manager" {
  template = file("${path.module}/templates/controllers-components.yml.tpl")
  vars = {
    project_name = var.project_name
    client_cert  = base64encode(module.kube-controller-manager.cert)
    client_key   = base64encode(module.kube-controller-manager.key)
    ca_cert      = base64encode(module.init-ca.ca_cert)
    component    = "system:kube-controller-manager"
  }
}

data "template_file" "kube-scheduler" {
  template = file("${path.module}/templates/controllers-components.yml.tpl")
  vars = {
    project_name = var.project_name
    client_cert  = base64encode(module.kube-scheduler.cert)
    client_key   = base64encode(module.kube-scheduler.key)
    ca_cert      = base64encode(module.init-ca.ca_cert)
    component    = "system:kube-scheduler"
  }
}

data "template_file" "admin" {
  template = file("${path.module}/templates/controllers-components.yml.tpl")
  vars = {
    project_name = var.project_name
    client_cert  = base64encode(module.admin.cert)
    client_key   = base64encode(module.admin.key)
    ca_cert      = base64encode(module.init-ca.ca_cert)
    component    = "admin"
  }
}

resource "aws_instance" "controllers" {

  ami           = var.controllers_ami
  count         = var.controllers_count
  key_name      = aws_key_pair.k8s_bootstrap.key_name
  subnet_id     = element(var.controllers_subnets, count.index)
  instance_type = "t2.micro"

  security_groups = [
    "${aws_security_group.controllers.id}"
  ]

  tags = {
    Name        = "kube-controller-${count.index}"
    role        = "master"
    environment = var.environment
  }

  connection {
    type        = "ssh"
    user        = "centos"
    private_key = tls_private_key.bootstrap_key.private_key_pem
    host        = self.public_ip
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
    cluster_instance_ids = "${join(",", aws_instance.controllers.*.id)}"
  }

  connection {
    type        = "ssh"
    user        = "centos"
    private_key = tls_private_key.bootstrap_key.private_key_pem
    host        = element(aws_instance.controllers.*.public_ip, count.index)
  }

  #Import bootstrap scripts
  provisioner "file" {
    source      = "${path.module}/installer/etcd_bootstrap.sh"
    destination = "~/bootstrap/etcd_bootstrap.sh"
  }

  #Import certs and keys
  provisioner "file" {
    content     = module.init-ca.ca_cert
    destination = "~/bootstrap/certs/ca.pem"
  }

  provisioner "file" {
    content     = module.init-ca.ca_key
    destination = "~/bootstrap/certs/ca-key.pem"
  }

  provisioner "file" {
    content     = module.admin.cert
    destination = "~/bootstrap/certs/admin.pem"
  }

  provisioner "file" {
    content     = module.admin.key
    destination = "~/bootstrap/certs/admin-key.pem"
  }

  provisioner "file" {
    content     = module.kube-controller-manager.cert
    destination = "~/bootstrap/certs/kube-controller-manager.pem"
  }

  provisioner "file" {
    content     = module.kube-controller-manager.key
    destination = "~/bootstrap/certs/kube-controller-manager-key.pem"
  }

  provisioner "file" {
    content     = module.kube-proxy.cert
    destination = "~/bootstrap/certs/kube-proxy.pem"
  }

  provisioner "file" {
    content     = module.kube-proxy.key
    destination = "~/bootstrap/certs/kube-proxy-key.pem"
  }

  provisioner "file" {
    content     = module.kube-scheduler.cert
    destination = "~/bootstrap/certs/kube-scheduler.pem"
  }

  provisioner "file" {
    content     = module.kube-scheduler.key
    destination = "~/bootstrap/certs/kube-scheduler-key.pem"
  }

  provisioner "file" {
    content     = module.service-accounts.cert
    destination = "~/bootstrap/certs/service-accounts.pem"
  }

  provisioner "file" {
    content     = module.service-accounts.key
    destination = "~/bootstrap/certs/service-accounts-key.pem"
  }

  provisioner "file" {
    content     = module.kubernetes.cert
    destination = "~/bootstrap/certs/kubernetes.pem"
  }

  provisioner "file" {
    content     = module.kubernetes.key
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

resource "null_resource" "bootstrap-etcd" {
  count      = var.controllers_count
  depends_on = [null_resource.import_bootstrap_files]

  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.controllers.*.id)}"
  }

  connection {
    type        = "ssh"
    user        = "centos"
    private_key = tls_private_key.bootstrap_key.private_key_pem
    host        = element(aws_instance.controllers.*.public_ip, count.index)
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/bootstrap/etcd_bootstrap.sh",
      "cd ~/bootstrap && sudo ./etcd_bootstrap.sh \"${join(" ", aws_instance.controllers.*.private_ip)}\""
    ]
  }
}


