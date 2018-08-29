#!/bin/bash

SHELL_DIR=${HOME}/helper

HOME_DIR=

_NAME=$1
_REGION=${2:-ap-northeast-2}
_OUTPUT=${3:-json}

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

    #figlet env
    echo "================================================================================"
    echo "   ___ _ ____   __ "
    echo "  / _ \ '_ \ \ / / "
    echo " |  __/ | | \ V / "
    echo "  \___|_| |_|\_/ "
    echo "================================================================================"
    echo " Usage: env.sh {NAME} {REGION} {OUTPUT}"
    echo "  NAME  : ${LS}"
    echo "  REGION: ap-northeast-2"
    echo "  OUTPUT: json"
    echo "================================================================================"
    echo "  PATH  : ${HOME_DIR}"
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
        DEFAULT="$(pwd)/work/src/github.com/${USER}/keys/credentials"
        popd

        _read "Please input credentials directory. [${DEFAULT}]: "
        HOME_DIR=${ANSWER:-${DEFAULT}}
    fi

    if [ -z "${HOME_DIR}" ] || [ ! -d "${HOME_DIR}" ]; then
        _error "[${HOME_DIR}] is not directory."
    fi

    echo "HOME_DIR=${HOME_DIR}" > "${CONFIG}"
}

deploy() {
    if [ -z "${_NAME}" ]; then
        usage
    fi
    if [ ! -f "${HOME_DIR}/${_NAME}" ]; then
        usage
    fi

    aws configure set default.region ${_REGION}
    aws configure set default.output ${_OUTPUT}

    cp -f ${HOME_DIR}/${_NAME} ~/.aws/credentials

    _success "${_NAME} ${_REGION} ${_OUTPUT}"
}

################################################################################

prepare

directory

deploy
