#!/bin/bash

OS_TYPE=`uname`
if [ ${OS_TYPE} != 'Linux' ]; then
    echo "Unsupported OS - $OS_TYPE"
#    exit 1
fi

################################################################################

OS_NAME="linux"

EXT="tar.xz"

VERSION="4"

SUDO=""
if [ "${HOME}" != "/root" ]; then
    SUDO="sudo"
fi

MACHINE=`uname -m`
if [ ${MACHINE} == 'x86_64' ]; then
    OS_BIT="x64"
else
    OS_BIT="i586"
fi

################################################################################

URL0="https://nodejs.org/en/download/"
URL4=$(curl -s ${URL0} | egrep -o "https\:\/\/nodejs\.org\/dist\/v${VERSION}.(.*)\/node-v${VERSION}.(.*)-${OS_NAME}-${OS_BIT}.${EXT}")

# https://nodejs.org/dist/v4.4.7/node-v4.4.7-linux-x64.tar.xz

if [[ -z "$URL4" ]]; then
    echo "Could not get node url - $URL4"
    exit 1
fi

URL5=$(echo ${URL4} | cut -d " " -f 1)

NODE=$(echo ${URL5} | cut -d "/" -f 6)

if [[ -z "$NODE" ]]; then
    echo "Could not get NODE - $NODE"
    exit 1
fi

echo ${NODE}

################################################################################

wget ${URL5}

${SUDO} tar xvf ${NODE}

rm -rf ${NODE}

NODE_DIR=$(echo ${NODE} | egrep -o "node-v${VERSION}.(.*)-${OS_NAME}-${OS_BIT}")
NODE_HOME="/usr/local/${NODE_DIR}"

${SUDO} rm -rf "${NODE_HOME}"
${SUDO} mv ${NODE_DIR} /usr/local/

${SUDO} rm -f /usr/bin/NODE
${SUDO} ln -s "${NODE_HOME}/bin/node" /usr/bin/node

${SUDO} rm -f /usr/bin/jar
${SUDO} ln -s "${NODE_HOME}/bin/npm" /usr/bin/npm

echo "NODE_HOME=${NODE_HOME}"
