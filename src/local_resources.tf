resource "local_file" "controllers_ssh" {
  content         = tls_private_key.controllers_ssh.private_key_pem
  filename        = "${path.module}/local/controllers.pem"
  file_permission = "0600"
}

resource "local_file" "workers_ssh" {
  content         = tls_private_key.workers_ssh.private_key_pem
  filename        = "${path.module}/local/workers.pem"
  file_permission = "0600"
}

resource "local_file" "ca_certificate" {
  content         = module.init-ca.ca_cert
  filename        = "${path.module}/local/ca.pem"
  file_permission = "0644"
}

resource "local_file" "ca_key" {
  content         = module.init-ca.ca_key
  filename        = "${path.module}/local/ca-key.pem"
  file_permission = "0600"
}

resource "local_file" "admin_kubeconfig" {
  content         = data.template_file.admin.rendered
  filename        = "${path.module}/local/admin.kubeconfig"
  file_permission = "0644"
}
