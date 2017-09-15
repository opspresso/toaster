#!/bin/bash

echo_() {
    echo "$1"
    echo "$1" >> /tmp/toast.log
}

success() {
    echo -e "$(/usr/bin/tput setaf 2)$1$(/usr/bin/tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

inform() {
    echo -e "$(/usr/bin/tput setaf 6)$1$(/usr/bin/tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

warning() {
    echo -e "$(/usr/bin/tput setaf 1)$1$(/usr/bin/tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

download() {
    _FILE="$1"
    _PATH="$2"

    if [ "${REPO}" != "" ]; then
        URL="${REPO}/${_PATH}/${_FILE}"

        echo_ "download... [${URL}]"

        /usr/bin/aws s3 cp ${URL} ./
    fi

    if [ ! -f ${_FILE} ]; then
        URL="http://repo.toast.sh/${_PATH}/${_FILE}"

        echo_ "download... [${URL}]"

        /usr/bin/curl -O ${URL}
    fi
}

################################################################################

OS_NAME=$(uname)
if [ ${OS_NAME} != "Linux" ]; then
    warning "Not supported OS : ${OS_NAME}"
    exit 1
fi

SUDO=""
if [ "${HOME}" != "/root" ]; then
    SUDO="sudo"
fi

################################################################################

# s3://repo.toast.sh/node/node-v6.11.3-linux-x64.tar.xz

NAME="node"

VERSION="6.11.3"

FILE="${NAME}-v${VERSION}-linux-x64"

EXT="tar.xz"

################################################################################

REPO="$1"

download "${FILE}.${EXT}" "${NAME}"

if [ ! -f ${FILE}.${EXT} ]; then
    warning "Can not download : ${FILE}.${EXT}"
    exit 1
fi

################################################################################

tar xf ${FILE}.${EXT}

NODE_HOME="/usr/local/${FILE}"

${SUDO} rm -rf ${NODE_HOME}
${SUDO} rm -rf /usr/local/node

if [ ! -d ${FILE} ]; then
    warning "Can not found : ${FILE}"
    exit 1
fi

${SUDO} mv ${FILE} /usr/local/

${SUDO} ln -s ${NODE_HOME} /usr/local/node

rm -rf ${FILE}.${EXT}

echo_ "NODE_HOME=${NODE_HOME}"
