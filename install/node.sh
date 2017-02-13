#!/bin/bash

echo_() {
    echo "$1"
    echo "$1" >> /tmp/toast.log
}

success() {
    echo "$(tput setaf 2)$1$(tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

warning() {
    echo "$(tput setaf 1)$1$(tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

################################################################################

#OS_NAME=`uname`
#if [ ${OS_NAME} != "Linux" ]; then
#    warning "Not supported OS : ${OS_NAME}"
#    exit 1
#fi

SUDO=""
if [ "${HOME}" != "/root" ]; then
    SUDO="sudo"
fi

################################################################################

NAME="node"

VERSION="6.9.5"

FILE="node-v${VERSION}-linux-x64"

EXT="tar.xz"

# s3://repo.toast.sh/node/node-v6.9.5-linux-x64.tar.xz

################################################################################

REPO="$1"

if [ "${REPO}" == "" ]; then
    URL="http://repo.toast.sh/${NAME}/${FILE}.${EXT}"

    echo_ "download... [${URL}]"

    wget -q -N ${URL}
else
    URL="${REPO}/${NAME}/${FILE}.${EXT}"

    echo_ "download... [${URL}]"

    aws s3 cp ${URL} ./
fi

if [ ! -f ${FILE}.${EXT} ]; then
    warning "Can not download : ${URL}"
    exit 1
fi

exit 0

################################################################################

tar xf ${FILE}.${EXT}

NODE_HOME="/usr/local/${FILE}"

${SUDO} rm -rf ${NODE_HOME}
${SUDO} rm -rf /usr/local/node

${SUDO} mv ${FILE} /usr/local/

${SUDO} ln -s ${NODE_HOME} /usr/local/node

echo_ "NODE_HOME=${NODE_HOME}"
