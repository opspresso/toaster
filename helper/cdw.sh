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
    LS=$(find ${CDW_DIR} -maxdepth 2 -type d -exec ls -d "{}" \;)

    if [ -r /tmp/toaster.old ]; then
        VER="$(cat /tmp/toaster.old)"
    else
        VER="v3"
    fi

    #figlet cdw
    echo "================================================================================"
    echo "          _ "
    echo "   ___ __| |_      __ "
    echo "  / __/ _' \ \ /\ / / "
    echo " | (_| (_| |\ V  V /  "
    echo "  \___\__,_| \_/\_/  by nalbam (${VER}) "
    echo "================================================================================"
    echo " Usage: cdw.sh {NAME}"
    echo "  NAME  : ${LS}"
    echo "================================================================================"

    exit 1
}

################################################################################

SHELL_DIR=$(dirname "$0")

CDW_DIR=

NAME=$1

CONFIG=${SHELL_DIR}/.cdw
if [ -f ${CONFIG} ]; then
    . ${CONFIG}
fi

################################################################################

directory() {
    if [ "${CDW_DIR}" == "" ] || [ ! -d "${CDW_DIR}" ]; then
        echo "Please input credentials directory. (ex: ~/work/src)"
        read CDW_DIR
    fi

    if [ "${CDW_DIR}" == "" ]; then
        error "[${CDW_DIR}] is empty."
    fi
    if [ ! -d "${CDW_DIR}" ]; then
        error "[${CDW_DIR}] is not directory."
    fi

    echo "CDW_DIR=${CDW_DIR}" >> "${CONFIG}"
}

cdw() {

    if [ "${NAME}" == "" ]; then
        usage
    fi
    if [ ! -d "${CDW_DIR}/${NAME}" ]; then
        usage
    fi

    cd ${CDW_DIR}/${NAME}
}

################################################################################

directory

cdw
