#!/bin/bash

SHELL_DIR=$(dirname "$0")

config=".openshift"
if [ -f ${config} ]; then
    source ${config}
fi

bastion_public_ip=${bastion_public_ip:=""}
master_public_ip=${master_public_ip:=""}
node1_public_ip=${node1_public_ip:=""}
node2_public_ip=${node2_public_ip:=""}

sudo yum update -y
sudo yum install -y git wget gettext httpd-tools

which ansible || sudo pip install -Iv ansible

if [ ! -d openshift-ansible ]; then
    git clone https://github.com/openshift/openshift-ansible.git

    pushd openshift-ansible
    git fetch
    git checkout release-3.7
    popd
fi

if [ "${master_public_ip}" != "" ]; then
    echo "********** master **********"
    ssh -o "StrictHostKeyChecking=no" ${master_public_ip} < ${SHELL_DIR}/install-master.sh
    echo "********** master **********"
fi

if [ "${node1_public_ip}" != "" ]; then
    echo "********** node1 **********"
    ssh -o "StrictHostKeyChecking=no" ${node1_public_ip} < ${SHELL_DIR}/install-node.sh
    echo "********** node1 **********"
fi

if [ "${node2_public_ip}" != "" ]; then
    echo "********** node2 **********"
    ssh -o "StrictHostKeyChecking=no" ${node2_public_ip} < ${SHELL_DIR}/install-node.sh
    echo "********** node2 **********"
fi
