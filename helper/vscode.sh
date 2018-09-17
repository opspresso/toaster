#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

SHELL_DIR=${HOME}/helper

HOME_DIR=

DIR=$1

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
    #figlet code
    echo "================================================================================"
    echo "                _ "
    echo "   ___ ___   __| | ___ "
    echo "  / __/ _ \ / _' |/ _ \ "
    echo " | (_| (_) | (_| |  __/ "
    echo "  \___\___/ \__,_|\___| "
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

        _read "Please input base directory. [${DEFAULT}]: "
        HOME_DIR=${ANSWER:-${DEFAULT}}
    fi

    mkdir -p ${HOME_DIR}

    if [ ! -d "${HOME_DIR}" ]; then
        _error "[${HOME_DIR}] is not directory."
    fi

    echo "HOME_DIR=${HOME_DIR}" > "${CONFIG}"
}

dir() {
    if [ ! -z ${DIR} ]; then
        return
    fi

    TEMP=/tmp/cdw.tmp

    find ${HOME_DIR} -maxdepth 2 -type d -exec ls -d "{}" \; | sort > ${TEMP}

    COUNT=$(wc -l ${TEMP} | xargs)

    if [ "x${COUNT}" == "x0" ]; then
        _error "[${HOME_DIR}] is empty."
    fi

    echo "================================================================================"

    IDX=0
    while read VAL; do
        IDX=$(( ${IDX} + 1 ))
        printf "%3s %s\n" "$IDX" "$VAL";
    done < ${TEMP}

    echo "================================================================================"
}

vscode() {
    if [ -z ${DIR} ]; then
        _read "Choose directory [1-${IDX}]: "

        if [ -z ${ANSWER} ]; then
            _error
        fi
        TEST='^[0-9]+$'
        if ! [[ ${ANSWER} =~ ${TEST} ]]; then
            _error "[${ANSWER}] is not a number."
        fi

        DIR=$(sed -n ${ANSWER}p ${TEMP})
    fi

    if [ -z ${DIR} ] || [ ! -d ${DIR} ]; then
        _error
    fi

    if [ "${OS_NAME}" == "linux" ]; then
        /usr/bin/code ${DIR}
    elif [ "${OS_NAME}" == "darwin" ]; then
        /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code ${DIR}
    elif [ "${OS_NAME}" == "mingw64_nt-10.0" ]; then
        /c/Users/${USER:-$(whoami)}/AppData/Local/Programs/Microsoft\ VS\ Code/Code.exe ${DIR}
    else
        _error
    fi
}

################################################################################

prepare

directory

dir

vscode
