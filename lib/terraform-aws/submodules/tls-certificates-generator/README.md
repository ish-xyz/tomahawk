# Terraform Module certificates-generator

A Terraform module to generate TLS RSA certificates with a self provisioned CA

This terraform modules uses the tls_provider resources defined in -> https://www.terraform.io/docs/providers/tls/index.html

The input variables are:

* key_filename
* cert_filename
* validity_period
* org
* cn
* location
* country
* ou


The output is:

* It will create 2 files 1 certificate and 1 key.
* module_name.key -> private key
* module_name.cert -> certificate
