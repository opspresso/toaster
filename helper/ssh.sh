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
    LS=$(ls -m ${DIR})

    if [ -r /tmp/toaster.old ]; then
        VER="$(cat /tmp/nsh.old)"
    else
        VER="0"
    fi

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

DIR=

PEM=$1
HOST=$2
USER=$3

SHELL_DIR=$(dirname "$0")

CONFIG=${SHELL_DIR}/.ssh
if [ -f "${CONFIG}" ]; then
    . "${CONFIG}"
fi

################################################################################

directory() {
    if [ "${DIR}" == "" ] || [ ! -d "${DIR}" ]; then
        echo "Please input pem directory. (ex: ~/pem)"
        read DIR
    fi

    if [ "${DIR}" == "" ]; then
        error "[${DIR}] is empty."
    fi
    if [ ! -d "${DIR}" ]; then
        error "[${DIR}] is not directory."
    fi

    echo "DIR=${DIR}" >> "${CONFIG}"
}

connect() {
    if [ "${PEM}" == "" ]; then
        PEM="nalbam"
    fi
    if [ ! -f "${DIR}/${PEM}" ]; then
        PEM="${PEM}.pem"
    fi
    if [ ! -f "${DIR}/${PEM}" ]; then
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

    ssh -i ${DIR}/${PEM} ${USER}@${HOST}
}

################################################################################

directory

connect
