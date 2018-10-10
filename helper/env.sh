#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

HOME_DIR=

CONFIG_DIR="${HOME}/.helper/conf"
mkdir -p ${CONFIG_DIR}

CONFIG="${CONFIG_DIR}/$(basename $0)"
touch ${CONFIG} && . ${CONFIG}

_NAME=$1
_REGION=${2:-ap-northeast-2}
_OUTPUT=${3:-json}

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
    LS=$(ls -m ${HOME_DIR})

    #figlet env
    echo "   ___ _ ____   __ "
    echo "  / _ \ '_ \ \ / / "
    echo " |  __/ | | \ V / "
    echo "  \___|_| |_|\_/ "
    echo
    echo "Usage: env.sh {NAME} {REGION} {OUTPUT}"
    echo " NAME  : ${LS}"
    echo " REGION: ap-northeast-2"
    echo " OUTPUT: json"
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
        DEFAULT="$(pwd)/work/src/github.com/${USER:-nalbam}/keys/credentials"
        popd

        _read "Please input credentials directory. [${DEFAULT}]: "
        HOME_DIR=${ANSWER:-${DEFAULT}}
    fi

    if [ -z ${HOME_DIR} ] || [ ! -d ${HOME_DIR} ]; then
        _error "[${HOME_DIR}] is not directory."
    fi

    echo "HOME_DIR=${HOME_DIR}" > ${CONFIG}
}

deploy() {
    LIST=/tmp/toaster-helper-env-ls

    if [ -z ${_NAME} ]; then
        ls ${HOME_DIR} > ${LIST}

        _select_one

        _result "${SELECTED}"

        _NAME="${SELECTED}"
    fi

    if [ -z "${_NAME}" ]; then
        usage
    fi
    if [ ! -f "${HOME_DIR}/${_NAME}" ]; then
        usage
    fi

    command -v aws > /dev/null || AWSCLI=false

    if [ ! -z ${AWSCLI} ]; then
        _error "Please install awscli."
    fi

    mkdir -p ~/.aws

    aws configure set default.region ${_REGION}
    aws configure set default.output ${_OUTPUT}

    cp -f ${HOME_DIR}/${_NAME} ~/.aws/credentials

    _success "${_NAME} ${_REGION} ${_OUTPUT}"
}

################################################################################

home_dir

deploy
