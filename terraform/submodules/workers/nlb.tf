/*
resource "aws_lb" "workers" {
  name               = var.nlb_name
  internal           = false
  load_balancer_type = "network"
  subnets            = var.nlb_subnets

  access_logs {
    bucket  = aws_s3_bucket.nlb_logs.bucket
    prefix  = var.bucket_prefix
    enabled = true
  }

  tags = {
    Environment = var.environment
    Name        = var.nlb_name
    Cluster     = var.cluster_name
  }
}



resource "aws_lb_target_group" "workers" {
  count    = len(var.nlb_config)
  name     = var.nlb_config[count.index]["name"]
  port     = var.nlb_config[count.index]["port"]
  protocol = var.nlb_config[count.index]["protocol"]
  vpc_id   = var.workers_vpc_id
}

resource "aws_lb_listener" "workers" {
  count = len(var.nlb_config)
  load_balancer_arn = aws_lb.workers.arn
  port              = var.nlb_config[count.index]["port"]
  protocol          = var.nlb_config[count.index]["protocol"]
  default_action {
    type             = var.nlb_config[count.index]["type"]
    target_group_arn = element(aws_lb_target_group.wokers.*.arn, count.index)
  }
}

resource "aws_s3_bucket" "nlb_logs" {
  bucket        = var.bucket_name
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
      "Resource": "arn:aws:s3:::${var.bucket_name}/${var.bucket_prefix}/*",
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
      "Resource": "arn:aws:s3:::${var.bucket_name}"
    }
  ]
}
POLICY
}


# Loop with targets

variable "nlb_config" {
    type = list
    default = [
        {
        "name": "http-workers-tg",
        "port": 80,
        "protocol": "TCP",
        "type": "forward"
        }
    ]
}

variable "bucket_prefix" {
  type = string
  default = "workers"
}

nlb_name
nlb_subnets
bucket_name

*/
