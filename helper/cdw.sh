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

    #figlet cdw
    echo "================================================================================"
    echo "          _ "
    echo "   ___ __| |_      __ "
    echo "  / __/ _' \ \ /\ / / "
    echo " | (_| (_| |\ V  V /  "
    echo "  \___\__,_| \_/\_/  by nalbam (${VER}) "
    echo "================================================================================"

    exit 1
}

################################################################################

SHELL_DIR=$(dirname "$0")

CDW_DIR=

NUM=$1

CONFIG=${SHELL_DIR}/.cdw
if [ -f ${CONFIG} ]; then
    . ${CONFIG}
fi

################################################################################

directory() {
    if [ "${CDW_DIR}" == "" ] || [ ! -d "${CDW_DIR}" ]; then
        echo "Please input base directory. (ex: ~/work/src)"
        read CDW_DIR
    fi

    if [ "${CDW_DIR}" == "" ]; then
        error "[${CDW_DIR}] is empty."
    fi
    if [ ! -d "${CDW_DIR}" ]; then
        error "[${CDW_DIR}] is not directory."
    fi

    echo "CDW_DIR=${CDW_DIR}" > "${CONFIG}"
}

dir() {
    TEMP=/tmp/cdr.tmp
    find ${CDW_DIR} -maxdepth 2 -type d -exec ls -d "{}" \; > ${TEMP}

    echo "================================================================================"

    i=0
    while read v; do
        i=$(( ${i} + 1 ))
        printf "%3s %s\n" "$i" "$v";
    done < ${TEMP}

    echo "================================================================================"
}

cdw() {
    TEMP=/tmp/cdr.tmp
    find ${CDW_DIR} -maxdepth 2 -type d -exec ls -d "{}" \; > ${TEMP}

    if [ "${NUM}" == "" ]; then
        echo "================================================================================"

        i=0
        while read v; do
            i=$(( ${i} + 1 ))
            printf "%3s %s\n" "$i" "$v";
        done < ${TEMP}

        echo "================================================================================"

        read NUM
    fi

    if [ "${NUM}" == "" ]; then
        usage
    fi

    DIR=

    i=0
    while read v; do
        i=$(( ${i} + 1 ))
        if [ "${i}" == "${NUM}" ]; then
            DIR="${v}"
        fi
    done < ${TEMP}

    if [ "${DIR}" == "" ] || [ ! -d ${DIR} ]; then
        usage
    fi

    success "cd ${DIR}"

    cd ${DIR}
}

################################################################################

directory

dir
