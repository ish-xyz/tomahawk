/*
resource "aws_instance" "workers" {
  ami           = var.workers_ami
  count         = var.workers_count
  key_name      = aws_key_pair.k8s_bootstrap.key_name
  subnet_id     = var.workers_subnet
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
*/