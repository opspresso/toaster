#!/bin/bash

PEM=$1
HOST=$2
USER=$3

ANSWER=

SSH_DIR=

SHELL_DIR=$(dirname $(dirname "$0"))

################################################################################

question() {
    read -p "$(tput setaf 6)$@$(tput sgr0)" ANSWER
}

success() {
    tput setaf 2
    echo -e "$@"
    tput sgr0
    exit 0
}

error() {
    tput setaf 1
    echo -e "$@"
    tput sgr0
    exit 1
}

usage() {
    if [ -r ${SHELL_DIR}/conf/ver.now ]; then
        VER="$(cat ${SHELL_DIR}/conf/ver.now)"
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
    echo "  HOST: hostname"
    echo "  USER: ec2-user"
    echo "================================================================================"

    exit 1
}

################################################################################

prepare() {
    mkdir -p ${SHELL_DIR}/conf

    CONFIG=${SHELL_DIR}/conf/$(basename $0)
    if [ -f ${CONFIG} ]; then
        . ${CONFIG}
    fi
}

directory() {
    if [ -z "${SSH_DIR}" ] || [ ! -d "${SSH_DIR}" ]; then
        USER=${USER:=$(whoami)}

        pushd ~
        DEFAULT="$(pwd)/work/src/github.com/${USER}/keys/pem"
        popd

        question "Please input pem directory. [${DEFAULT}]: "
        SSH_DIR=${ANSWER:-${DEFAULT}}
    fi

    if [ -z "${SSH_DIR}" ] || [ ! -d "${SSH_DIR}" ]; then
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

prepare

directory

connect
