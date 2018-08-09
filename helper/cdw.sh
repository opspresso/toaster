#!/bin/bash

DIR=

ANSWER=$1

HOME_DIR=

SHELL_DIR=${HOME}/toaster

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
    if [ -r ${SHELL_DIR}/conf/ver.now ]; then
        VER="$(cat ${SHELL_DIR}/conf/ver.now)"
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

    rm -rf /tmp/cdw.*
}

directory() {
    if [ -z "${HOME_DIR}" ] || [ ! -d "${HOME_DIR}" ]; then
        pushd ~
        DEFAULT="$(pwd)/work/src"
        popd

        question "Please input base directory. [${DEFAULT}]: "
        HOME_DIR=${ANSWER:-${DEFAULT}}
    fi

    mkdir -p ${HOME_DIR}

    if [ ! -d "${HOME_DIR}" ]; then
        error "[${HOME_DIR}] is not directory."
    fi

    echo "HOME_DIR=${HOME_DIR}" > "${CONFIG}"
}

dir() {
    TEMP=/tmp/cdw.tmp

    find ${HOME_DIR} -maxdepth 2 -type d -exec ls -d "{}" \; > ${TEMP}

    if [ -z "${ANSWER}" ]; then
        echo "================================================================================"

        IDX=0
        while read VAL; do
            IDX=$(( ${IDX} + 1 ))
            printf "%3s %s\n" "$IDX" "$VAL";
        done < ${TEMP}

        echo "================================================================================"
    fi
}

cdw() {
    if [ -z "${ANSWER}" ]; then
        question
    fi

    if [ -z "${ANSWER}" ]; then
        error
    fi

    export DIR=$(sed -n ${ANSWER}p ${TEMP})

    if [ -z "${DIR}" ] || [ ! -d ${DIR} ]; then
        error
    fi

    success "${DIR}"

    echo "${DIR}" > /tmp/cdw.result
}

################################################################################

prepare

directory

dir

cdw
