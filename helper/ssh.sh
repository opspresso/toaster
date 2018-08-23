#!/bin/bash

SHELL_DIR=${HOME}/helper

HOME_DIR=

_PEM=${1:-$USER}
_HOST=${2}
_USER=${3:-ec2-user}

################################################################################

command -v tput > /dev/null || TPUT=false

_echo() {
    if [ -z ${TPUT} ] && [ ! -z $2 ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
    fi
}

_read() {
    if [ -z ${TPUT} ]; then
        read -p "$(tput setaf 6)$1$(tput sgr0)" ANSWER
    else
        read -p "$1" ANSWER
    fi
}

_result() {
    _echo "# $@" 4
}

_command() {
    _echo "$ $@" 3
}

_success() {
    _echo "+ $@" 2
    exit 0
}

_error() {
    _echo "- $@" 1
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
        pushd ~
        DEFAULT="$(pwd)/work/src/github.com/${USER}/keys/pem"
        popd

        _read "Please input pem directory. [${DEFAULT}]: "
        HOME_DIR=${ANSWER:-${DEFAULT}}
    fi

    if [ -z "${HOME_DIR}" ] || [ ! -d "${HOME_DIR}" ]; then
        _error "[${HOME_DIR}] is not directory."
    fi

    chmod 600 ${HOME_DIR}/*.pem

    echo "HOME_DIR=${HOME_DIR}" > "${CONFIG}"

    echo "Host * " > ~/.ssh/config
    echo "    StrictHostKeyChecking no " >> ~/.ssh/config

    echo "" > ~/.ssh/known_hosts
}

connect() {
    if [ ! -f ${HOME_DIR}/${_PEM} ]; then
        _PEM="${_PEM}.pem"
        if [ ! -f ${HOME_DIR}/${_PEM} ]; then
            usage
        fi
    fi

    if [ -z ${_HOST} ]; then
        _error "Please input hostname or ip."
    fi

    _command "ssh -i ${HOME_DIR}/${_PEM} ${_USER}@${_HOST}"
    ssh -i ${HOME_DIR}/${_PEM} ${_USER}@${_HOST}
}

################################################################################

prepare

directory

connect
