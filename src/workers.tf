resource "aws_launch_configuration" "worker" {
  name_prefix = "worker-"

  image_id                    = var.workers_ami
  instance_type               = "t2.micro"
  security_groups             = ["${aws_security_group.workers.id}"]

  user_data = ""

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

  security_group_id = aws_security_group.controllers.id
}

resource "aws_autoscaling_group" "worker" {

  name = "${aws_launch_configuration.worker.name}-asg"

  min_size             = 10
  desired_capacity     = 15
  max_size             = 25
  health_check_type    = "EC2"
  launch_configuration = "${aws_launch_configuration.worker.name}"
  vpc_zone_identifier  = ["${aws_subnet.public.*.id}"]

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }
}
