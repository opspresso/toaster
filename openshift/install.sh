#!/bin/bash

export SHELL_DIR=$(dirname "$0")

export DOMAIN=${DOMAIN:="$(curl ipinfo.io/ip).nip.io"}
export USERNAME=${USERNAME:="$(whoami)"}
export PASSWORD=${PASSWORD:=password}
export VERSION=${VERSION:="v3.7.1"}
export DISK=${DISK:=""}

export MASTER_IP="$(ip route get 8.8.8.8 | awk '{print $NF; exit}')"

export REPO_URL="http://repo.toast.sh/openshift"

export METRICS="True"
export LOGGING="True"

MEMORY=$(cat /proc/meminfo | grep MemTotal | sed "s/MemTotal:[ ]*\([0-9]*\) kB/\1/")

if [ "$MEMORY" -lt "4194304" ]; then
    export METRICS="False"
fi

if [ "$MEMORY" -lt "8388608" ]; then
    export LOGGING="False"
fi

install_dependency() {
    #sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    #sudo yum-config-manager --enable epel

    sudo yum install -y git nano wget zip zile net-tools docker \
         python-cryptography python-passlib python-devel python-pip pyOpenSSL.x86_64 \
         openssl-devel httpd-tools java-1.8.0-openjdk-headless NetworkManager \
         "@Development Tools"

    sudo systemctl | grep "NetworkManager.*running"
    if [ $? -eq 1 ]; then
        sudo systemctl start NetworkManager
        sudo systemctl enable NetworkManager
    fi
}

install_ansible() {
    which ansible || sudo pip install -Iv ansible

    [ ! -d openshift-ansible ] && git clone https://github.com/openshift/openshift-ansible.git

    pushd openshift-ansible
    git fetch && git checkout release-3.7
    popd
}

install_openshift() {
    build_inventory

    ansible-playbook -i inventory.ini openshift-ansible/playbooks/byo/config.yml

    sudo htpasswd -b /etc/origin/master/htpasswd ${USERNAME} ${PASSWORD}

    oc adm policy add-cluster-role-to-user cluster-admin ${USERNAME}

    sudo systemctl restart origin-master-api
}

start_docker() {
    if [ -z ${DISK} ]; then
        echo "Not setting the Docker storage."
    else
        sudo cp /etc/sysconfig/docker-storage-setup /etc/sysconfig/docker-storage-setup.bk

        sudo echo DEVS=${DISK} > /etc/sysconfig/docker-storage-setup
        sudo echo VG=DOCKER >> /etc/sysconfig/docker-storage-setup
        sudo echo SETUP_LVM_THIN_POOL=yes >> /etc/sysconfig/docker-storage-setup
        sudo echo DATA_SIZE="100%FREE" >> /etc/sysconfig/docker-storage-setup

        sudo systemctl stop docker

        sudo rm -rf /var/lib/docker
        sudo wipefs --all ${DISK}
        sudo docker-storage-setup
    fi

    sudo systemctl restart docker
    sudo systemctl enable docker
}

build_config() {
    cat ${SHELL_DIR}/config > ~/.ssh/config
    chmod 600 ~/.ssh/config
}

build_hosts() {
    envsubst < ${SHELL_DIR}/hosts > /tmp/hosts
    sudo cp -rf /tmp/hosts /etc/hosts
}

build_inventory() {
    envsubst < ${SHELL_DIR}/inventory > inventory.ini

    if [ ! -f inventory.ini ]; then
        echo "inventory.ini is missing!"
        exit 1
    fi
}

echo "**********"
echo "* Your domain is $DOMAIN "
echo "* Your username is $USERNAME "
echo "* Your password is $PASSWORD "
echo "*"
echo "* OpenShift version: $VERSION "
echo "**********"

install_dependency

install_ansible

build_config

build_hosts

start_docker

install_openshift

echo "**********"
echo "* Your console is https://console.$DOMAIN:8443/"
echo "* Your username is $USERNAME "
echo "* Your password is $PASSWORD "
echo "*"
echo "* OpenShift version: $VERSION "
echo "*"
echo "* Login using:"
echo "*"
echo "$ oc login -u ${USERNAME} -p ${PASSWORD} https://console.$DOMAIN:8443/"
echo "**********"

oc login -u ${USERNAME} -p ${PASSWORD} https://console.${DOMAIN}:8443/
