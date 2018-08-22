#!/bin/bash

PEM=$1
HOST=$2
USER=$3

ANSWER=

HOME_DIR=

SHELL_DIR=${HOME}/helper

################################################################################

question() {
    read -p "$(tput setaf 6)$@$(tput sgr0)" ANSWER
}

title() {
    echo -e "$(tput setaf 3)$@$(tput sgr0)"
}

success() {
    echo -e "$(tput setaf 2)$@$(tput sgr0)"
    exit 0
}

error() {
    echo -e "$(tput setaf 1)$@$(tput sgr0)"
    exit 1
}

usage() {
    LS=$(ls -m ${HOME_DIR})

    #figlet ssh
    echo "================================================================================"
    echo "          _ "
    echo "  ___ ___| |__ "
    echo " / __/ __| '_ \ "
    echo " \__ \__ \ | | | "
    echo " |___/___/_| |_| "
    echo "================================================================================"
    echo " Usage: ssh.sh {PEM} {HOST} {USER}"
    echo "  NAME: ${LS}"
    echo "  HOST: hostname"
    echo "  USER: ec2-user"
    echo "================================================================================"
    echo "  PATH: ${HOME_DIR}"
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
    if [ -z "${HOME_DIR}" ] || [ ! -d "${HOME_DIR}" ]; then
        USER=${USER:=$(whoami)}

        pushd ~
        DEFAULT="$(pwd)/work/src/github.com/${USER}/keys/pem"
        popd

        question "Please input pem directory. [${DEFAULT}]: "
        HOME_DIR=${ANSWER:-${DEFAULT}}
    fi

    if [ -z "${HOME_DIR}" ] || [ ! -d "${HOME_DIR}" ]; then
        error "[${HOME_DIR}] is not directory."
    fi

    chmod 600 ${HOME_DIR}/*.pem

    echo "HOME_DIR=${HOME_DIR}" > "${CONFIG}"

    echo "Host * " > ~/.ssh/config
    echo "    StrictHostKeyChecking no " >> ~/.ssh/config

    echo "" > ~/.ssh/known_hosts
}

connect() {
    if [ "${PEM}" == "" ]; then
        PEM="nalbam"
    fi
    if [ ! -f "${HOME_DIR}/${PEM}" ]; then
        PEM="${PEM}.pem"
    fi
    if [ ! -f "${HOME_DIR}/${PEM}" ]; then
        usage
    fi

    if [ "${HOST}" == "" ]; then
        error "Please input hostname or ip."
    fi

    if [ "${USER}" == "" ]; then
        USER="ec2-user"
    fi

    ssh -i ${HOME_DIR}/${PEM} ${USER}@${HOST}
}

################################################################################

prepare

directory

connect
