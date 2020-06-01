#! /bin/bash
#
# Bootstrap Kubernetes Workers
## NOTE:
##  1) Must be executed as root! **
##  2) All the variables with $ (e.g.: S{content}) are \
##     terraform template variables \
##     the others (e.g.: SS{content}) are normal BASH variables

set -e
declare -A kube_packages

#Config directories
execdir="/usr/bin"
cnidir="/opt/cni/bin"
bootstrap_dir="/bootstrap"
kubelet_confdir="/var/lib/kubelet"
kubeproxy_confdir="/var/lib/kube-proxy"
kube_confdir="/var/lib/kubernetes"
containerd_confdir="/etc/containerd/"

#Config files
ca_cert_filename="$${kube_confdir}/ca.pem"
ca_key_filename="ca-key.pem"
worker_cert="$${kubelet_confdir}/worker.pem"
worker_key="$${kubelet_confdir}/worker-key.pem"
kubeproxy_config="$${kubeproxy_confdir}/kubeconfig"
kubeproxy_config_ext="$${kubeproxy_confdir}/kube-proxy-config.yaml"
kubelet_config="$${kubelet_confdir}/kubeconfig"
kubelet_config_ext="$${kubelet_confdir}/kubelet-config.yaml"

#Instance Metadata
lock_sb=1
metadata="http://169.254.169.254/latest/meta-data"
instance_mac=$(curl -s $${metadata}/network/interfaces/macs/ | head -n1 | tr -d '/')

#Packages to verify, download and/or install
required_cmds=("yum" "tar")
install_packages=("curl" "socat" "conntrack" "ipset")

kube_packages=(
    ["https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz"]="$${cnidir}" \
    ["https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.15.0/crictl-v1.15.0-linux-amd64.tar.gz"]="$${execdir}/" \
    ["https://github.com/containerd/containerd/releases/download/v1.2.9/containerd-1.2.9.linux-amd64.tar.gz"]="/bin/" \
    ["https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl"]="$${execdir}/kubectl" \
    ["https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-proxy"]="$${execdir}/kube-proxy" \
    ["https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubelet"]="$${execdir}/kubelet" \
    ["https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64"]="$${execdir}/runc"
)

log() {
    # Logging function

    echo "$(date +"%m-%d-%Y::%H:%M:%S") $${1}" | tee -a /bootstrap.log
}

init_checks() {
    # pre-bootstrap checks

    log "INFO: Checking requirements..."
    for cmd in $${required_cmds[@]}; do
        if [[ -z $(which $${cmd}) ]]; then
            log "ERROR: you must have $${cmd} installed to run this script."
            exit 1
        fi
    done
}

prepare() {
    # Prepare the machine:
    #   Download binaries
    #   Create config directories
    #   Disable swap

    log "INFO: Create required directories"
    mkdir -p $${bootstrap_dir}/cmd \
        $${cnidir} \
        $${kubeproxy_confdir} \
        $${kube_confdir} \
        $${kubelet_confdir} \
        $${containerd_confdir} \
        /var/run/kubernetes

    log "INFO: install required packages..."
    yum install -y $${install_packages[@]}

    log "INFO: Disable swap."
    if [[ -n $(swapon --show) ]]; then
        swapoff -a
    fi

    cd $${bootstrap_dir}/cmd
    for pkg in $${!kube_packages[@]}; do
        log "INFO: installing $${pkg##*/} in  -> $${kube_packages[$${pkg}]}"

        curl -O -L $${pkg}
        if [[ "$${pkg##*.}" =~ gz|tar ]]; then
            mkdir "$${pkg##*/}-ext"
            tar -xvf $${pkg##*/} -C $${pkg##*/}-ext
            find $${bootstrap_dir}/cmd/$${pkg##*/}-ext -type f -exec chmod +x {} \;
            find $${bootstrap_dir}/cmd/$${pkg##*/}-ext -type f -exec mv {} $${kube_packages[$${pkg}]} \;
            continue
        fi
        chmod +x $${pkg##*/} && \
        mv $${pkg##*/} $${kube_packages[$${pkg}]} 
    done
    cd $${bootstrap_dir}
}

configure_containerd() {
    # Configure containerd

    log "INFO: Configure contained"
    cat << EOF | sed 's/        //' | tee $${containerd_confdir}/config.toml
        [plugins]
          [plugins.cri.registry.mirrors]
            [plugins.cri.registry.mirrors."docker.io"]
              endpoint = ["https://registry-1.docker.io"]
          [plugins.cri.containerd]
            snapshotter = "overlayfs"
            [plugins.cri.containerd.default_runtime]
              runtime_type = "io.containerd.runtime.v1.linux"
              runtime_engine = "$${execdir}/runc"
              runtime_root = ""
EOF

    log "INFO: Create containerd systemd service"
    cat <<EOF | sed 's/        //' | tee /etc/systemd/system/containerd.service
        [Unit]
        Description=containerd container runtime
        Documentation=https://containerd.io
        After=network.target

        [Service]
        ExecStartPre=/sbin/modprobe overlay
        ExecStart=/bin/containerd
        Restart=always
        RestartSec=5
        Delegate=yes
        KillMode=process
        OOMScoreAdjust=-999
        LimitNOFILE=1048576
        LimitNPROC=infinity
        LimitCORE=infinity

        [Install]
        WantedBy=multi-user.target
EOF
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

generate_certificates() {
    # Create and sign a certificate for the new worker

    log "INFO: Create CA files..."
    cat <<EOF | sed '$d' | tee $${ca_cert_filename}
${CA_CERT}
EOF
    cat <<EOF | sed '$d' | tee $${ca_key_filename}
${CA_KEY}
EOF
    log "INFO: Create and sign certificate"
    openssl genrsa -out $${worker_key} 2048
    openssl req -new -key $${worker_key} -out worker.csr \
        -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCATION}/O=${ORG}/OU=${OU}/CN=${CN}:$(hostname -f)"

    cat <<EOF | sed 's/    //' | tee worker.ext
    authorityKeyIdentifier=keyid,issuer
    basicConstraints=CA:FALSE
    keyUsage = digitalSignature, keyEncipherment
    extendedKeyUsage = serverAuth, clientAuth
    subjectAltName = @alt_names

    [alt_names]
    DNS.1 = $(curl http://169.254.169.254/latest/meta-data/local-ipv4)
    DNS.2 = $(hostname -f)
EOF

    openssl x509 -req -in worker.csr -CA $${ca_cert_filename} \
        -CAkey $${ca_key_filename} \
        -CAcreateserial \
        -out $${worker_cert} \
        -days ${CERT_VALIDITY} \
        -sha256 -extfile worker.ext
}

configure_kubelet() {
    #Configure Kubelet

    log "INFO: Configure Kubelet"
    cat <<EOF | sed 's/    //' | tee $${kubelet_config}
    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority-data: $(cat $${ca_cert_filename} | base64 -w 0)
        server: ${KUBE_ADDRESS}
      name: ${PROJECT_NAME}
    contexts:
    - context:
        cluster: ${PROJECT_NAME}
        user: system:node:$(hostname -f)
      name: default
    current-context: default
    kind: Config
    preferences: {}
    users:
    - name: system:node:$(hostname -f)
      user:
        client-certificate-data: $(cat $${worker_cert} | base64 -w 0)
        client-key-data: $(cat $${worker_key} | base64 -w 0)
EOF

    cat <<EOF | sed 's/        //'| tee $${kubelet_config_ext}
        kind: KubeletConfiguration
        apiVersion: kubelet.config.k8s.io/v1beta1
        authentication:
          anonymous:
            enabled: false
          webhook:
            enabled: true
          x509:
            clientCAFile: "$${ca_cert_filename}"
        authorization:
          mode: Webhook
        clusterDomain: "cluster.local"
        clusterDNS:
          - "${DNS_ADDRESS}"
        podCIDR: "${POD_CIDR}"
        resolvConf: "/run/NetworkManager/resolv.conf"
        runtimeRequestTimeout: "15m"
        tlsCertFile: "$${worker_cert}"
        tlsPrivateKeyFile: "$${worker_key}"
EOF

    log "INFO: Create Kubelet systemd service"
    cat <<EOF | sed 's/        //'| tee /etc/systemd/system/kubelet.service
        [Unit]
        Description=Kubernetes Kubelet
        Documentation=https://github.com/kubernetes/kubernetes
        After=containerd.service
        Requires=containerd.service

        [Service]
        ExecStart=$${execdir}/kubelet \\
            --config=$${kubelet_config_ext} \\
            --container-runtime=remote \\
            --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
            --image-pull-progress-deadline=2m \\
            --kubeconfig=$${kubelet_config} \\
            --network-plugin=cni \\
            --register-node=true \\
            --v=2
        Restart=on-failure
        RestartSec=5

        [Install]
        WantedBy=multi-user.target
EOF
}

configure_kubeproxy() {
    #Configure Kube proxy

    log "INFO: Configure Kube Proxy"
    cat <<EOF | sed '$d' | tee $${kubeproxy_config}
${KUBECONFIG_PROXY}
EOF

    cat <<EOF | sed 's/        //' | tee $${kubeproxy_config_ext}
        kind: KubeProxyConfiguration
        apiVersion: kubeproxy.config.k8s.io/v1alpha1
        clientConnection:
          kubeconfig: "$${kubeproxy_config}"
        mode: "iptables"
        clusterCIDR: ${POD_CIDR}
EOF

    log "INFO: Create Kube Proxy systemd service"
    cat <<EOF | sed 's/        //' | tee /etc/systemd/system/kube-proxy.service
        [Unit]
        Description=Kubernetes Kube Proxy
        Documentation=https://github.com/kubernetes/kubernetes

        [Service]
        ExecStart=$${execdir}/kube-proxy \\
            --config=$${kubeproxy_config_ext}
        Restart=on-failure
        RestartSec=5

        [Install]
        WantedBy=multi-user.target
EOF
}

configure_resolv_conf() {

    log "INFO: Configure /etc/resolv.conf with Google Nameservers"
    cat <<EOF | sed 's/        //' | tee /etc/resolv.conf
        nameserver 8.8.8.8
        nameserver 8.8.4.4
        nameserver $(cat /etc/resolv.conf | grep nameserver | awk {'print $2'} | tail -n1)
EOF

}

reload_services() {
    # Enable & Reload Services

    log "INFO: Enable & Reload Services"
    systemctl daemon-reload
    systemctl enable containerd kubelet kube-proxy
}

bootstrap() {

    init_checks
    prepare
    configure_resolv_conf
    lock_simultaneus_boostrap
    generate_certificates

    configure_containerd
    configure_kubelet
    configure_kubeproxy
    #configure_graceful_shutdown
    #configure_hostname
    reload_services

    log "INFO: starting containerd..."
    systemctl start containerd
    log "INFO: starting Kubelet..."
    systemctl start kubelet
    log "INFO: starting Kube Proxy..."
    systemctl start kube-proxy

    
}

bootstrap
