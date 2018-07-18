#!/bin/bash

DIR=

ANSWER=$1

HOME_DIR=

SHELL_DIR=$(dirname $(dirname "$0"))

OS_NAME="$(uname | awk '{print tolower($0)}')"

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

    #figlet code
    echo "================================================================================"
    echo "                _ "
    echo "   ___ ___   __| | ___ "
    echo "  / __/ _ \ / _' |/ _ \ "
    echo " | (_| (_) | (_| |  __/ "
    echo "  \___\___/ \__,_|\___|  by nalbam (${VER}) "
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
    TEMP=/tmp/cdr.tmp

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

vscode() {
    if [ -z "${ANSWER}" ]; then
        question
    fi

    if [ -z "${ANSWER}" ]; then
        error
    fi

    DIR=$(sed -n ${ANSWER}p ${TEMP})

    if [ -z "${DIR}" ] || [ ! -d ${DIR} ]; then
        error
    fi

    if [ "${OS_NAME}" == "linux" ]; then
        bash /usr/local/bin/code ${DIR}
    elif [ "${OS_NAME}" == "darwin" ]; then
        bash /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code ${DIR}
    fi
}

################################################################################

prepare

directory

dir

vscode
