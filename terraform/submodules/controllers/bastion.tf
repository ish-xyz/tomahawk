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
}

resource "aws_security_group" "bastion" {
  name   = "${var.environment}-${var.cluster_name}-bastion"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "bastion_allow_egress_all" {
  type             = "egress"
  to_port          = 0
  from_port        = 0
  protocol         = "-1"
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