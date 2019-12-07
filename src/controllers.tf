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

resource "aws_instance" "controllers" {

  ami           = var.controllers_ami
  count         = var.controllers_count
  key_name      = aws_key_pair.k8s_bootstrap.key_name
  instance_type = "t2.micro"

  security_groups = [
    "${aws_security_group.controllers.name}"
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

resource "aws_security_group_rule" "allow_ssh_ext" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.controllers.id
}

resource "random_string" "ekey" {
  length           = 32
  special          = true
  override_special = "/@£$"
}

data "template_file" "ekey" {
  template = file("${path.module}/templates/encryption-config.yaml.tpl")
  vars = {
    ENCRYPTION_KEY = "${base64encode(random_string.ekey.result)}"
  }
}


resource "null_resource" "scp_kube_configs" {
  count = var.controllers_count

  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.controllers.*.id)}",
    template_file_id     = data.template_file.ekey.rendered
  }

  connection {
    type        = "ssh"
    user        = "centos"
    private_key = tls_private_key.bootstrap_key.private_key_pem
    host        = element(aws_instance.controllers.*.public_ip, count.index)
  }

  provisioner "file" {
    content     = data.template_file.ekey.rendered
    destination = "~/bootstrap/encryption-config.yaml"
  }
}
