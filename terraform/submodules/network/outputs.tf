output "private_subnets" {
  value = aws_subnet.prv_subnets.*.id
}

output "public_subnets" {
  value = aws_subnet.pub_subnets.*.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}