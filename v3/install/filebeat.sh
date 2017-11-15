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

NAME="filebeat"

VERSION="5.6.4"

FILE="${NAME}-${VERSION}-x86_64"

EXT="rpm"

################################################################################

wget -N https://artifacts.elastic.co/downloads/beats/filebeat/${FILE}.${EXT}

if [ ! -f ${FILE}.${EXT} ]; then
    error "Can not download : ${FILE}.${EXT}"
fi

################################################################################

${SUDO} rpm -Uvh filebeat-5.6.4-x86_64.rpm

rm -rf ${FILE}.${EXT}

################################################################################
