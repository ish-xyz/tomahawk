#! /bin/bash
#
# Bootstrap Kubernetes Workers

## NOTE:
## All the variables with $ (e.g.: S{content}) are \
##  terraform template variables \
##  the others (e.g.: SS{content}) are normal BASH variables

ca_cert_filename="ca.pem"
ca_key_filename="ca-key.pem"

log() {
    # Logging function

    echo "$(date +"%m-%d-%Y::%H:%M:%S") ${1}"
}

init_checks() {
    # pre-control-plane checks

    log "INFO: Checking requirements..."

    if [[ -z $(which curl) ]]; then
        log "ERROR: you must install curl to run this script."
        exit 1
    fi
}

create_ca_files() {
    log "INFO: Create CA files..."
    cat <<EOF | sed '$d' | tee $${ca_cert_filename}
${CA_CERT}
EOF
    cat <<EOF | sed '$d' | tee $${ca_key_filename}
${CA_KEY}
EOF
    log "INFO: Create and sign certificate"
    openssl genrsa -out worker.key 2048
    openssl req -new -key worker.key -out worker.csr -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCATION}/O=${ORG}/OU=${OU}/CN=${CN}"
    cat <<EOF | tee worker.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = example.com
DNS.2 = worker.example.com
DNS.3 = hostname-worker.example.com
EOF
#DNS.1 = $(curl http://169.254.169.254/latest/meta-data/local-ipv4)
#DNS.2 = $(curl http://169.254.169.254/latest/meta-data/public-ipv4)
#DNS.3 = $(hostname -f)
    openssl x509 -req -in worker.csr -CA $${ca_cert_filename} \
        -CAkey $${ca_key_filename} \
        -CAcreateserial \
        -out worker.crt \
        -days ${CERT_VALIDITY} \
        -sha256 -extfile worker.ext
}

create_ca_files
