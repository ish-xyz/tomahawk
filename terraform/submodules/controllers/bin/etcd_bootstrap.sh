#!/bin/bash
##
## Bootstrap etcd script

set -e

CONTROLLERS=${1}
LOCK_SB=1
ETCD_URL="https://github.com/etcd-io/etcd/releases/download/v3.4.0/etcd-v3.4.0-linux-amd64.tar.gz"
ETCD_CONFDIR="/etc/etcd"
ETCD_DATADIR="/var/lib/etcd"
CERTS_DIR="certs"
REQUIRED_KEYS=("ca.pem" "kubernetes.pem" "kubernetes-key.pem")
ETCD_NAME=$(hostname -s)
INTERNAL_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
REQUIRED_PACKAGES=("curl" "yum")

trap "rm -rf ${ETCD_URL##*/}  ./$(echo ${ETCD_URL##*/} | sed 's/\.tar\.gz//')" EXIT SIGTERM SIGKILL SIGINT

log() {
    # Logging function

    echo "$(date +"%m-%d-%Y::%H:%M:%S") ${1}" | tee -a /boostrap.log
}

init_checks() {
    # pre-bootstrap checks

    log "INFO: Checking requirements..."

    if [[ -z ${CONTROLLERS} ]]; then
        log "ERROR: you need to pass the cluster members IPs"
        exit 1
    fi
    
    for KEY in ${REQUIRED_KEYS[@]}; do
        if ! [[ -f "${CERTS_DIR}/${KEY}" ]]; then
            log "ERROR: This is a full tls implementation. A TLS cert or key is missing: ${CERTS_DIR}/${KEY}"
            exit 1
        fi
    done

    for pkg in ${REQUIRED_PACKAGES[@]}; do
        if [[ -z $(which ${pkg}) ]]; then
            log "ERROR: you must have ${pkg} installed to run this script."
            exit 1
        fi
    done
}

lock_simultaneus_boostrap() {
    # A distributed sleep/lock, to avoid simoultaneus cluster initializations

    if [[ $LOCK_SB == 1 ]]; then
        log "INFO: Simultaneus bootstrap lock: active."
        #Sleep at max 19.999 sec
        sleep $(( ${RANDOM:0:2} / 5 ))
    else
        log "INFO: Simultaneus bootstrap lock: disabled."
    fi
}

generate_initial_cluster() {
    # Generate Initial Cluster string

    MEMBERS=(${CONTROLLERS})
    cn=0
    for IP in ${MEMBERS[@]}; do 
        [[ $IP == ${MEMBERS[0]} ]] && \
            IC="controller-${cn}=https://$IP:2380" || \
            IC=${IC}",controller-${cn}=https://$IP:2380"; 
        cn=$((cn + 1));
    done
    initial_cluster=${IC}
}

boostrap() {
    # Main function to run and bootstrap the etcd

    init_checks
    lock_simultaneus_boostrap

    log "INFO: downloading etcd..."

    curl -O -L ${ETCD_URL} && tar -xvf ${ETCD_URL##*/}
    if [[ $? != 0 ]]; then
        log "ERROR: etcd download failed."
        exit 1
    fi

    log "INFO: installing etcd..."
    mv $(echo ${ETCD_URL##*/} | sed 's/\.tar\.gz//')/etcd* /usr/bin
    mkdir -p ${ETCD_CONFDIR} ${ETCD_DATADIR}
    cp  ${CERTS_DIR}/ca.pem \
        ${CERTS_DIR}/kubernetes-key.pem \
        ${CERTS_DIR}/kubernetes.pem ${ETCD_CONFDIR}/

    log "INFO: setting permissions for keys"
    chmod 600 ${ETCD_CONFDIR}/*key.pem

    generate_initial_cluster

    log "INFO: creating systemd unit files"
    cat <<EOF | sed 's/    //' | tee /etc/systemd/system/etcd.service
    [Unit]
    Description=etcd
    Documentation=https://github.com/coreos

    [Service]
    Type=notify
    ExecStart=/usr/bin/etcd \\
        --name ${ETCD_NAME} \\
        --cert-file=/etc/etcd/kubernetes.pem \\
        --key-file=/etc/etcd/kubernetes-key.pem \\
        --peer-cert-file=/etc/etcd/kubernetes.pem \\
        --peer-key-file=/etc/etcd/kubernetes-key.pem \\
        --trusted-ca-file=/etc/etcd/ca.pem \\
        --peer-trusted-ca-file=/etc/etcd/ca.pem \\
        --peer-client-cert-auth \\
        --client-cert-auth \\
        --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
        --listen-peer-urls https://${INTERNAL_IP}:2380 \\
        --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
        --advertise-client-urls https://${INTERNAL_IP}:2379 \\
        --initial-cluster-token etcd-cluster-0 \\
        --initial-cluster ${initial_cluster} \\
        --initial-cluster-state new \\
        --data-dir=/var/lib/etcd
    Restart=on-failure
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable etcd
  log "INFO: Starting etcd..."
  systemctl start etcd
}

boostrap
