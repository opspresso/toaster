#!/bin/bash

OS_NAME=`uname`
if [ ${OS_NAME} != "Linux" ]; then
    warning "Not supported OS - $OS_NAME"
    exit 1
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

URL1="https://nodejs.org/en/download/"
URL2=$(curl -s ${URL1} | egrep -o "https\:\/\/nodejs\.org\/dist\/v${VERSION}.(.*)\/node-v${VERSION}.(.*)-${OS_NAME}-${OS_BIT}.${EXT}")

# https://nodejs.org/dist/v4.4.7/node-v4.4.7-linux-x64.tar.xz

if [[ -z "$URL2" ]]; then
    echo "Could not get node url - $URL2"
    exit 1
fi

URL3=$(echo ${URL2} | cut -d " " -f 1)

NODE=$(echo ${URL3} | cut -d "/" -f 6)

if [[ -z "$NODE" ]]; then
    echo "Could not get node - $NODE"
    exit 1
fi

echo ${URL3}
echo ${NODE}

################################################################################

wget -q -N ${URL3}

tar xf ${NODE}

rm -rf ${NODE}

NODE_DIR=$(echo ${NODE} | egrep -o "node-v${VERSION}.(.*)-${OS_NAME}-${OS_BIT}")
NODE_HOME="/usr/local/${NODE_DIR}"

${SUDO} rm -rf "${NODE_HOME}"
${SUDO} mv ${NODE_DIR} /usr/local/

${SUDO} rm -f /usr/bin/node
${SUDO} ln -s "${NODE_HOME}/bin/node" /usr/bin/node

${SUDO} rm -f /usr/bin/npm
${SUDO} ln -s "${NODE_HOME}/bin/npm" /usr/bin/npm

${SUDO} npm install -g pm2

${SUDO} rm -f /usr/bin/pm2
${SUDO} ln -s "${NODE_HOME}/lib/node_modules/pm2/bin/pm2" /usr/bin/pm2

echo "NODE_HOME=${NODE_HOME}"
