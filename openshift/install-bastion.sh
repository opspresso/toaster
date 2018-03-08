#!/bin/bash

SHELL_DIR=$(dirname "$0")

bastion_public_ip=${bastion_public_ip:=""}
master_public_ip=${master_public_ip:=""}
node1_public_ip=${node1_public_ip:=""}
node2_public_ip=${node2_public_ip:=""}

sudo yum update -y
sudo yum install -y git wget docker gettext httpd-tools

sudo service docker start
sudo chkconfig docker on

which ansible || pip install -Iv ansible

[ ! -d openshift-ansible ] && git clone https://github.com/openshift/openshift-ansible.git

pushd openshift-ansible
git fetch && git checkout release-3.7
popd

if [ "${master_public_ip}" != "" ]; then
    ssh -o "StrictHostKeyChecking=no" ${master_public_ip} < ${SHELL_DIR}/install-master.sh
fi

if [ "${node1_public_ip}" != "" ]; then
    ssh -o "StrictHostKeyChecking=no" ${node1_public_ip} < ${SHELL_DIR}/install-node.sh
fi

if [ "${node1_public_ip}" != "" ]; then
    ssh -o "StrictHostKeyChecking=no" ${node1_public_ip} < ${SHELL_DIR}/install-node.sh
fi
