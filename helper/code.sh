#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

HOME_DIR=

CONFIG_DIR="${HOME}/.helper/conf"

CONFIG="${CONFIG_DIR}/$(basename $0)"

DIR=$1

LIST=/tmp/toaster-helper-code-list
TEMP=/tmp/toaster-helper-code-result

################################################################################

command -v fzf > /dev/null && FZF=true
command -v tput > /dev/null && TPUT=true

_echo() {
    if [ -n ${TPUT} ] && [ -n $2 ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
    fi
}

_read() {
    if [ -n ${TPUT} ]; then
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

_select_one() {
    OPT=$1

    SELECTED=

    CNT=$(cat ${LIST} | wc -l | xargs)
    if [ "x${CNT}" == "x0" ]; then
        return
    fi

    if [ "${OPT}" != "" ] && [ "x${CNT}" == "x1" ]; then
        SELECTED="$(cat ${LIST} | xargs)"
    else
        if [ -n ${FZF} ]; then
            SELECTED=$(cat ${LIST} | fzf --reverse --no-mouse --height=10 --bind=left:page-up,right:page-down)
        else
            echo

            IDX=0
            while read VAL; do
                IDX=$(( ${IDX} + 1 ))
                printf "%3s. %s\n" "${IDX}" "${VAL}"
            done < ${LIST}

            if [ "${CNT}" != "1" ]; then
                CNT="1-${CNT}"
            fi

            echo
            _read "Please select one. (1-${CNT}) : "

            if [ -z ${ANSWER} ]; then
                return
            fi
            TEST='^[0-9]+$'
            if ! [[ ${ANSWER} =~ ${TEST} ]]; then
                return
            fi
            SELECTED=$(sed -n ${ANSWER}p ${LIST})
        fi
    fi
}

################################################################################

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

prepare() {
    mkdir -p ${CONFIG_DIR}

    touch ${CONFIG} && . ${CONFIG}

    rm -rf ${LIST}
    rm -rf ${TEMP}
}

home_dir() {
    if [ -z ${HOME_DIR} ] || [ ! -d ${HOME_DIR} ]; then
        DEFAULT="${HOME}/work/src"

        echo
        _read "Please input base directory. [${DEFAULT}]: "
        HOME_DIR=${ANSWER:-${DEFAULT}}
    fi

    if [ -z ${HOME_DIR} ]; then
        _error "[${HOME_DIR}] is not directory."
    fi

    mkdir -p ${HOME_DIR}/github.com

    if [ ! -d ${HOME_DIR} ]; then
        _error "[${HOME_DIR}] is not directory."
    fi

    echo "HOME_DIR=${HOME_DIR}" > ${CONFIG}
}

dir() {
    if [ ! -z ${DIR} ]; then
        return
    fi

    find ${HOME_DIR} -maxdepth 2 -type d -exec ls -d "{}" \; | sort > ${LIST}

    _select_one

    if [ -z ${SELECTED} ] || [ ! -d ${SELECTED} ]; then
        _error
    fi

    DIR="${SELECTED}"

    printf "${DIR}" > ${TEMP}

    _success "${DIR}"
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

prepare

home_dir

dir

code
