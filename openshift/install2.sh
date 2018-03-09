#!/bin/bash

if [ "${HOME}" != "/root" ]; then
    echo "Please run as root."
    exit 1
fi

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
    #rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    #yum-config-manager --enable epel

    yum install -y git nano wget zip zile net-tools docker \
        python-cryptography python-passlib python-devel python-pip pyOpenSSL.x86_64 \
        openssl-devel httpd-tools NetworkManager java-1.8.0-openjdk-headless \
        "@Development Tools"

#    if ! command -v docker > /dev/null; then
#        #wget -qO- https://get.docker.com/ | sh
#        yum-config-manager --enable rhui-REGION-rhel-server-extras
#        yum install -y docker
#    fi

    systemctl | grep "NetworkManager.*running"
    if [ $? -eq 1 ]; then
        systemctl start NetworkManager
        systemctl enable NetworkManager
    fi
}

install_ansible() {
    which ansible || pip install -Iv ansible

    [ ! -d openshift-ansible ] && git clone https://github.com/openshift/openshift-ansible.git

    pushd openshift-ansible
    git fetch && git checkout release-3.7
    popd
}

install_openshift() {
    build_inventory

    ansible-playbook -i inventory.ini openshift-ansible/playbooks/byo/config.yml

    htpasswd -b /etc/origin/master/htpasswd ${USERNAME} ${PASSWORD}
    oc adm policy add-cluster-role-to-user cluster-admin ${USERNAME}

    systemctl restart origin-master-api
}

start_docker() {
    if [ -z ${DISK} ]; then
        echo "Not setting the Docker storage."
    else
        cp /etc/sysconfig/docker-storage-setup /etc/sysconfig/docker-storage-setup.bk

        echo DEVS=${DISK} > /etc/sysconfig/docker-storage-setup
        echo VG=DOCKER >> /etc/sysconfig/docker-storage-setup
        echo SETUP_LVM_THIN_POOL=yes >> /etc/sysconfig/docker-storage-setup
        echo DATA_SIZE="100%FREE" >> /etc/sysconfig/docker-storage-setup

        systemctl stop docker

        rm -rf /var/lib/docker
        wipefs --all ${DISK}
        docker-storage-setup
    fi

    systemctl restart docker
    systemctl enable docker
}

build_hosts() {
    envsubst < ${SHELL_DIR}/hosts > /etc/hosts
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
