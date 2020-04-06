output "key" {
   value = tls_private_key.service.private_key_pem
}

output "cert" {
   value = tls_locally_signed_cert.local.cert_pem
}

output "ca_key" {
   value = var.ca_key  != "generated" ? var.ca_key  : tls_private_key.ca.private_key_pem
}

output "ca_cert" {
   value = var.ca_cert != "generated" ? var.ca_cert  : tls_self_signed_cert.ca.cert_pem
}
