#! /bin/bash
#
# Bootstrap Kubernetes Workers

## NOTE:
## All the variables with $ (e.g.: S{content}) are \
##  terraform template variables \
##  the others (e.g.: SS{content}) are normal BASH variables

set -e

lock_sb=0
ca_cert_filename="ca.pem"
ca_key_filename="ca-key.pem"
required_packages=("curl")

log() {
    # Logging function

    echo "$(date +"%m-%d-%Y::%H:%M:%S") $${1}"
}

init_checks() {
    # pre-bootstrap checks

    log "INFO: Checking requirements..."
    for package in $${required_packages[@]}; do
        if [[ -z $(which $${package}) ]]; then
            log "ERROR: you must have $${package} installed to run this script."
            exit 1
        fi
    done
}

lock_simultaneus_boostrap() {
    # A distributed sleep/lock, to avoid simoultaneus cluster initializations

    if [[ $${lock_sb} == 1 ]]; then
        log "INFO: Simultaneus bootstrap lock: active."
        #Sleep at max 19.999 sec
        sleep $(( $${RANDOM:0:2} / 5 ))
    else
        log "INFO: Simultaneus bootstrap lock: disabled."
    fi
}

create_worker_certificate() {
    # Create and sign a certificate for the new worker

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
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $(curl http://169.254.169.254/latest/meta-data/local-ipv4)
DNS.2 = $(curl http://169.254.169.254/latest/meta-data/public-ipv4)
DNS.3 = $(hostname -f)
EOF


    openssl x509 -req -in worker.csr -CA $${ca_cert_filename} \
        -CAkey $${ca_key_filename} \
        -CAcreateserial \
        -out worker.crt \
        -days ${CERT_VALIDITY} \
        -sha256 -extfile worker.ext
}

bootstrap() {
    init_checks
    create_worker_certificate
    #create_worker_kubeconfig
    #create_kube_services
    #create_autodrain_service
}

bootstrap
