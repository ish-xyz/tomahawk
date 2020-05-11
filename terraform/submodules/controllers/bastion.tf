resource "tls_private_key" "bastion_ssh" {
  algorithm = "RSA"
}

resource "aws_key_pair" "bastion" {
  key_name   = "${var.environment}-${var.cluster_name}-bastion"
  public_key = tls_private_key.bastion_ssh.public_key_openssh
}

resource "aws_instance" "bastion" {
  ami           = var.bastion_ami
  count         = var.bastion_count
  key_name      = aws_key_pair.bastion.key_name
  subnet_id     = element(var.bastion_subnets, count.index)
  instance_type = var.bastion_type

  vpc_security_group_ids = [
    "${aws_security_group.bastion.id}"
  ]

  tags = {
    Name        = "${var.bastion_hosts_prefix}-${count.index}"
    Role        = "bastion"
    Environment = var.environment
    Cluster     = var.cluster_name
  }

  connection {
    type                = "ssh"
    timeout             = "7m"
    user                = var.bastion_user
    private_key         = tls_private_key.bastion_ssh.private_key_pem
    host                = self.public_ip
  }

  # Import bootstrap script
  provisioner "file" {
    source      = "${path.module}/bin/bastion_host.sh"
    destination = "~/bootstrap/bastion_host.sh"
  }

  # Run bootstrap script
  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/bootstrap/*.sh",
      "cd ~/bootstrap && sudo ./bastion_host.sh",
      "rm -rf ~/bootstrap"
    ]
  }
}

resource "aws_security_group" "bastion" {
  name   = "${var.environment}-${var.cluster_name}-bastion"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "bastion_allow_egress_http" {
  type             = "egress"
  to_port          = 80
  from_port        = 80
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "allow_egress_ssh" {
  type             = "egress"
  to_port          = 22
  from_port        = 22
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "allow_egress_https" {
  type             = "egress"
  to_port          = 443
  from_port        = 443
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "allow_egress_dns" {
  type             = "egress"
  to_port          = 53
  from_port        = 53
  protocol         = "udp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = aws_security_group.bastion.id
}


resource "aws_security_group_rule" "bastion_allow_ssh_ext" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.bastion.id
}
