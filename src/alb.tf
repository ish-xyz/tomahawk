data "aws_elb_service_account" "main" {}

resource "aws_lb" "controllers" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_allow.id]
  subnets            = var.controllers_subnets

  #enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = var.alb_bucket_prefix
    enabled = true
  }

  tags = {
    Environment = var.environment
    Name        = var.alb_name
  }
}

resource "aws_lb_target_group" "controllers" {
  name     = "kube-controllers-tg"
  port     = var.kube_api_port
  protocol = "HTTPS"
  vpc_id   = var.vpc_id
}


resource "aws_lb_listener" "controllers" {
  load_balancer_arn = aws_lb.controllers.arn
  port              = var.kube_api_port
  protocol          = "HTTPS"
  ssl_policy        = var.alb_ssl_policy
  certificate_arn   = aws_iam_server_certificate.alb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.controllers.arn
  }
}

resource "aws_iam_server_certificate" "alb" {
  name             = "kube_controllers_alb_certificate"
  certificate_body = module.kubernetes.cert
  private_key      = module.kubernetes.key
}


resource "aws_lb_target_group_attachment" "test" {
  count            = var.controllers_count
  target_group_arn = aws_lb_target_group.controllers.arn
  target_id        = element(aws_instance.controllers.*.id, count.index)
  port             = var.kube_api_port
}

#resource "aws_lb_listener_certificate" "controllers" {
#  listener_arn    = "${aws_lb_listener.controllers.arn}"
#  certificate_arn = "${aws_iam_server_certificate.alb.arn}"
#}

resource "aws_s3_bucket" "alb_logs" {
  bucket        = var.alb_bucket
  acl           = "private"
  force_destroy = true

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.alb_bucket}/${var.alb_bucket_prefix}/*",
      "Principal": {
        "AWS": [
          "${data.aws_elb_service_account.main.arn}"
        ]
      }
    }
  ]
}
POLICY
}

resource "aws_security_group" "alb_allow" {
  name        = "alb_allow_traffic"
  description = "ALB allow TLS traffic 6443/TCP"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.kube_api_port
    to_port     = var.kube_api_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
