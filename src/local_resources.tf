resource "local_file" "controllers_ssh" {
  content         = tls_private_key.controllers_ssh.private_key_pem
  filename        = "${path.module}/.local/ssh-controllers.pem"
  file_permission = "0600"
}

resource "local_file" "workers_ssh" {
  content         = tls_private_key.workers_ssh.private_key_pem
  filename        = "${path.module}/.local/ssh-workers.pem"
  file_permission = "0600"
}

resource "local_file" "ca_certificate" {
  content         = module.init-ca.ca_cert
  filename        = "${path.module}/.local/ca.pem"
  file_permission = "0644"
}

resource "local_file" "admin_key" {
  content         = module.admin.key
  filename        = "${path.module}/.local/admin-key.pem"
  file_permission = "0600"
}

resource "local_file" "admin_cert" {
  content         = module.admin.cert
  filename        = "${path.module}/.local/admin.pem"
  file_permission = "0644"
}

data "template_file" "remote_admin" {
  template = file("${path.module}/templates/kubeconfig.yml.tpl")
  vars = {
    project_name = var.cluster_name
    client_cert  = base64encode(module.admin.cert)
    client_key   = base64encode(module.admin.key)
    ca_cert      = base64encode(module.init-ca.ca_cert)
    user         = "admin"
    kube_address = "https://${aws_lb.controllers.dns_name}:6443"
  }
}

resource "local_file" "remote_admin" {
  content         = data.template_file.remote_admin.rendered
  filename        = "${path.module}/.local/admin.kubeconfig"
  file_permission = "0644"
}