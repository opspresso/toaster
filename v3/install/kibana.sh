#!/bin/bash

echo_() {
    echo -e "$1"
    echo "$1" >> /tmp/toast.log
}

success() {
    echo -e "$(tput setaf 2)$1$(tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

error() {
    echo -e "$(tput setaf 1)$1$(tput sgr0)"
    echo "$1" >> /tmp/toast.log
    exit 1
}

################################################################################

OS_NAME="$(uname)"
OS_FULL="$(uname -a)"
if [ "${OS_NAME}" == "Linux" ]; then
    if [ $(echo "${OS_FULL}" | grep -c "Ubuntu") -gt 0 ]; then
        OS_TYPE="Ubuntu"
    else
        OS_TYPE="generic"
    fi
elif [ "${OS_NAME}" == "Darwin" ]; then
    OS_TYPE="${OS_NAME}"
fi

SUDO=""
if [ "${HOME}" != "/root" ]; then
    SUDO="sudo"
fi

################################################################################

download() {
    _FILE="$1"
    _PATH="$2"

    if [ "${REPO}" != "" ]; then
        URL="s3://${REPO}/${_PATH}/${_FILE}"

        echo_ "download... [${URL}]"

        aws s3 cp ${URL} ./
    fi

    if [ ! -f ${_FILE} ]; then
        URL="http://repo.toast.sh/${_PATH}/${_FILE}"

        echo_ "download... [${URL}]"

        curl -O ${URL}
    fi
}

################################################################################

# s3://repo.toast.sh/elastic/kibana-6.0.0-x86_64.rpm

REPO="$1"

NAME="elastic"

FILE="kibana-6.0.0-x86_64.rpm"

################################################################################

if [ -f ${FILE} ]; then
    exit 0
fi

download "${FILE}" "${NAME}"

if [ ! -f ${FILE} ]; then
    error "Can not download : ${FILE}"
fi

################################################################################

${SUDO} rpm -Uvh ${FILE}

################################################################################
