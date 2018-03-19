#!/bin/bash

success() {
    echo -e "$(tput setaf 2)$1$(tput sgr0)"
    exit 0
}

error() {
    echo -e "$(tput setaf 1)$1$(tput sgr0)"
    exit 1
}

usage() {
    if [ -r /tmp/toaster.old ]; then
        VER="$(cat /tmp/toaster.old)"
    else
        VER="v3"
    fi

    LS=$(ls -m ${SSH_DIR})

    #figlet ssh
    echo "================================================================================"
    echo "          _ "
    echo "  ___ ___| |__ "
    echo " / __/ __| '_ \ "
    echo " \__ \__ \ | | | "
    echo " |___/___/_| |_|  by nalbam (${VER}) "
    echo "================================================================================"
    echo " Usage: ssh.sh {PEM} {HOST} {USER}"
    echo "  PEM : ${LS}"
    echo "  HOST: hostname.com"
    echo "  USER: ec2-user"
    echo "================================================================================"

    exit 1
}

################################################################################

SHELL_DIR=$(dirname "$0")

SSH_DIR=

PEM=$1
HOST=$2
USER=$3

CONFIG=${SHELL_DIR}/.ssh
if [ -f ${CONFIG} ]; then
    . ${CONFIG}
fi

################################################################################

directory() {
    if [ "${SSH_DIR}" == "" ] || [ ! -d "${SSH_DIR}" ]; then
        echo "Please input pem directory. (ex: ~/keys/pem)"
        read SSH_DIR
    fi

    if [ "${SSH_DIR}" == "" ]; then
        error "[${SSH_DIR}] is empty."
    fi
    if [ ! -d "${SSH_DIR}" ]; then
        error "[${SSH_DIR}] is not directory."
    fi

    chmod 600 ${SSH_DIR}/*.pem

    echo "SSH_DIR=${SSH_DIR}" >> "${CONFIG}"

    echo "Host * " > ~/.ssh/config
    echo "    StrictHostKeyChecking no " >> ~/.ssh/config

    echo "" > ~/.ssh/known_hosts
}

connect() {
    if [ "${PEM}" == "" ]; then
        PEM="nalbam"
    fi
    if [ ! -f "${SSH_DIR}/${PEM}" ]; then
        PEM="${PEM}.pem"
    fi
    if [ ! -f "${SSH_DIR}/${PEM}" ]; then
        usage
    fi

    if [ "${HOST}" == "" ]; then
        error "Please input hostname or ip."
    fi

    if [ "${USER}" == "" ]; then
        USER="ec2-user"
    fi

    if [ ! -d ~/.aws ]; then
      mkdir -p ~/.aws
    fi

    ssh -i ${SSH_DIR}/${PEM} ${USER}@${HOST}
}

################################################################################

directory

connect
