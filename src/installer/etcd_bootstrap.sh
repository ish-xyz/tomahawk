#!/bin/bash
##
## Bootstrap etcd script

set -e

ETCD_URL="https://github.com/etcd-io/etcd/releases/download/v3.4.0/etcd-v3.4.0-linux-amd64.tar.gz"

trap "rm -rf ${ETCD_URL##*/}  ./$(echo ${ETCD_URL##*/} | sed 's/\.tar\.gz//')" EXIT SIGTERM SIGKILL SIGINT

log() {
    echo "$(date +"%m-%d-%Y::%H:%M:%S") ${1}"
}

install() {
    log "INFO: downloading etcd..."
    if [[ -z $(which curl) ]]; then
        log "ERROR: you must install curl to run this script."
    fi

    curl -O -L ${ETCD_URL} && tar -xvf ${ETCD_URL##*/}
    if [[ $? != 0 ]]; then
        log "ERROR: etcd download failed."
    fi

    log "INFO: installing etcd..."
    mv $(echo ${ETCD_URL##*/} | sed 's/\.tar\.gz//')/etcd* /usr/local/bin

    #create unit-file
}

install
