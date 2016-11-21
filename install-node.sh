#!/bin/bash

OS_NAME=`uname`
if [ ${OS_NAME} != "Linux" ]; then
    echo "Not supported OS - $OS_NAME"
    exit 1
fi

################################################################################

OS_NAME="linux"

EXT="tar.xz"

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
URL2=$(curl -s ${URL1} | egrep -o "https\:\/\/nodejs\.org\/dist\/v[0-9]+.[0-9]+.[0-9]+\/node-v[0-9]+.[0-9]+.[0-9]+-${OS_NAME}-${OS_BIT}.${EXT}")

# curl -s https://nodejs.org/en/download/ | egrep -o "https\:\/\/nodejs\.org\/dist\/v[0-9]+.[0-9]+.[0-9]+\/node-v[0-9]+.[0-9]+.[0-9]+-linux-x64.tar.xz"

# https://nodejs.org/dist/v6.9.1/node-v6.9.1-linux-x64.tar.xz
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

NODE_DIR=$(echo ${NODE} | egrep -o "node-v[0-9]+.[0-9]+.[0-9]+-${OS_NAME}-${OS_BIT}")
NODE_HOME="/usr/local/${NODE_DIR}"

${SUDO} rm -rf ${NODE_HOME}
${SUDO} mv ${NODE_DIR} /usr/local/

${SUDO} rm -rf /usr/local/node
${SUDO} ln -s ${NODE_HOME} /usr/local/node

echo "NODE_HOME=${NODE_HOME}"
