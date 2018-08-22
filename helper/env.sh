#!/bin/bash

NAME=$1
REGION=$2
OUTPUT=$3

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
    mkdir -p ~/.aws

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
        DEFAULT="$(pwd)/work/src/github.com/${USER}/keys/credentials"
        popd

        question "Please input credentials directory. [${DEFAULT}]: "
        HOME_DIR=${ANSWER:-${DEFAULT}}
    fi

    if [ -z "${HOME_DIR}" ] || [ ! -d "${HOME_DIR}" ]; then
        error "[${HOME_DIR}] is not directory."
    fi

    echo "HOME_DIR=${HOME_DIR}" > "${CONFIG}"
}

deploy() {
    if [ -z "${NAME}" ]; then
        usage
    fi
    if [ ! -f "${HOME_DIR}/${NAME}" ]; then
        usage
    fi

    REGION=${REGION:-ap-northeast-2}
    OUTPUT=${OUTPUT:-json}

    aws configure set default.region ${REGION}
    aws configure set default.output ${OUTPUT}

    cp -f ${HOME_DIR}/${NAME} ~/.aws/credentials

    success "=> ${NAME} ${REGION} ${OUTPUT}"
}

################################################################################

prepare

directory

deploy
