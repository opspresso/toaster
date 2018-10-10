#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

HOME_DIR=

CONFIG_DIR="${HOME}/.helper/conf"
mkdir -p ${CONFIG_DIR}

CONFIG="${CONFIG_DIR}/$(basename $0)"
touch ${CONFIG} && . ${CONFIG}

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
    echo
    _echo "# $@" 4
}

_command() {
    echo
    _echo "$ $@" 3
}

_success() {
    echo
    _echo "+ $@" 2
    echo
    exit 0
}

_error() {
    echo
    _echo "- $@" 1
    echo
    exit 1
}

usage() {
    #figlet code
    echo "                _ "
    echo "   ___ ___   __| | ___ "
    echo "  / __/ _ \ / _' |/ _ \ "
    echo " | (_| (_) | (_| |  __/ "
    echo "  \___\___/ \__,_|\___| "
    echo
    echo "PATH: ${HOME_DIR}"
    echo

    exit 1
}

_select_one() {
    echo

    IDX=0
    while read VAL; do
        IDX=$(( ${IDX} + 1 ))
        printf "%3s. %s\n" "${IDX}" "${VAL}";
    done < ${LIST}

    CNT=$(cat ${LIST} | wc -l | xargs)

    echo
    _read "Please select one. (1-${CNT}) : "
    echo

    SELECTED=
    if [ -z ${ANSWER} ]; then
        _error
    fi
    TEST='^[0-9]+$'
    if ! [[ ${ANSWER} =~ ${TEST} ]]; then
        _error
    fi
    SELECTED=$(sed -n ${ANSWER}p ${LIST})
    if [ -z ${SELECTED} ]; then
        _error
    fi
}

################################################################################

home_dir() {
    if [ -z ${HOME_DIR} ] || [ ! -d ${HOME_DIR} ]; then
        pushd ~
        DEFAULT="$(pwd)/work/src"
        popd

        _read "Please input base directory. [${DEFAULT}]: "
        HOME_DIR=${ANSWER:-${DEFAULT}}
    fi

    if [ -z ${HOME_DIR} ]; then
        _error "[${HOME_DIR}] is not directory."
    fi

    mkdir -p ${HOME_DIR}

    if [ ! -d ${HOME_DIR} ]; then
        _error "[${HOME_DIR}] is not directory."
    fi

    echo "HOME_DIR=${HOME_DIR}" > ${CONFIG}
}

dir() {
    if [ ! -z ${DIR} ]; then
        return
    fi

    LIST=/tmp/cdw.tmp

    find ${HOME_DIR} -maxdepth 2 -type d -exec ls -d "{}" \; | sort > ${LIST}

    _select_one

    if [ -z ${SELECTED} ] || [ ! -d ${SELECTED} ]; then
        _error
    fi

    DIR="${SELECTED}"

    printf "${DIR}" > /tmp/cdw.result

    _result "${DIR}"
}

code() {
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

home_dir

dir

code
