resource "aws_lb" "controllers" {
  name               = var.nlb_name
  internal           = false
  load_balancer_type = "network"
  subnets            = var.nlb_subnets

  access_logs {
    bucket  = aws_s3_bucket.nlb_logs.bucket
    prefix  = var.nlb_bucket_prefix
    enabled = true
  }

  tags = {
    Environment = var.environment
    Name        = var.nlb_name
    Cluster     = var.cluster_name
  }
}

resource "aws_lb_target_group" "controllers" {
  name     = "${var.nlb_name}-controllers"
  port     = 6443
  protocol = "TCP"
  vpc_id   = var.vpc_id
}


resource "aws_lb_listener" "controllers" {
  load_balancer_arn = aws_lb.controllers.arn
  port              = 6443
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.controllers.arn
  }
}

resource "aws_lb_target_group_attachment" "controllers" {
  count            = var.controllers_count
  target_group_arn = aws_lb_target_group.controllers.arn
  target_id        = element(aws_instance.controllers.*.id, count.index)
  port             = 6443
}

resource "aws_s3_bucket" "nlb_logs" {
  bucket        = var.nlb_bucket
  acl           = "private"
  force_destroy = true

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSLogDeliveryWrite",
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.nlb_bucket}/${var.nlb_bucket_prefix}/*",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Sid": "AWSLogDeliveryAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${var.nlb_bucket}"
    }
  ]
}
POLICY
}

