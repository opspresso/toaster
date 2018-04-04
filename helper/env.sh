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

SHELL_DIR=$(dirname "$0")

ENV_DIR=

NAME=$1
REGION=$2
OUTPUT=$3

CONFIG=${SHELL_DIR}/.env
if [ -f ${CONFIG} ]; then
    . ${CONFIG}
fi

################################################################################

directory() {
    if [ "${ENV_DIR}" == "" ] || [ ! -d "${ENV_DIR}" ]; then
        echo "Please input credentials directory. (ex: ~/keys/credentials)"
        read ENV_DIR
    fi

    if [ "${ENV_DIR}" == "" ]; then
        error "[${ENV_DIR}] is empty."
    fi
    if [ ! -d "${ENV_DIR}" ]; then
        error "[${ENV_DIR}] is not directory."
    fi

    echo "ENV_DIR=${ENV_DIR}" > "${CONFIG}"
}

deploy() {
    if [ "${NAME}" == "" ]; then
        usage
    fi
    if [ ! -f "${ENV_DIR}/${NAME}" ]; then
        usage
    fi

    if [ "${REGION}" == "" ] || [ "${REGION}" == "seoul" ]; then
        REGION="ap-northeast-2"
    fi
    if [ "${OUTPUT}" == "" ]; then
        OUTPUT="json"
    fi

    if [ ! -d ~/.aws ]; then
      mkdir -p ~/.aws
    fi

    cp -rf ${ENV_DIR}/${NAME} ~/.aws/credentials

    aws configure set default.region ${REGION}
    aws configure set default.output ${OUTPUT}

    success "=> ${NAME} ${REGION} ${OUTPUT}"
}

################################################################################

directory

deploy
