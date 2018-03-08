#!/bin/bash

SHELL_DIR=$(dirname "$0")

config=".openshift"
if [ -f ${config} ]; then
    source ${config}
fi

export bastion_public_ip=${bastion_public_ip:=""}
export master_public_ip=${master_public_ip:=""}
export node1_public_ip=${node1_public_ip:=""}
export node2_public_ip=${node2_public_ip:=""}

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

chmod 600 ~/.ssh/id_rsa

if [ "${master_public_ip}" != "" ]; then
    echo "********** master **********"
    scp ${SHELL_DIR}/install-master.sh ${master_public_ip}:~
    ssh -t ${master_public_ip} ~/install-master.sh
    echo "********** master **********"
fi

if [ "${node1_public_ip}" != "" ]; then
    echo "********** node1 **********"
    scp ${SHELL_DIR}/install-master.sh ${node1_public_ip}:~
    ssh -t ${node1_public_ip} ~/install-master.sh
    echo "********** node1 **********"
fi

if [ "${node2_public_ip}" != "" ]; then
    echo "********** node2 **********"
    scp ${SHELL_DIR}/install-master.sh ${node2_public_ip}:~
    ssh -t ${node2_public_ip} ~/install-master.sh
    echo "********** node2 **********"
fi
