#!/bin/bash

#sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

sudo yum-config-manager --enable epel
sudo yum install -y git nano wget zip zile net-tools docker \
    python-cryptography python-passlib python-devel python-pip pyOpenSSL.x86_64 \
    openssl-devel httpd-tools java-1.8.0-openjdk-headless NetworkManager \
    "@Development Tools"

#if ! command -v docker > /dev/null; then
#    sudo yum-config-manager --enable rhui-REGION-rhel-server-extras
#    sudo yum install -y docker
#fi

sudo systemctl | grep "NetworkManager.*running"
if [ $? -eq 1 ]; then
    sudo systemctl start NetworkManager
    sudo systemctl enable NetworkManager
fi

sudo systemctl start docker
sudo systemctl enable docker
