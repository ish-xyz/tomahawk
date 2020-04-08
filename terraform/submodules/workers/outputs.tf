output "workers_bootstrap_script" {
    value = data.template_file.workers_bootstrap.rendered
}

output "ssh_private_key" {
    value = tls_private_key.workers_ssh.private_key_pem
}

output "ssh_public_key" {
    value = tls_private_key.workers_ssh.public_key_openssh
}
