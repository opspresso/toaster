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

SHELL_DIR=$(dirname $0)

################################################################################

NAME="java"

FILE="server-jre-8u121-linux-x64"

EXT="tar.gz"

# aws s3 cp server-jre-8u121-linux-x64.tar.gz s3://repo.yanolja.com/java/server-jre-8u121-linux-x64.tar.gz

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

tar xzf ${FILE}.${EXT}

VS1=$(echo ${FILE} | cut -d "-" -f 3)
VS2="${VS1/u/.0_}"

JAVA_DIR="jdk1.${VS2}"
JAVA_HOME="/usr/local/${JAVA_DIR}"

${SUDO} rm -rf ${JAVA_HOME}
${SUDO} mv ${JAVA_DIR} /usr/local/

${SUDO} rm -rf /usr/local/java
${SUDO} ln -s ${JAVA_HOME} /usr/local/java

${SUDO} cp -rf ${SHELL_DIR}/jce8/* ${JAVA_HOME}/jre/lib/security/

echo_ "JAVA_HOME=${JAVA_HOME}"
