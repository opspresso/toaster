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

# https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.0.0.rpm

NAME="elasticsearch"

VERSION="6.0.0"

FILE="${NAME}-${VERSION}"

EXT="rpm"

################################################################################

if [ -f ${FILE}.${EXT} ]; then
    exit 0
fi

wget -N https://artifacts.elastic.co/downloads/${NAME}/${FILE}.${EXT}

if [ ! -f ${FILE}.${EXT} ]; then
    error "Can not download : ${FILE}.${EXT}"
fi

################################################################################

${SUDO} rpm -Uvh ${FILE}.${EXT}

################################################################################
