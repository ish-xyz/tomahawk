output "key" {
   value = tls_private_key.cert.private_key_pem
}

output "cert" {
   value = tls_locally_signed_cert.local.cert_pem
}
