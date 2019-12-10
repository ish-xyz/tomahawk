#!/bin/bash
##
## Bootstrap control_plane script

set -e

LOCK_SB=1
CONTROLLERS=${1}
VPC_CIDR=${2}
KUBE_PACKAGES=("https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-apiserver" \
               "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-controller-manager" \
               "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-scheduler" \
               "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl")
CERTIFICATES="certs/ca.pem certs/ca-key.pem certs/kubernetes-key.pem certs/kubernetes.pem \
             certs/service-account-key.pem certs/service-account.pem"
#KUBECONFIGS="encryption-config.yaml kube-scheduler.kubeconfig kube-controller-manager.kubeconfig"
KUBECONFIGS="encryption-config.yaml kube-controller-manager.kubeconfig"
KUBE_DATADIR="/var/lib/kubernetes"
CLUSTER_IP_RANGE="10.32.0.0/24"
BINARY_DIR="/usr/bin"
INTERNAL_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

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

lock_simultaneus_boostrap() {
    # A distributed sleep lock, to avoid simoultaneus cluster initializations

    if [ $LOCK_SB == 1 ]; then
        log "INFO: Simultaneus bootstrap lock: active."
        #Sleep at max 49.999 sec
        sleep $(( ${RANDOM:0:2} / 2 ))
    else
        log "WARNING: Simultaneus bootstrap lock: disabled."
    fi
}

generate_etcd_addresses() {
    # Generate Initial Cluster string
    # e.g.: https://10.240.0.10:2379,https://10.240.0.11:2379,https://10.240.0.12:2379

    MEMBERS=(${CONTROLLERS})
    cn=0
    for IP in ${MEMBERS[@]}; do 
        [[ $IP == ${MEMBERS[0]} ]] && \
            EA="https://$IP:2379" || \
            EA=${EA}",https://$IP:2379"; 
        cn=$((cn + 1));
    done
    #
    etcd_addresses=${EA}
}

apiserver_service() {
    # Create the systemd service for kube-api

    log "INFO: Creating kube-apiserver.service"

    cat <<EOF | sed 's/    //' | sudo tee /etc/systemd/system/kube-apiserver.service
    [Unit]
    Description=Kubernetes API Server
    Documentation=https://github.com/kubernetes/kubernetes

    [Service]
    ExecStart=${BINARY_DIR}/kube-apiserver \\
    --advertise-address=${INTERNAL_IP} \\
    --allow-privileged=true \\
    --apiserver-count=3 \\
    --audit-log-maxage=30 \\
    --audit-log-maxbackup=3 \\
    --audit-log-maxsize=100 \\
    --audit-log-path=/var/log/audit.log \\
    --authorization-mode=Node,RBAC \\
    --bind-address=0.0.0.0 \\
    --client-ca-file=${KUBE_DATADIR}/ca.pem \\
    --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
    --etcd-cafile=${KUBE_DATADIR}/ca.pem \\
    --etcd-certfile=${KUBE_DATADIR}/kubernetes.pem \\
    --etcd-keyfile=${KUBE_DATADIR}/kubernetes-key.pem \\
    --etcd-servers=${etcd_addresses} \\
    --event-ttl=1h \\
    --encryption-provider-config=${KUBE_DATADIR}/encryption-config.yaml \\
    --kubelet-certificate-authority=${KUBE_DATADIR}/ca.pem \\
    --kubelet-client-certificate=${KUBE_DATADIR}/kubernetes.pem \\
    --kubelet-client-key=${KUBE_DATADIR}/kubernetes-key.pem \\
    --kubelet-https=true \\
    --runtime-config=api/all \\
    --service-account-key-file=${KUBE_DATADIR}/service-account.pem \\
    --service-cluster-ip-range=${CLUSTER_IP_RANGE} \\
    --service-node-port-range=30000-32767 \\
    --tls-cert-file=${KUBE_DATADIR}/kubernetes.pem \\
    --tls-private-key-file=${KUBE_DATADIR}/kubernetes-key.pem \\
    --v=2
    Restart=on-failure
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
EOF

}

controller_manager_service() {
    # Create the systemd service for kube-api

    log "INFO: Creating kube-controller-manager.service"

    cat <<EOF | sed 's/    //' | sudo tee /etc/systemd/system/kube-controller-manager.service
    [Unit]
    Description=Kubernetes Controller Manager
    Documentation=https://github.com/kubernetes/kubernetes

    [Service]
    ExecStart=/usr/bin/kube-controller-manager \\
    --address=0.0.0.0 \\
    --cluster-cidr=${VPC_CIDR} \\
    --cluster-name=kubernetes \\
    --cluster-signing-cert-file=${KUBE_DATADIR}/ca.pem \\
    --cluster-signing-key-file=${KUBE_DATADIR}/ca-key.pem \\
    --kubeconfig=${KUBE_DATADIR}/kube-controller-manager.kubeconfig \\
    --leader-elect=true \\
    --root-ca-file=${KUBE_DATADIR}/ca.pem \\
    --service-account-private-key-file=${KUBE_DATADIR}/service-account-key.pem \\
    --service-cluster-ip-range=${CLUSTER_IP_RANGE} \\
    --use-service-account-credentials=true \\
    --v=2
    Restart=on-failure
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
EOF

}

reload_services() {
    # Enable and reload systemd \
    #   control plane services

    log "INFO: enable and reload control plane services"
    systemctl daemon-reload
    systemctl enable kube-apiserver.service \
        kube-controller-manager.service
}

boostrap() {
    # Main function to run and bootstrap the Kuberentes control_plane

    init_checks
    lock_simultaneus_boostrap

    log "INFO: Downloading packages..."
    for KP in ${KUBE_PACKAGES[@]}; do
        curl -O -L ${KP}
        chmod +x ${KP##*/}
        mv ${KP##*/} ${BINARY_DIR}
    done

    mkdir -p ${KUBE_DATADIR}

    log "INFO: Moving certificates to the kube datadir..."
    mv  ${CERTIFICATES} ${KUBECONFIGS} ${KUBE_DATADIR}/
    
    generate_etcd_addresses
    apiserver_service
    controller_manager_service
    reload_services

    log "INFO: starting kube-apiserver"
    systemctl start kube-apiserver.service

    log "INFO: starting kube-controller-manager"
    systemctl start kube-controller-manager.service

}

boostrap
