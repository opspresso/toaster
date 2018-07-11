#!/bin/bash

NAME=$1
REGION=$2
OUTPUT=$3

ANSWER=

ENV_DIR=

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

    LS=$(ls -m ${ENV_DIR})

    #figlet env
    echo "================================================================================"
    echo "   ___ _ ____   __ "
    echo "  / _ \ '_ \ \ / / "
    echo " |  __/ | | \ V / "
    echo "  \___|_| |_|\_/  by nalbam (${VER}) "
    echo "================================================================================"
    echo " Usage: env.sh {NAME} {REGION} {OUTPUT}"
    echo "  NAME  : ${LS}"
    echo "  REGION: ap-northeast-2"
    echo "  OUTPUT: json"
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
    USER=${USER:=$(whoami)}

    pushd ~
    DEFAULT="$(pwd)/work/src/github.com/${USER}/keys/credentials"
    popd

    if [ -z "${ENV_DIR}" ] || [ ! -d "${ENV_DIR}" ]; then
        question "Please input credentials directory."
        ENV_DIR=${ANSWER:-${DEFAULT}}
    fi

    if [ ! -d "${ENV_DIR}" ]; then
        error "[${ENV_DIR}] is not directory."
    fi

    echo "ENV_DIR=${ENV_DIR}" > "${CONFIG}"
}

deploy() {
    if [ -z "${NAME}" ]; then
        usage
    fi
    if [ ! -f "${ENV_DIR}/${NAME}" ]; then
        usage
    fi

    REGION=${REGION:-ap-northeast-2}
    OUTPUT=${OUTPUT:-json}

    cp -rf ${ENV_DIR}/${NAME} ~/.aws/credentials

    aws configure set default.region ${REGION}
    aws configure set default.output ${OUTPUT}

    success "=> ${NAME} ${REGION} ${OUTPUT}"
}

################################################################################

prepare

directory

deploy
