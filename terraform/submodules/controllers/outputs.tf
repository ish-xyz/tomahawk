
output "encryption_string" {
  value = base64encode(random_string.kube-encryption.result)
}

output "ssh_private_key" {
  value = tls_private_key.controllers_ssh.private_key_pem
}

output "ssh_public_key" {
  value = tls_private_key.controllers_ssh.public_key_openssh
}

output "kube_address" {
  value = "https://${aws_lb.controllers.dns_name}:6443"
}

output "private_ips" {
  value = aws_instance.controllers.*.private_ip
}

output "lb_dns_name" {
  value = aws_lb.controllers.dns_name
}

output "bastion_ssh_private_key" {
  value = tls_private_key.bastion_ssh.private_key_pem
}