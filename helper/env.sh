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

    #figlet env
    echo "================================================================================"
    echo "   ___ _ ____   __ "
    echo "  / _ \ '_ \ \ / / "
    echo " |  __/ | | \ V / "
    echo "  \___|_| |_|\_/   by nalbam (${VER}) "
    echo "================================================================================"
    echo " Usage: env.sh {NAME} {REGION} {OUTPUT}"
    echo "  NAME  : ${LS}"
    echo "  REGION: ap-northeast-2"
    echo "  OUTPUT: json"
    echo "================================================================================"

    exit 1
}

################################################################################

DIR=

NAME=$1
REGION=$2
OUTPUT=$3

SHELL_DIR=$(dirname "$0")

CONFIG=${SHELL_DIR}/.env
if [ -f "${CONFIG}" ]; then
    . "${CONFIG}"
fi

################################################################################

directory() {
    if [ "${DIR}" == "" ] || [ ! -d "${DIR}" ]; then
        echo "Please input credentials directory. (ex: ~/credentials)"
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

deploy() {
    if [ "${NAME}" == "" ]; then
        usage
    fi
    if [ ! -f "${DIR}/${NAME}" ]; then
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

    cp -rf ${DIR}/${NAME} ~/.aws/credentials

    aws configure set default.region ${REGION}
    aws configure set default.output ${OUTPUT}

    success ">> ${NAME} ${REGION} ${OUTPUT}"
}

################################################################################

directory

deploy
