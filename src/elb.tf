data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "elb_logs" {
  bucket        = var.elb_bucket
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
      "Resource": "arn:aws:s3:::${var.elb_bucket}/${var.elb_bucket_prefix}/*",
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


resource "aws_elb" "kube-controllers" {
  name    = var.elb_name
  subnets = aws_instance.controllers.*.subnet_id

  access_logs {
    bucket        = aws_s3_bucket.elb_logs.id
    bucket_prefix = var.elb_bucket_prefix
    interval      = 60
  }

  listener {
    instance_port     = 6443
    instance_protocol = "https"
    lb_port           = 6443
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:6443/"
    interval            = 30
  }

  instances                   = aws_instance.controllers.*.id
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 300

  tags = {
    Environment = var.environment
    Name        = var.elb_name
  }
}
