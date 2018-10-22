#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

HOME_DIR=

CONFIG_DIR="${HOME}/.helper/conf"

CONFIG="${CONFIG_DIR}/$(basename $0)"

_PEM=${1}
_HOST=${2}
_USER=${3}

HISTORY="${CONFIG_DIR}/ssh-history"

LIST=/tmp/toaster-helper-ssh-list

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
    LS=$(ls -m ${HOME_DIR})

    #figlet ssh
    echo "          _ "
    echo "  ___ ___| |__ "
    echo " / __/ __| '_ \ "
    echo " \__ \__ \ | | | "
    echo " |___/___/_| |_| "
    echo
    echo "Usage: `basename $0` {PEM} {HOST} {USER}"
    echo " NAME: ${LS}"
    echo " HOST: hostname"
    echo " USER: ec2-user"
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

    SELECTED=
    if [ -z ${ANSWER} ]; then
        return
    fi
    TEST='^[0-9]+$'
    if ! [[ ${ANSWER} =~ ${TEST} ]]; then
        return
    fi
    SELECTED=$(sed -n ${ANSWER}p ${LIST})
}

################################################################################

prepare() {
    mkdir -p ${CONFIG_DIR}

    touch ${CONFIG} && . ${CONFIG}
}

home_dir() {
    if [ -z ${HOME_DIR} ] || [ ! -d ${HOME_DIR} ]; then
        pushd ~
        DEFAULT="$(pwd)/work/src/github.com/${USER:-nalbam}/keys/pem"
        popd

        echo
        _read "Please input pem directory. [${DEFAULT}]: "
        HOME_DIR=${ANSWER:-${DEFAULT}}
    fi

    if [ -z ${HOME_DIR} ] || [ ! -d ${HOME_DIR} ]; then
        _error "[${HOME_DIR}] is not directory."
    fi

    echo "HOME_DIR=${HOME_DIR}" > ${CONFIG}

    chmod 600 ${HOME_DIR}/*.pem

    echo "Host * " > ~/.ssh/config
    echo "    StrictHostKeyChecking no " >> ~/.ssh/config

    echo "" > ~/.ssh/known_hosts
}

connect() {
    FROM_HISTORY=

    # history
    if [ -z ${_PEM} ] && [ -z ${_HOST} ] && [ -z ${_USER} ]; then
        if [ -f ${HISTORY} ]; then
            cat ${HISTORY} | sort > ${LIST}

            _select_one

            if [ "${SELECTED}" != "" ]; then
                ARR=(${SELECTED})

                _PEM=${ARR[0]}
                _HOST=${ARR[1]}
                _USER=${ARR[2]}

                FROM_HISTORY=true
            fi
        fi
    fi

    # pem
    if [ -z ${_PEM} ]; then
        ls ${HOME_DIR} | sort > ${LIST}

        _select_one

        if [ -z ${SELECTED} ] || [ ! -f ${HOME_DIR}/${SELECTED} ]; then
            _error
        fi

        _PEM="${SELECTED}"
    fi
    if [ -z ${_PEM} ]; then
        usage
    fi

    # host
    if [ -z ${_HOST} ]; then
        echo
        _read "Please input ssh host. []: "

        _HOST="${ANSWER}"
    fi
    if [ -z ${_HOST} ]; then
        usage
    fi

    # user
    if [ -z ${_USER} ]; then
        echo
        _read "Please input ssh user. [ec2-user]: "

        _USER="${ANSWER:-ec2-user}"
    fi
    if [ -z ${_USER} ]; then
        usage
    fi

    if [ ! -f ${HOME_DIR}/${_PEM} ]; then
        if [ -f ${HOME_DIR}/${_PEM}.pem ]; then
            _PEM="${_PEM}.pem"
        else
            usage
        fi
    fi

    if [ -z ${FROM_HISTORY} ]; then
        COUNT=$(cat ${HISTORY} | grep "${_PEM} ${_HOST} ${_USER}" | wc -l | xargs)

        if [ "x${COUNT}" == "x0" ]; then
            echo "${_PEM} ${_HOST} ${_USER}" >> ${HISTORY}
        fi
    fi

    _command "ssh -i ${HOME_DIR}/${_PEM} ${_USER}@${_HOST}"
    ssh -i ${HOME_DIR}/${_PEM} ${_USER}@${_HOST}
}

################################################################################

prepare

home_dir

connect
