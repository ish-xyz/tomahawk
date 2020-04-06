resource "tls_private_key" "ca" {
  algorithm   = "RSA"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm     = "RSA"
  private_key_pem   = tls_private_key.ca.private_key_pem
  is_ca_certificate = true

  subject {
    organization        = var.org
    common_name         = var.cn
    organizational_unit = var.ou
    country             = var.country
    locality            = var.location
  }

  validity_period_hours = var.validity_period

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

resource "tls_private_key" "service" {
  algorithm   = "RSA"
}

resource "tls_cert_request" "service" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.service.private_key_pem
  dns_names       = var.dns_names
  ip_addresses    = var.ip_addresses 

  subject {
    organization        = var.org
    common_name         = var.cn
    organizational_unit = var.ou
    country             = var.country
    locality            = var.location
  }
}

resource "tls_locally_signed_cert" "local" {
  cert_request_pem   = tls_cert_request.service.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = var.ca_key  != "generated" ? var.ca_key  : tls_private_key.ca.private_key_pem
  ca_cert_pem        = var.ca_cert != "generated" ? var.ca_cert  : tls_self_signed_cert.ca.cert_pem

  validity_period_hours = var.validity_period

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

resource "local_file" "key-file" {
  count           = var.key_filename == "attribute_only" ? 0 : 1
	content         = tls_private_key.service.private_key_pem
	filename        = var.key_filename
	file_permission = "0600"
}

resource "local_file" "cert-file" {
  count           = var.cert_filename == "attribute_only" ? 0 : 1
	content         = tls_locally_signed_cert.local.cert_pem
	filename        = var.cert_filename
	file_permission = "0644"
}
